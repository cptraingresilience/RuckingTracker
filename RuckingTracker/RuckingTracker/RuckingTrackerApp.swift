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
            VStack {
                Text("Testing Backend Connection...")
                    .font(.headline)
                    .padding()
                
                LoginView()
            }
            .onOpenURL { url in
                // This ensures Google Sign-In can process the callback
                GIDSignIn.sharedInstance.handle(url)
            }
            .onAppear {
                testBackendConnection()
            }
        }
    }
    
    func testBackendConnection() {
        Task {
            do {
                let response = try await APIClient.shared.signUp(
                    email: "test@example.com",
                    password: "password123",
                    username: "testuser"
                )
                print("✅ Backend Connected!")
                print("✅ Got Access Token:", response.accessToken.prefix(20) + "...")
            } catch {
                print("❌ Backend Error:", error)
            }
        }
    }
}
