import Foundation
import Combine
import UserNotifications

// MARK: - Deep Link

/// Actions delivered via notification tap (§11.8).
enum DeepLinkAction: Equatable {
    /// Navigate to the main screen.
    /// `forceRefresh == true` when no active cache exists → trigger immediate recalculation.
    /// `forceRefresh == false` when active cache exists → display cached result as-is.
    case openMain(forceRefresh: Bool)
}

// MARK: - NotificationService

/// §11.1–11.9: Manages local push notifications, UNUserNotificationCenterDelegate routing,
/// and the trust-first delivery policy.
///
/// Trust-first policy (§11.5):
///   Case A — fresh same-day cache exists when background task completes:
///     → one-shot notification: "Leave home at 8:24 AM. Northern line service is good."
///   Case B — no fresh cache (background task missed or API failed):
///     → placeholder fires: "Open TimeToGo to calculate your commute."
///
///   The system NEVER sends a stale leave time as authoritative (§11.5, §11.6).
///
/// Notification tap handling (§11.8):
///   All notifications carry { "action": "openMain" } in userInfo.
///   Tap → `UNUserNotificationCenterDelegate` → `pendingDeepLink` published →
///   ContentView reacts and routes to MainView, triggering recalculation if needed.
@MainActor
final class NotificationService: NSObject, ObservableObject {

    static let shared = NotificationService()

    // MARK: - Published state

    /// §11.1: Permission state for UI warning display.
    @Published private(set) var permissionGranted: Bool = false
    @Published private(set) var permissionDenied:  Bool = false

    /// §11.8: Set when a notification is tapped. ContentView observes this to route.
    /// Consumed immediately after routing so it doesn't retrigger.
    @Published var pendingDeepLink: DeepLinkAction? = nil

    // MARK: - Dependencies

    private let center:        UNUserNotificationCenter
    private let cacheManager:  CommuteCacheManager
    private let calcService:   CommuteCalculationService
    private let timeFormatter: DateFormatter

    // MARK: - Constants

    /// §11.8: Payload key present in every notification.
    private static let actionKey   = "action"
    private static let actionValue = "openMain"

    // MARK: - Init

    override init() {
        self.center       = UNUserNotificationCenter.current()
        self.cacheManager = CommuteCacheManager()
        self.calcService  = CommuteCalculationService()

        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.locale     = Locale(identifier: "en_US_POSIX")
        f.timeZone   = TimeZone(identifier: "Europe/London")
        self.timeFormatter = f

        super.init()

        // Register as the delegate so taps are handled here, not ignored.
        // Must happen before any notifications are scheduled.
        center.delegate = self
    }

    // MARK: - §11.2 Permission

    /// Request notification authorisation. Non-throwing; updates published state.
    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            permissionGranted = granted
            permissionDenied  = !granted
        } catch {
            permissionDenied = true
        }
    }

    /// Check current authorisation without prompting. Call on every app launch.
    func refreshPermissionStatus() async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            permissionGranted = true
            permissionDenied  = false
        case .denied:
            permissionGranted = false
            permissionDenied  = true
        default:
            permissionGranted = false
            permissionDenied  = false
        }
    }

    // MARK: - §11.3 Scheduling (repeating placeholder per office day)

    /// Schedule one repeating weekly placeholder per office day.
    /// Placeholder content = Case B ("Open TimeToGo…") so it is always safe to deliver.
    /// The background task will replace it with Case A content before it fires.
    func scheduleNotifications(for settings: UserSettings) async {
        cancelAllPendingNotifications()
        guard permissionGranted else { return }
        guard !settings.officeDays.isEmpty else { return }

        let cal            = Calendar.current
        let timeComponents = cal.dateComponents([.hour, .minute], from: settings.notificationTime)

        for day in settings.officeDays {
            var trigger        = DateComponents()
            trigger.weekday    = day.rawValue   // 1=Sunday … 7=Saturday
            trigger.hour       = timeComponents.hour
            trigger.minute     = timeComponents.minute
            trigger.second     = 0

            let content = makeCaseBContent()    // §11.5 Case B — safe default
            let request = UNNotificationRequest(
                identifier: identifier(for: day),
                content:    content,
                trigger:    UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
            )

            do    { try await center.add(request) }
            catch { /* Non-fatal. */ }
        }
    }

    /// §11.9: Cancel everything and reschedule after settings change.
    func reschedule(for settings: UserSettings) async {
        cancelAllPendingNotifications()
        await scheduleNotifications(for: settings)
    }

    func cancelAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - §11.4 / §11.5 Trust-first one-shot update

    /// Replace today's repeating placeholder with a one-shot Case A notification.
    ///
    /// Trust-first enforcement:
    ///   - Verifies the cache entry for `today` is still fresh (same-day + <24 h).
    ///   - If not fresh → does nothing; the Case B placeholder fires as designed.
    ///   - If fresh → schedules Case A notification and marks cache as active (§11.7).
    ///
    /// Called by:
    ///   - `BackgroundTaskManager.performRefresh(task:)` (background path)
    ///   - `refreshTodayNotification(settings:)` (foreground app-open path)
    func updateTodayNotification(
        result:   CommuteResult,
        settings: UserSettings,
        today:    Date
    ) async {
        // §11.5 / §11.6: Only proceed if the result we received maps to a fresh cache.
        guard cacheManager.isValid(for: today) else {
            // Cache is not fresh — trust-first demands we do NOT send a real leave time.
            // The Case B placeholder stays in place.
            return
        }

        let cal          = Calendar.current
        let todayWeekday = cal.component(.weekday, from: today)
        guard let day    = Weekday(rawValue: todayWeekday) else { return }

        // Remove the repeating Case B placeholder for this weekday.
        center.removePendingNotificationRequests(withIdentifiers: [identifier(for: day)])

        // Build the one-shot trigger at today's notification time.
        var triggerComponents      = cal.dateComponents([.year, .month, .day], from: today)
        let timeComponents         = cal.dateComponents([.hour, .minute], from: settings.notificationTime)
        triggerComponents.hour     = timeComponents.hour
        triggerComponents.minute   = timeComponents.minute
        triggerComponents.second   = 0

        guard
            let fireDate = cal.date(from: triggerComponents),
            fireDate > today
        else {
            // Notification time already passed; restore the Case B placeholder.
            await scheduleOneDayPlaceholder(for: day, settings: settings)
            return
        }

        // §11.7: Mark the cache as the active commute result before committing the notification.
        // From this point, opening the app during the same commute day shows this exact value.
        cacheManager.markAsActive()

        let content = makeCaseAContent(result: result, settings: settings)
        let request = UNNotificationRequest(
            identifier: "\(identifier(for: day)).oneshot",
            content:    content,
            trigger:    UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        )

        do    { try await center.add(request) }
        catch { /* Non-fatal; the Case B placeholder no longer exists — reschedule it. */
            await scheduleOneDayPlaceholder(for: day, settings: settings)
        }
    }

    // MARK: - Foreground app-open refresh

    /// Attempt a fresh calculation and update today's notification if not yet active.
    /// If the API fails, no notification change occurs; the placeholder stays.
    func refreshTodayNotification(settings: UserSettings) async {
        let today        = Date()
        let cal          = Calendar.current
        let todayWeekday = cal.component(.weekday, from: today)

        guard settings.officeDays.map(\.rawValue).contains(todayWeekday) else { return }
        guard !cacheManager.hasActiveResult(for: today) else { return }   // §11.7

        do {
            let result = try await calcService.calculate(for: settings)
            cacheManager.save(result, for: today)
            await updateTodayNotification(result: result, settings: settings, today: today)
        } catch {
            // API failed; Case B placeholder already in place. Nothing to do.
        }
    }

    // MARK: - §11.5 Content builders

    /// Case B content (§11.5): no leave time, no stale data. Always safe.
    func makeCaseBContent() -> UNMutableNotificationContent {
        let content    = UNMutableNotificationContent()
        content.title  = "Time to Go"
        content.body   = "Open TimeToGo to calculate your commute."
        content.sound  = .default
        content.userInfo = [Self.actionKey: Self.actionValue]   // §11.8
        return content
    }

    /// Case A content (§11.5): real leave time from a validated fresh result.
    func makeCaseAContent(
        result:   CommuteResult,
        settings: UserSettings
    ) -> UNMutableNotificationContent {
        let content   = UNMutableNotificationContent()
        content.title = "Time to Go"
        content.sound = .default
        content.userInfo = [Self.actionKey: Self.actionValue]   // §11.8

        let leaveTime = timeFormatter.string(from: result.leaveHomeTime)
        let lineName  = settings.homeLineId.capitalized

        switch result.serviceStatus {
        case .goodService:
            content.body = "Leave home at \(leaveTime). \(lineName) line service is good."
        case .minorDelays:
            content.body = "Leave home at \(leaveTime). Minor delays on the \(lineName) line."
        case .severeDelays:
            content.body = "Leave home at \(leaveTime). Major delays on the \(lineName) line."
        case .unknown:
            content.body = "Leave home at \(leaveTime)."
        }

        return content
    }

    // MARK: - Private helpers

    private func identifier(for day: Weekday) -> String {
        "com.timetogo.notification.\(day.rawValue)"
    }

    /// Restores a single-day repeating placeholder when a one-shot update fails or is too late.
    private func scheduleOneDayPlaceholder(for day: Weekday, settings: UserSettings) async {
        let cal            = Calendar.current
        let timeComponents = cal.dateComponents([.hour, .minute], from: settings.notificationTime)

        var trigger        = DateComponents()
        trigger.weekday    = day.rawValue
        trigger.hour       = timeComponents.hour
        trigger.minute     = timeComponents.minute
        trigger.second     = 0

        let content = makeCaseBContent()
        let request = UNNotificationRequest(
            identifier: identifier(for: day),
            content:    content,
            trigger:    UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
        )

        do    { try await center.add(request) }
        catch { /* Non-fatal. */ }
    }
}

// MARK: - UNUserNotificationCenterDelegate (§11.8)

extension NotificationService: UNUserNotificationCenterDelegate {

    /// Called when a notification is tapped while the app is in background or terminated.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let action   = userInfo[NotificationService.actionKey] as? String

        Task { @MainActor in
            if action == NotificationService.actionValue {
                self.handleOpenMainAction()
            }
        }

        completionHandler()
    }

    /// Called when a notification arrives while the app is in the foreground.
    /// Presenting it ensures the user sees it even if they have the app open.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Deep link routing (§11.8)

    @MainActor
    private func handleOpenMainAction() {
        let today             = Date()
        let hasActive         = cacheManager.hasActiveResult(for: today)
        // Case A tap: active cache → display as-is (no recalculation).
        // Case B tap: no active cache → force immediate recalculation.
        pendingDeepLink = .openMain(forceRefresh: !hasActive)
    }
}
