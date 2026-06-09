//
//  LoginViewModel.swift
//  Rux
//
//  Created by Picos on 11/11/25.
//

import Foundation
import Combine
import FirebaseAuth
import UIKit

class LoginViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Email Login
    func loginWithEmail() {
        self.isLoading = true
        AuthService.shared.signInWithEmail(email: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(_):
                    self?.isLoggedIn = true
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.isLoggedIn = false
                    self?.errorMessage = Self.errorDescription(error)
                }
            }
        }
    }
    
    // MARK: - Google Login
    func loginWithGoogle(presenting: UIViewController) {
        self.isLoading = true
        AuthService.shared.signInWithGoogle(presenting: presenting) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(_):
                    self?.isLoggedIn = true
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.isLoggedIn = false
                    self?.errorMessage = Self.errorDescription(error)
                }
            }
        }
    }

    // If integrating Apple login:
    /*
    func loginWithApple(presentationAnchor: ASPresentationAnchor) {
        self.isLoading = true
        AuthService.shared.signInWithApple(presentationAnchor: presentationAnchor) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(_):
                    self?.isLoggedIn = true
                    self?.errorMessage = nil
                case .failure(let error):
                    self?.isLoggedIn = false
                    self?.errorMessage = Self.errorDescription(error)
                }
            }
        }
    }
    */

    // MARK: - Error Formatting
    private static func errorDescription(_ error: Error) -> String {
        switch error {
        case is AuthError:
            switch error as! AuthError {
            case .missingClientID:
                return "Missing Firebase client ID."
            case .unknown:
                return "Unknown error occurred."
            case .firebase(let e):
                return "Auth error: \(e.localizedDescription)"
            case .apple(let appleError):
                return "Apple login error: \(appleError?.localizedDescription ?? "unknown")"
            case .cancelled:
                return "Login cancelled."
            case .credentialError(let message):
                return "Credential error: \(message)"
            }
        default:
            return error.localizedDescription
        }
    }
}
