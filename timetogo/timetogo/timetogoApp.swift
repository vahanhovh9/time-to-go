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

    // Global app state: holds onboarding flag + loaded UserSettings.
    // Created once; ContentView reads hasCompletedOnboarding to decide the root view.
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .environmentObject(appState)
                .environmentObject(NotificationService.shared)
        }
    }
}
