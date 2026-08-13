import Foundation
import Security

// MARK: - Models & Errors
enum APIError: LocalizedError {
    case invalidURL, noInternetConnection, unauthorized
    case serverError(Int), decodingError(String), unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .unauthorized: return "Please sign in to continue."
        case .serverError(let code): return "Server error: \(code)"
        case .decodingError(let message): return message
        case .unknown(let message): return message
        case .noInternetConnection: return "No internet connection."
        }
    }
}

// Internal structures to handle requests without using [String: Any]
struct SignupRequest: Encodable { let email, password, username: String }
struct SigninRequest: Encodable { let email, password: String }

struct AuthResponse: Codable {
    let message: String?
    let accessToken: String
    let refreshToken: String
    let user: UserDTO
}

struct UserDTO: Codable, Identifiable {
    let id: String
    let email: String
    let username: String
    let fullName: String?
}

struct ActivitySubmissionRequest: Codable {
    let id: String
    let title: String
    let notes: String?
    let distance, duration, pace, packWeight: Double?
    let startedAt, endedAt: String
}

struct ActivityResponse: Codable, Identifiable {
    let id: String
    let title: String
    let notes: String
    let distance: Double
    let duration: Double
    let pace: Double
    let packWeight: Double?
    let startedAt: String
    let endedAt: String?
    let createdAt: String
    let updatedAt: String?
}

struct ActivitiesResponse: Codable {
    let activities: [ActivityResponse]
}

struct ActivityMutationResponse: Codable {
    let message: String
    let activity: ActivityResponse
}

struct TeamResponse: Codable, Identifiable {
    let id: String
    let name: String
    let members: [String]?
}

struct TeamsResponse: Codable {
    let teams: [TeamResponse]
}

struct LeaderboardEntryResponse: Codable, Identifiable {
    var id: String { "\(rank)-\(username)" }
    let rank: Int
    let username: String
    let totalDistance: Double
    let totalActivities: Int
}

struct LeaderboardResponse: Codable {
    let period: String
    let entries: [LeaderboardEntryResponse]
}

private struct ErrorResponse: Decodable {
    let error: String
}

// MARK: - API Client
class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private var accessToken: String?
    private let decoder: JSONDecoder
    private let tokenService = "com.cptraingresilience.RuckingTracker"
    private let tokenAccount = "rt_access_token"

    private init() {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.accessToken = nil
        self.accessToken = loadStoredToken()
    }

    var hasAccessToken: Bool {
        accessToken?.isEmpty == false
    }

    private var baseURL: String {
        if let customURL = UserDefaults.standard.string(forKey: "rt_backend_url"),
           !customURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customURL
        }

        if let configuredURL = Bundle.main.object(forInfoDictionaryKey: "BackendBaseURL") as? String,
           !configuredURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return configuredURL
        }

        return "http://localhost:3000/api"
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
        deleteStoredToken()
    }

    // MARK: - Activities

    func getActivities() async throws -> [ActivityResponse] {
        let response: ActivitiesResponse = try await request(url: "\(baseURL)/activities", method: "GET", requiresAuth: true)
        return response.activities
    }

    func submitActivity(_ activity: ActivitySubmissionRequest) async throws -> ActivityResponse {
        let response: ActivityMutationResponse = try await request(url: "\(baseURL)/activities", method: "POST", body: activity, requiresAuth: true)
        return response.activity
    }

    func updateActivity(id: String, _ activity: ActivitySubmissionRequest) async throws -> ActivityResponse {
        let response: ActivityMutationResponse = try await request(url: "\(baseURL)/activities/\(id)", method: "PUT", body: activity, requiresAuth: true)
        return response.activity
    }

    func deleteActivity(id: String) async throws {
        let _: DeleteResponse = try await request(url: "\(baseURL)/activities/\(id)", method: "DELETE", requiresAuth: true)
    }

    func getTeams() async throws -> [TeamResponse] {
        let response: TeamsResponse = try await request(url: "\(baseURL)/teams", method: "GET")
        return response.teams
    }

    func getLeaderboard() async throws -> [LeaderboardEntryResponse] {
        let response: LeaderboardResponse = try await request(url: "\(baseURL)/leaderboard", method: "GET")
        return response.entries
    }

    // MARK: - Token Storage

    private func storeToken(_ token: String) {
        accessToken = token
        storeTokenInKeychain(token)
    }

    private func loadStoredToken() -> String? {
        if let keychainToken = loadTokenFromKeychain() {
            return keychainToken
        }

        if let legacyToken = UserDefaults.standard.string(forKey: "rt_access_token") {
            storeTokenInKeychain(legacyToken)
            UserDefaults.standard.removeObject(forKey: "rt_access_token")
            return legacyToken
        }

        return nil
    }

    private func loadTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tokenService,
            kSecAttrAccount as String: tokenAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    private func storeTokenInKeychain(_ token: String) {
        let tokenData = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tokenService,
            kSecAttrAccount as String: tokenAccount
        ]

        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tokenService,
            kSecAttrAccount as String: tokenAccount,
            kSecValueData as String: tokenData
        ]

        SecItemAdd(attributes as CFDictionary, nil)
    }

    private func deleteStoredToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tokenService,
            kSecAttrAccount as String: tokenAccount
        ]

        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: "rt_access_token")
    }

    // MARK: - Generic Request Handler

    private func request<T: Decodable>(
        url: String,
        method: String,
        requiresAuth: Bool = false
    ) async throws -> T {
        try await request(url: url, method: method, body: Optional<String>.none, requiresAuth: requiresAuth)
    }

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
        } else if requiresAuth {
            throw APIError.unauthorized
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.unknown(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response")
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                throw APIError.unknown(errorResponse.error)
            }

            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError("Could not read the server response.")
        }
    }
}

private struct DeleteResponse: Decodable {
    let message: String
}
