import Foundation

final class AuthService {
    static let shared = AuthService()

    let socialSignInUnavailableMessage = "Google and Apple sign-in are temporarily unavailable until the backend supports social account token exchange. Use email sign-in."

    private init() {}
}
