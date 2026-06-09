import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import UIKit

// MARK: - Auth Errors
enum AuthError: Error {
    case missingClientID
    case unknown
    case firebase(Error)
    case apple(Error?)
    case cancelled
    case credentialError(String)
}

// MARK: - Auth Service
final class AuthService: NSObject {
    static let shared = AuthService()
    
    private override init() {}
    private var appleCompletion: ((Result<User, AuthError>) -> Void)?
    private var currentNonce: String?

    // MARK: - Email Auth
    func signInWithEmail(email: String, password: String, completion: @escaping (Result<User, AuthError>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(.firebase(error)))
            } else if let user = result?.user {
                completion(.success(user))
            } else {
                completion(.failure(.unknown))
            }
        }
    }
    
    // MARK: - Google Auth
    func signInWithGoogle(presenting: UIViewController, completion: @escaping (Result<User, AuthError>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(.missingClientID))
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { signInResult, error in
            if let error = error {
                completion(.failure(.firebase(error)))
                return
            }

            guard let user = Auth.auth().currentUser else {
                completion(.failure(.unknown))
                return
            }

            completion(.success(user))
        }
    }

    // MARK: - Apple Auth
    func signInWithApple(presentationAnchor: ASPresentationAnchor, completion: @escaping (Result<User, AuthError>) -> Void) {
        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        self.appleCompletion = completion
        controller.performRequests()
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            appleCompletion?(.failure(.credentialError("Could not retrieve valid Apple identity token.")))
            appleCompletion = nil
            return
        }

        let firebaseCredential = OAuthProvider.appleCredential(withIDToken: tokenString, rawNonce: currentNonce ?? "", fullName: nil)

        Auth.auth().signIn(with: firebaseCredential) { authResult, error in
            if let error = error {
                self.appleCompletion?(.failure(.apple(error)))
            } else if let user = authResult?.user {
                self.appleCompletion?(.success(user))
            } else {
                self.appleCompletion?(.failure(.unknown))
            }
            self.appleCompletion = nil
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleCompletion?(.failure(.apple(error)))
        appleCompletion = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? ASPresentationAnchor()
    }
}

// MARK: - Nonce Utilities
private extension AuthService {
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
