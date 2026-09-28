import Foundation
import AuthenticationServices
import UIKit

enum AuthError: LocalizedError {
    case unsupported(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .unsupported(let message):
            return message
        case .unknown:
            return "Unknown error occurred."
        }
    }
}

final class AuthService {
    static let shared = AuthService()

    let socialSignInUnavailableMessage = "Google and Apple sign-in are temporarily unavailable until the backend supports social account token exchange. Use email sign-in."

    private init() {}

    var isSocialSignInAvailable: Bool {
        false
    }

    func signInWithEmail(email _: String, password _: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        completion(.failure(.unsupported("Email authentication is handled by the Rux backend API.")))
    }

    func signInWithGoogle(presenting _: UIViewController, completion: @escaping (Result<Void, AuthError>) -> Void) {
        completion(.failure(.unsupported(socialSignInUnavailableMessage)))
    }

    func signInWithApple(presentationAnchor _: ASPresentationAnchor, completion: @escaping (Result<Void, AuthError>) -> Void) {
        completion(.failure(.unsupported(socialSignInUnavailableMessage)))
    }
}
