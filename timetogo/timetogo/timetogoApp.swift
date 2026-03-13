//
//  timetogoApp.swift
//  timetogo
//
//  Created by Vahan Hovhannisyan on 26/10/2025.
//

import SwiftUI

@main
struct timetogoApp: App {

    // Bridges UIApplicationDelegate into the SwiftUI lifecycle.
    // AppDelegate.application(_:didFinishLaunchingWithOptions:) runs first,
    // which is required for BGTaskScheduler registration and UNUserNotificationCenter
    // delegate setup (both must complete before didFinishLaunching returns).
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject NotificationService so ContentView can observe
                // pendingDeepLink for notification-tap routing (§11.8).
                .environmentObject(NotificationService.shared)
        }
    }
}
