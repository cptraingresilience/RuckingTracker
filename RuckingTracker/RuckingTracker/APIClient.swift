import Foundation
import Security

// MARK: - Models & Errors
enum APIError: LocalizedError {
    case invalidURL
    case backendConfiguration(String)
    case noInternetConnection
    case unauthorized
    case serverError(Int)
    case decodingError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .backendConfiguration(let message):
            return message
        case .noInternetConnection:
            return "No internet connection."
        case .unauthorized:
            return "Please sign in to continue."
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError(let message):
            return message
        case .unknown(let message):
            return message
        }
    }
}

struct SignupRequest: Encodable { let email, password, username: String }
struct SigninRequest: Encodable { let email, password: String }
private struct RefreshRequest: Encodable { let refreshToken: String }
private struct RefreshResponse: Decodable { let accessToken: String; let refreshToken: String }

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

extension Notification.Name {
    static let apiClientCurrentUserDidChange = Notification.Name("APIClientCurrentUserDidChange")
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

private enum BackendConfiguration {
    private static let debugOverrideKey = "rt_backend_url"
    private static let productionBaseURLKey = "BackendProductionBaseURL"
    private static let simulatorBaseURLKey = "BackendSimulatorBaseURL"
    private static let localNetworkBaseURLKey = "BackendLocalNetworkBaseURL"

    static func resolveBaseURL(bundle: Bundle = .main, userDefaults: UserDefaults = .standard) throws -> URL {
        #if DEBUG
        if let overrideURL = try resolveDebugOverride(userDefaults: userDefaults) {
            return overrideURL
        }

        #if targetEnvironment(simulator)
        if let simulatorURL = try configuredURL(for: simulatorBaseURLKey, in: bundle, requireHTTPS: false, allowLoopback: true) {
            return simulatorURL
        }
        return try validatedURL(
            "http://127.0.0.1:3000/api",
            source: simulatorBaseURLKey,
            requireHTTPS: false,
            allowLoopback: true
        )
        #else
        if let localNetworkURL = try configuredURL(for: localNetworkBaseURLKey, in: bundle, requireHTTPS: false, allowLoopback: false) {
            return localNetworkURL
        }
        if let productionURL = try configuredURL(for: productionBaseURLKey, in: bundle, requireHTTPS: true, allowLoopback: false) {
            return productionURL
        }
        throw APIError.backendConfiguration("Set BackendLocalNetworkBaseURL to your Mac's LAN API URL for physical-device debug builds.")
        #endif
        #else
        if let productionURL = try configuredURL(for: productionBaseURLKey, in: bundle, requireHTTPS: true, allowLoopback: false) {
            return productionURL
        }
        throw APIError.backendConfiguration("The production backend is not configured. Set BackendProductionBaseURL to an HTTPS API before shipping.")
        #endif
    }

    #if DEBUG
    private static func resolveDebugOverride(userDefaults: UserDefaults) throws -> URL? {
        guard let rawValue = userDefaults.string(forKey: debugOverrideKey),
              !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        #if targetEnvironment(simulator)
        return try validatedURL(rawValue, source: debugOverrideKey, requireHTTPS: false, allowLoopback: true)
        #else
        return try validatedURL(rawValue, source: debugOverrideKey, requireHTTPS: false, allowLoopback: false)
        #endif
    }
    #endif

    private static func configuredURL(for key: String, in bundle: Bundle, requireHTTPS: Bool, allowLoopback: Bool) throws -> URL? {
        guard let rawValue = bundle.object(forInfoDictionaryKey: key) as? String,
              !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return try validatedURL(rawValue, source: key, requireHTTPS: requireHTTPS, allowLoopback: allowLoopback)
    }

    private static func validatedURL(_ rawValue: String, source: String, requireHTTPS: Bool, allowLoopback: Bool) throws -> URL {
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedValue),
              let scheme = url.scheme?.lowercased(),
              let host = url.host,
              !host.isEmpty else {
            throw APIError.backendConfiguration("\(source) must be a full URL including scheme and host.")
        }

        if requireHTTPS && scheme != "https" {
            throw APIError.backendConfiguration("\(source) must use HTTPS.")
        }

        if !requireHTTPS && scheme != "http" && scheme != "https" {
            throw APIError.backendConfiguration("\(source) must use http or https.")
        }

        if !allowLoopback && isLoopbackHost(host) {
            throw APIError.backendConfiguration("\(source) cannot use localhost on a physical device or release build.")
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }

        if components.path == "/" {
            components.path = ""
        } else {
            components.path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).isEmpty
                ? ""
                : "/" + components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }

        guard let normalizedURL = components.url else {
            throw APIError.invalidURL
        }

        return normalizedURL
    }

    private static func isLoopbackHost(_ host: String) -> Bool {
        let normalizedHost = host.lowercased()
        return normalizedHost == "localhost" || normalizedHost == "127.0.0.1" || normalizedHost == "::1"
    }
}

// MARK: - API Client
class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private var accessToken: String?
    private var refreshToken: String?
    private(set) var currentUser: UserDTO?
    private let decoder: JSONDecoder
    private let tokenService = "com.cptraingresilience.RuckingTracker"
    private let accessTokenAccount = "rt_access_token"
    private let refreshTokenAccount = "rt_refresh_token"
    private let currentUserDefaultsKey = "rt_current_user"

    private init() {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.accessToken = loadStoredToken(account: accessTokenAccount)
        self.refreshToken = loadStoredToken(account: refreshTokenAccount)
        self.currentUser = loadStoredCurrentUser()
    }

    var hasAccessToken: Bool {
        accessToken?.isEmpty == false || refreshToken?.isEmpty == false
    }

    // MARK: - Auth

    func signUp(email: String, password: String, username: String) async throws -> AuthResponse {
        let body = SignupRequest(email: email, password: password, username: username)
        let response: AuthResponse = try await request(path: "/auth/signup", method: "POST", body: body)
        storeTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        storeCurrentUser(response.user)
        return response
    }

    func signIn(email: String, password: String) async throws -> AuthResponse {
        let body = SigninRequest(email: email, password: password)
        let response: AuthResponse = try await request(path: "/auth/signin", method: "POST", body: body)
        storeTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        storeCurrentUser(response.user)
        return response
    }

    func signOut() {
        accessToken = nil
        refreshToken = nil
        storeCurrentUser(nil)
        deleteStoredToken(account: accessTokenAccount)
        deleteStoredToken(account: refreshTokenAccount)
        UserDefaults.standard.removeObject(forKey: accessTokenAccount)
    }

    // MARK: - Activities

    func getActivities() async throws -> [ActivityResponse] {
        let response: ActivitiesResponse = try await request(path: "/activities", method: "GET", requiresAuth: true)
        return response.activities
    }

    func submitActivity(_ activity: ActivitySubmissionRequest) async throws -> ActivityResponse {
        let response: ActivityMutationResponse = try await request(path: "/activities", method: "POST", body: activity, requiresAuth: true)
        return response.activity
    }

    func updateActivity(id: String, _ activity: ActivitySubmissionRequest) async throws -> ActivityResponse {
        let response: ActivityMutationResponse = try await request(path: "/activities/\(id)", method: "PUT", body: activity, requiresAuth: true)
        return response.activity
    }

    func deleteActivity(id: String) async throws {
        let _: DeleteResponse = try await request(path: "/activities/\(id)", method: "DELETE", requiresAuth: true)
    }

    func getTeams() async throws -> [TeamResponse] {
        let response: TeamsResponse = try await request(path: "/teams", method: "GET")
        return response.teams
    }

    func getLeaderboard(teamId: String? = nil) async throws -> [LeaderboardEntryResponse] {
        let queryItems = teamId.map { [URLQueryItem(name: "teamId", value: $0)] } ?? []
        let response: LeaderboardResponse = try await request(
            path: "/leaderboard",
            method: "GET",
            queryItems: queryItems
        )
        return response.entries
    }

    // MARK: - Token Storage

    private func storeTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        storeTokenInKeychain(accessToken, account: accessTokenAccount)
        storeTokenInKeychain(refreshToken, account: refreshTokenAccount)
    }

    private func loadStoredCurrentUser() -> UserDTO? {
        guard let data = UserDefaults.standard.data(forKey: currentUserDefaultsKey) else {
            return nil
        }

        return try? decoder.decode(UserDTO.self, from: data)
    }

    private func storeCurrentUser(_ user: UserDTO?) {
        currentUser = user

        if let user, let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: currentUserDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: currentUserDefaultsKey)
        }

        NotificationCenter.default.post(name: .apiClientCurrentUserDidChange, object: nil)
    }

    private func loadStoredToken(account: String) -> String? {
        if let keychainToken = loadTokenFromKeychain(account: account) {
            return keychainToken
        }

        if account == accessTokenAccount,
           let legacyToken = UserDefaults.standard.string(forKey: accessTokenAccount) {
            storeTokenInKeychain(legacyToken, account: accessTokenAccount)
            UserDefaults.standard.removeObject(forKey: accessTokenAccount)
            return legacyToken
        }

        return nil
    }

    private func loadTokenFromKeychain(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tokenService,
            kSecAttrAccount as String: account,
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

    private func storeTokenInKeychain(_ token: String, account: String) {
        let tokenData = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tokenService,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tokenService,
            kSecAttrAccount as String: account,
            kSecValueData as String: tokenData
        ]

        SecItemAdd(attributes as CFDictionary, nil)
    }

    private func deleteStoredToken(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: tokenService,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Generic Request Handler

    private func request<T: Decodable>(
        path: String,
        method: String,
        requiresAuth: Bool = false,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        try await request(
            path: path,
            method: method,
            body: Optional<String>.none,
            requiresAuth: requiresAuth,
            queryItems: queryItems
        )
    }

    private func request<T: Decodable, B: Encodable>(
        path: String,
        method: String,
        body: B? = nil,
        requiresAuth: Bool = false,
        allowsTokenRefresh: Bool = true,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        var request = URLRequest(url: try endpointURL(for: path, queryItems: queryItems))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth {
            if accessToken?.isEmpty != false {
                let didRefresh = try await refreshAccessToken()
                guard didRefresh else {
                    signOut()
                    throw APIError.unauthorized
                }
            }

            guard let accessToken, !accessToken.isEmpty else {
                signOut()
                throw APIError.unauthorized
            }

            request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                throw APIError.noInternetConnection
            case .timedOut, .cannotConnectToHost, .cannotFindHost, .networkConnectionLost:
                throw APIError.unknown("Unable to reach the server.")
            default:
                throw APIError.unknown(urlError.localizedDescription)
            }
        } catch {
            throw APIError.unknown(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response")
        }

        if requiresAuth && allowsTokenRefresh && [401, 403].contains(httpResponse.statusCode) {
            let didRefresh = try await refreshAccessToken()
            guard didRefresh else {
                signOut()
                throw APIError.unauthorized
            }

            return try await request(
                path: path,
                method: method,
                body: body,
                requiresAuth: requiresAuth,
                allowsTokenRefresh: false,
                queryItems: queryItems
            )
        }

        if requiresAuth && [401, 403].contains(httpResponse.statusCode) {
            signOut()
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

    private func refreshAccessToken() async throws -> Bool {
        guard let refreshToken, !refreshToken.isEmpty else {
            return false
        }

        do {
            let response: RefreshResponse = try await request(
                path: "/auth/refresh",
                method: "POST",
                body: RefreshRequest(refreshToken: refreshToken),
                requiresAuth: false,
                allowsTokenRefresh: false
            )
            storeTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
            return true
        } catch APIError.unauthorized {
            return false
        } catch APIError.serverError(let code) where code == 401 || code == 403 {
            return false
        } catch APIError.unknown(let message) where message == "Invalid refresh token" {
            return false
        }
    }

    private func endpointURL(for path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        let baseURL = try BackendConfiguration.resolveBaseURL()
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL
        }

        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let suffix = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = "/" + [basePath, suffix].filter { !$0.isEmpty }.joined(separator: "/")
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        return url
    }
}

private struct DeleteResponse: Decodable {
    let message: String
}
