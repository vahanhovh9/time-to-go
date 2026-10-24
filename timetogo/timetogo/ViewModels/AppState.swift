import Foundation
import Combine

/// Global app state that drives the root navigation decision.
///
/// On init, loads persisted data from UserDefaults:
///   - `hasCompletedSetup` (Bool flag)
///   - `settings` (UserSettings JSON)
///
/// ContentView observes this to decide: setup flow vs MainView.
/// All mutations go through methods here — no persistence logic in Views.
@MainActor
final class AppState: ObservableObject {

    // MARK: - Published state

    @Published private(set) var hasCompletedSetup: Bool
    /// The intro screens (what TimeToGo is) have been shown once, before setup.
    @Published private(set) var hasSeenIntro: Bool
    @Published private(set) var settings: UserSettings?
    /// True when the user tapped "Change your settings" and is re-editing.
    /// Setup views should pre-fill from `settings` when this is true.
    @Published private(set) var isEditingSettings: Bool = false

    // MARK: - Storage keys

    /// Still says "Onboarding" (setup's old name) so existing installs stay set up.
    private static let setupKey = "com.timetogo.hasCompletedOnboarding"
    private static let introKey = "com.timetogo.hasSeenIntro"

    // MARK: - Init

    init() {
        let completed = UserDefaults.standard.bool(forKey: Self.setupKey)
        self.hasCompletedSetup = completed
        self.settings = completed ? UserSettings.load() : nil
        // People who set up before the intro existed never need it.
        self.hasSeenIntro = completed || UserDefaults.standard.bool(forKey: Self.introKey)
    }

    // MARK: - Intro

    /// Called from the intro's Skip or last button; setup follows.
    func finishIntro() {
        UserDefaults.standard.set(true, forKey: Self.introKey)
        hasSeenIntro = true
    }

    // MARK: - Setup completion

    /// Called once when the user taps "All done" on the success screen.
    /// Persists settings and sets the setup flag.
    func completeSetup(with settings: UserSettings) {
        settings.save()
        UserDefaults.standard.set(true, forKey: Self.setupKey)

        self.settings = settings
        self.hasCompletedSetup = true
    }

    // MARK: - Settings editing ("Change your settings")

    /// Enters settings-edit mode: shows setup flow with fields pre-filled.
    /// Does NOT wipe saved data — the existing settings stay in `self.settings`.
    func enterSettingsEditMode() {
        isEditingSettings = true
        hasCompletedSetup = false   // triggers ContentView to show setup
    }

    /// Called when the user finishes re-editing settings (taps "All done" again).
    /// Persists updated settings.
    func finishSettingsEdit(with newSettings: UserSettings) {
        newSettings.save()
        UserDefaults.standard.set(true, forKey: Self.setupKey)

        self.settings = newSettings
        self.isEditingSettings = false
        self.hasCompletedSetup = true
    }

    // MARK: - Settings update (from SettingsView)

    func updateSettings(_ newSettings: UserSettings) {
        newSettings.save()
        UserDefaults.standard.set(true, forKey: Self.setupKey)
        self.settings = newSettings
    }

    // MARK: - Reset (for testing)

    /// Wipes all persisted data and returns to setup.
    func reset() {
        UserDefaults.standard.set(false, forKey: Self.setupKey)
        UserDefaults.standard.set(false, forKey: Self.introKey)
        UserSettings.clear()
        CommuteCacheManager().clear()

        self.settings = nil
        self.hasCompletedSetup = false
        self.hasSeenIntro = false
    }
}
