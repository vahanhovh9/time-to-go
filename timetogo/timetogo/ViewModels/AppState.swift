import Foundation
import Combine

/// Global app state that drives the root navigation decision.
///
/// On init, loads persisted data from UserDefaults:
///   - `hasCompletedOnboarding` (Bool flag)
///   - `settings` (UserSettings JSON)
///
/// ContentView observes this to decide: onboarding flow vs MainView.
/// All mutations go through methods here — no persistence logic in Views.
@MainActor
final class AppState: ObservableObject {

    // MARK: - Published state

    @Published private(set) var hasCompletedOnboarding: Bool
    @Published private(set) var settings: UserSettings?
    /// True when the user tapped "Change your settings" and is re-editing.
    /// Onboarding views should pre-fill from `settings` when this is true.
    @Published private(set) var isEditingSettings: Bool = false

    // MARK: - Storage keys

    private static let onboardingKey = "com.timetogo.hasCompletedOnboarding"

    // MARK: - Init

    init() {
        let completed = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        self.hasCompletedOnboarding = completed
        self.settings = completed ? UserSettings.load() : nil
    }

    // MARK: - Onboarding completion

    /// Called once when the user taps "All done" on the success screen.
    /// Persists settings, sets the onboarding flag, schedules notifications
    /// and background tasks — everything needed for autonomous operation.
    func completeOnboarding(with settings: UserSettings) {
        settings.save()
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)

        self.settings = settings
        self.hasCompletedOnboarding = true

        Task {
            await NotificationService.shared.requestPermission()
            await NotificationService.shared.scheduleNotifications(for: settings)
        }
        BackgroundTaskManager.shared.scheduleNextRefresh(for: settings)
    }

    // MARK: - Settings editing ("Change your settings")

    /// Enters settings-edit mode: shows onboarding flow with fields pre-filled.
    /// Does NOT wipe saved data — the existing settings stay in `self.settings`.
    func enterSettingsEditMode() {
        isEditingSettings = true
        hasCompletedOnboarding = false   // triggers ContentView to show onboarding
    }

    /// Called when the user finishes re-editing settings (taps "All done" again).
    /// Persists updated settings and reschedules notifications + background tasks (§11.9).
    func finishSettingsEdit(with newSettings: UserSettings) {
        newSettings.save()
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)

        self.settings = newSettings
        self.isEditingSettings = false
        self.hasCompletedOnboarding = true

        Task {
            await NotificationService.shared.reschedule(for: newSettings)
        }
        BackgroundTaskManager.shared.scheduleNextRefresh(for: newSettings)
    }

    // MARK: - Reset (for testing)

    /// Wipes all persisted data and returns to onboarding.
    func reset() {
        UserDefaults.standard.set(false, forKey: Self.onboardingKey)
        UserSettings.clear()
        CommuteCacheManager().clear()
        NotificationService.shared.cancelAllPendingNotifications()
        BackgroundTaskManager.shared.cancelAllPendingRefreshes()

        self.settings = nil
        self.hasCompletedOnboarding = false
    }
}
