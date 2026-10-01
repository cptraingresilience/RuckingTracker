//
//  SettingsView.swift
//  Rux
//
//  Created by Picos on 11/12/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var loginViewModel: LoginViewModel
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    Text("Profile Details") // Would usually link to further profile editing
                    Text("Change Email")
                    Text("Change Password")
                }
                
                Section(header: Text("Preferences")) {
                    Toggle(isOn: $viewModel.notificationsEnabled) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                            Text("Push Notifications")
                        }
                    }
                    
                    Toggle(isOn: $viewModel.darkModeEnabled) {
                        HStack {
                            Image(systemName: "moon.fill")
                            Text("Dark Mode")
                        }
                    }
                    
                    Picker("Units", selection: $viewModel.selectedUnits) {
                        Text("Imperial").tag("Imperial")
                        Text("Metric").tag("Metric")
                    }
                }
                
                Section(header: Text("Support & About")) {
                    Text("Help Center")
                    Text("Privacy Policy")
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showLogoutConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Log Out", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    APIClient.shared.signOut()
                    loginViewModel.password = ""
                    loginViewModel.isLoggedIn = false
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}

