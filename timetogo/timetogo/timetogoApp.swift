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
    // Used to force light interface style on every UIWindow.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Global app state: holds onboarding flag + loaded UserSettings.
    // Created once; ContentView reads hasCompletedOnboarding to decide the root view.
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                // Text follows the user's text size up to the largest standard size; beyond
                // that the illustrated headers and fixed-height controls can't fit it.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .environmentObject(appState)
        }
    }
}
