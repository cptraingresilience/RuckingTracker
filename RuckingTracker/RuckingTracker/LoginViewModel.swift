//
//  LoginViewModel.swift
//  Rux
//
//  Created by Picos on 11/11/25.
//

import Foundation
import UIKit

class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    var isSocialSignInAvailable: Bool {
        AuthService.shared.isSocialSignInAvailable
    }

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

    func loginWithGoogle(presenting: UIViewController) {
        guard isSocialSignInAvailable else {
            errorMessage = socialSignInUnavailableMessage
            isLoggedIn = false
            return
        }

        isLoading = true
        AuthService.shared.signInWithGoogle(presenting: presenting) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.isLoggedIn = true
                    self?.errorMessage = nil
                case .failure(let error):
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
