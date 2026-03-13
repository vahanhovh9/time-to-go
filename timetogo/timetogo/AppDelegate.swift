import UIKit
import BackgroundTasks

// MARK: - AppDelegate

/// UIKit application delegate used alongside the SwiftUI @main entry point.
///
/// Why a UIApplicationDelegate instead of SwiftUI .backgroundTask:
///   BGTaskScheduler.shared.register(forTaskWithIdentifier:using:launchHandler:) MUST be
///   called before application(_:didFinishLaunchingWithOptions:) returns. This is a hard
///   system requirement — missing the window causes a fatal BGTaskScheduler error.
///   The UIApplicationDelegate approach also gives us access to the BGTask object so we
///   can attach an expirationHandler and control task completion manually.
///
/// UNUserNotificationCenterDelegate:
///   NotificationService sets itself as the delegate in its own init(), which runs when
///   `NotificationService.shared` is first accessed (inside this method). The delegate
///   must be set before `application(_:didFinishLaunchingWithOptions:)` returns so that
///   taps from launch-via-notification are captured correctly.
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // 1. Register BGTaskScheduler identifiers.
        //    MUST happen before this method returns.
        BackgroundTaskManager.shared.registerBackgroundTasks()

        // 2. Accessing NotificationService.shared triggers its init(), which calls
        //    UNUserNotificationCenter.current().delegate = self.
        //    This must happen here so notification taps during cold-launch are routed.
        Task {
            await NotificationService.shared.refreshPermissionStatus()
        }

        // 3. Keep the background refresh chain alive after cold launch / force-quit recovery.
        if let settings = UserSettings.load() {
            BackgroundTaskManager.shared.scheduleNextRefresh(for: settings)
        }

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Resubmit the next refresh on every foreground transition.
        // Covers BGTask submissions cancelled by settings change or app termination.
        if let settings = UserSettings.load() {
            BackgroundTaskManager.shared.scheduleNextRefresh(for: settings)
        }
    }
}
