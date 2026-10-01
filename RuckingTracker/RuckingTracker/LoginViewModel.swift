//
//  LoginViewModel.swift
//  Rux
//
//  Created by Picos on 11/11/25.
//

import Foundation
import Combine

class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    var socialSignInUnavailableMessage: String {
        AuthService.shared.socialSignInUnavailableMessage
    }

    func loginWithEmail() {
        let trimmedEmail = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email."
            return
        }

        self.isLoading = true
        self.errorMessage = nil

        let password = self.password
        Task { [weak self] in
            do {
                _ = try await APIClient.shared.signIn(email: trimmedEmail, password: password)
                await ActivityStore.shared.refreshFromBackendIfAvailable()
                await MainActor.run {
                    self?.isLoading = false
                    self?.isLoggedIn = true
                    self?.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self?.isLoading = false
                    self?.isLoggedIn = false
                    self?.errorMessage = Self.errorDescription(error)
                }
            }
        }
    }

    private static func errorDescription(_ error: Error) -> String {
        error.localizedDescription
    }
}
