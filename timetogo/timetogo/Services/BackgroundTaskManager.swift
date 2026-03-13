import Foundation
import BackgroundTasks

// MARK: - BackgroundTaskManager

/// Autonomous background execution layer.
///
/// Architecture overview
/// ─────────────────────
/// The system delivers a daily BGAppRefreshTask ~2 hours before the user's notification time.
/// This task:
///   1. Calls CommuteCalculationService with forceRefresh:true.
///   2. Persists the result via CommuteCacheManager.
///   3. Verifies the saved cache is fresh (trust-first guard) before touching notifications.
///   4. Replaces today's Case B placeholder with a one-shot Case A notification.
///   5. Self-reschedules for the next office day.
///
/// Trust-first guarantee:
///   `NotificationService.updateTodayNotification` re-validates the cache before
///   scheduling real content. If the cache is not fresh, the Case B placeholder stays.
///   Stale leave times can NEVER reach the user via this path.
///
/// Fail-safe chain (if iOS skips the background task):
///   • The Case B repeating placeholder fires: "Open TimeToGo to calculate your commute."
///   • The user taps → app runs a forced recalculation immediately (§11.8 Case B tap).
///
/// iOS scheduling limitations & mitigations
/// ─────────────────────────────────────────
/// • BGAppRefreshTask is NOT guaranteed to run at an exact time.
///   `earliestBeginDate` set 2 h early gives the OS a comfortable window.
/// • Low Power Mode suppresses background tasks.
///   Mitigation: Case B placeholder + foreground recalculation on notification tap.
/// • Background budget ≈ 30 s per invocation (single TFL REST call is well within budget).
/// • Force-quit cancels pending submissions.
///   Mitigation: `scheduleNextRefresh` called on every app-open and onboarding completion.
final class BackgroundTaskManager {

    // MARK: - Identifiers

    /// Must match the value in BGTaskSchedulerPermittedIdentifiers (Info.plist).
    static let refreshTaskIdentifier = "com.timetogo.commuteRefresh"

    // MARK: - Singleton

    static let shared = BackgroundTaskManager()

    // MARK: - Dependencies

    private let calcService:   CommuteCalculationService
    private let cacheManager:  CommuteCacheManager

    // MARK: - Init

    init(
        calcService:  CommuteCalculationService = CommuteCalculationService(),
        cacheManager: CommuteCacheManager       = CommuteCacheManager()
    ) {
        self.calcService  = calcService
        self.cacheManager = cacheManager
    }

    // MARK: - Registration
    //
    // IMPORTANT: Must be called before application(_:didFinishLaunchingWithOptions:) returns.
    // This is handled by AppDelegate (see AppDelegate.swift).
    // Calling it later causes a fatal error from BGTaskScheduler.

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.refreshTaskIdentifier,
            using: nil               // nil = main queue
        ) { [weak self] task in
            guard let appRefreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self?.handle(task: appRefreshTask)
        }
    }

    // MARK: - Scheduling

    /// Submit (or replace) the next BGAppRefreshTask for the nearest upcoming office day.
    ///
    /// Call sites:
    ///   - AppDelegate.applicationDidBecomeActive (keeps chain alive after app-open)
    ///   - After onboarding completion
    ///   - After settings change (§11.7)
    ///   - At the end of every successful background task run (self-rescheduling chain)
    func scheduleNextRefresh(for settings: UserSettings) {
        guard !settings.officeDays.isEmpty else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskIdentifier)
            return
        }

        guard let targetDate = nextRefreshDate(for: settings) else { return }

        let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskIdentifier)
        // earliestBeginDate tells iOS the EARLIEST it may start the task.
        // The actual start may be later; 2h lead time gives a comfortable buffer.
        request.earliestBeginDate = targetDate

        // Cancel any outstanding request before submitting a new one
        // (BGTaskScheduler allows only one pending request per identifier).
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskIdentifier)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Submission can fail if the identifier is not registered or the app
            // is running in the foreground during simulator testing.
            // This is non-fatal; the fail-safe cache covers the miss.
        }
    }

    func cancelAllPendingRefreshes() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskIdentifier)
    }

    // MARK: - Task execution (called by BGTaskScheduler on main queue)

    private func handle(task: BGAppRefreshTask) {
        // Launch async work; capture the Task so the expiration handler can cancel it.
        let workItem = Task {
            await performRefresh(task: task)
        }

        // iOS is reclaiming background time — cancel gracefully.
        // The cache will serve as fallback for this notification cycle.
        task.expirationHandler = {
            workItem.cancel()
            task.setTaskCompleted(success: false)
        }
    }

    // MARK: - Core refresh logic

    /// The actual background work: recalculate commute, update cache, refresh notification.
    func performRefresh(task: BGAppRefreshTask) async {
        guard let settings = UserSettings.load() else {
            task.setTaskCompleted(success: false)
            return
        }

        // Reschedule immediately so the chain continues even if this run fails.
        scheduleNextRefresh(for: settings)

        let today        = Date()
        let cal          = Calendar.current
        let todayWeekday = cal.component(.weekday, from: today)

        // Nothing to do on non-office days.
        guard settings.officeDays.map(\.rawValue).contains(todayWeekday) else {
            task.setTaskCompleted(success: true)
            return
        }

        do {
            // forceRefresh:true bypasses any active cache — this IS the daily refresh.
            let result = try await calcService.calculate(for: settings, forceRefresh: true)

            // §11.4: Persist the fresh result.
            cacheManager.save(result, for: today)

            // §11.5 trust-first: `updateTodayNotification` re-validates the cache
            // internally before scheduling real content. If the save above succeeded
            // and the clock hasn't crossed midnight, the guard will pass and a Case A
            // notification will be scheduled. Otherwise Case B placeholder stays.
            await NotificationService.shared.updateTodayNotification(
                result:   result,
                settings: settings,
                today:    today
            )

            task.setTaskCompleted(success: true)

        } catch {
            // §11.5: TFL API failed.
            // The Case B placeholder notification is already in place and will fire.
            // When the user taps it, the app performs a forced recalculation (§11.8).
            // No stale data is ever sent as a leave time.
            task.setTaskCompleted(success: false)
        }
    }

    // MARK: - Private date calculation

    /// Returns the target `earliestBeginDate` for the next BGAppRefreshTask:
    /// 2 hours before `notificationTime` on the nearest upcoming office day.
    private func nextRefreshDate(for settings: UserSettings) -> Date? {
        let cal             = Calendar.current
        let now             = Date()
        let officeDayValues = Set(settings.officeDays.map(\.rawValue))

        for offset in 0...6 {
            guard let candidateDay = cal.date(byAdding: .day, value: offset, to: now) else { continue }

            let weekday = cal.component(.weekday, from: candidateDay)
            guard officeDayValues.contains(weekday) else { continue }

            let timeComponents = cal.dateComponents([.hour, .minute], from: settings.notificationTime)
            guard let notifOnDay = cal.date(
                bySettingHour: timeComponents.hour   ?? 7,
                minute:        timeComponents.minute ?? 30,
                second:        0,
                of:            candidateDay
            ) else { continue }

            // Target: 2 hours before the notification fires.
            let refreshTarget = notifOnDay.addingTimeInterval(-2 * 60 * 60)

            if refreshTarget > now {
                return refreshTarget
            }
            // If the refresh window has already passed today, try the next office day.
        }

        return nil
    }
}
