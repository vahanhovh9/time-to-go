import UIKit
import UserNotifications

// MARK: - AppDelegate

/// UIKit application delegate used alongside the SwiftUI @main entry point.
final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // 1. Notifications were removed. Clear anything an older build left scheduled
        //    or delivered so existing installs stop receiving them.
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()

        // 2. App is light-only: force every UIWindow to light mode so system sheets,
        //    navigation bars, and pickers never use Dark Mode chrome (matches Info.plist).
        applyLightInterfaceStyleToAllWindows()

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        applyLightInterfaceStyleToAllWindows()
    }

    /// Ensures newly created windows (e.g. after sheet presentation) stay light.
    private func applyLightInterfaceStyleToAllWindows() {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            windowScene.windows.forEach { $0.overrideUserInterfaceStyle = .light }
        }
    }
}
