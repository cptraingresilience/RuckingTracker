//
// RuckingTrackerApp.swift
//
//  mod 6.7.26
//

import SwiftUI

@main
struct RuckingTrackerApp: App {
    // This connects your AppDelegate to SwiftUI
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}
