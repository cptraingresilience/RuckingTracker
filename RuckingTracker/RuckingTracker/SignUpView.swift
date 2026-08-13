//
//  SignUpView.swift
//  RuckingTracker
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var didSignUp = false

    var body: some View {
        NavigationView {
            VStack(spacing: 26) {
                Spacer(minLength: 40)

                VStack(spacing: 6) {
                    Text("Create Account")
                        .font(.largeTitle.bold())
                    Text("Start tracking your rucks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 14) {
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)

                    SecureField("Password (min 6 characters)", text: $password)
                        .padding()
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(10)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button(action: signUp) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(isLoading)
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $didSignUp) {
                TabViewMain()
            }
        }
    }

    // MARK: - Actions

    private func signUp() {
        errorMessage = nil

        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        guard !trimmedUsername.isEmpty else {
            errorMessage = "Please enter a username."
            return
        }
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true

        Task {
            do {
                _ = try await APIClient.shared.signUp(
                    email: trimmedEmail,
                    password: password,
                    username: trimmedUsername
                )
                await MainActor.run {
                    isLoading = false
                    didSignUp = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
