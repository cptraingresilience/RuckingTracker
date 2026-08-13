import Foundation

// MARK: - Models & Errors
enum APIError: LocalizedError {
    case invalidURL, noInternetConnection, unauthorized
    case serverError(Int), decodingError(String), unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .serverError(let code): return "Server error: \(code)"
        default: return "An error occurred"
        }
    }
}

// Internal structures to handle requests without using [String: Any]
struct SignupRequest: Encodable { let email, password, username: String }
struct SigninRequest: Encodable { let email, password: String }

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: UserDTO
}

struct UserDTO: Codable, Identifiable {
    let id, email, username: String
    let fullName: String?
}

struct ActivitySubmissionRequest: Codable {
    let title: String
    let notes: String?
    let distance, duration, pace, packWeight: Double?
    let startedAt, endedAt: String
}

struct ActivityUpdateRequest: Codable {
    let title: String
    let notes: String?
    let distance, duration, pace, packWeight: Double?
    let startedAt, endedAt: String
}

struct ActivityResponse: Codable, Identifiable {
    let id: String
    let title: String
    let distance, duration, pace: Double
    let isValidated: Bool
    let createdAt: String
}

// MARK: - API Client
class APIClient {
    static let shared = APIClient()

    // Change this to match your backend host.
    // Default: developer LAN IP. For local dev use http://localhost:3000/api
    private let baseURL = "http://172.20.10.8:3000/api"
    private let session: URLSession
    private var accessToken: String?

    private init() {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
        self.accessToken = UserDefaults.standard.string(forKey: "rt_access_token")
    }

    // MARK: - Auth

    func signUp(email: String, password: String, username: String) async throws -> AuthResponse {
        let body = SignupRequest(email: email, password: password, username: username)
        let response: AuthResponse = try await request(url: "\(baseURL)/auth/signup", method: "POST", body: body)
        storeToken(response.accessToken)
        return response
    }

    func signIn(email: String, password: String) async throws -> AuthResponse {
        let body = SigninRequest(email: email, password: password)
        let response: AuthResponse = try await request(url: "\(baseURL)/auth/signin", method: "POST", body: body)
        storeToken(response.accessToken)
        return response
    }

    func signOut() {
        accessToken = nil
        UserDefaults.standard.removeObject(forKey: "rt_access_token")
    }

    // MARK: - Activities

    func getActivities() async throws -> [ActivityResponse] {
        return try await request(url: "\(baseURL)/activities", method: "GET", requiresAuth: true)
    }

    func submitActivity(_ activity: ActivitySubmissionRequest) async throws -> ActivityResponse {
        return try await request(url: "\(baseURL)/activities", method: "POST", body: activity, requiresAuth: true)
    }

    func updateActivity(id: String, _ activity: ActivityUpdateRequest) async throws -> ActivityResponse {
        return try await request(url: "\(baseURL)/activities/\(id)", method: "PUT", body: activity, requiresAuth: true)
    }

    func deleteActivity(id: String) async throws {
        let _: EmptyResponse = try await request(url: "\(baseURL)/activities/\(id)", method: "DELETE", requiresAuth: true)
    }

    // MARK: - Token Storage

    private func storeToken(_ token: String) {
        accessToken = token
        UserDefaults.standard.set(token, forKey: "rt_access_token")
    }

    // MARK: - Generic Request Handler

    private func request<T: Decodable, B: Encodable>(
        url: String,
        method: String,
        body: B? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        guard let url = URL(string: url) else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = accessToken {
            request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response")
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

// Used as a placeholder return type for DELETE responses with no body
private struct EmptyResponse: Decodable {}
