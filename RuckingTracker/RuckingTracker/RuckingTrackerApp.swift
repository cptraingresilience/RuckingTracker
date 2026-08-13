//
// RuckingTrackerApp.swift
//
//  mod 6.7.26
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct RuckingTrackerApp: App {
    // This connects your AppDelegate to SwiftUI
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            LoginView()
            .onOpenURL { url in
                // This ensures Google Sign-In can process the callback
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
