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
    private let baseURL = "http://172.20.10.8:3000/api"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - API Methods
    
    func signUp(email: String, password: String, username: String) async throws -> AuthResponse {
        let body = SignupRequest(email: email, password: password, username: username)
        return try await request(url: "\(baseURL)/auth/signup", method: "POST", body: body)
    }
    
    func signIn(email: String, password: String) async throws -> AuthResponse {
        let body = SigninRequest(email: email, password: password)
        return try await request(url: "\(baseURL)/auth/signin", method: "POST", body: body)
    }
    
    func submitActivity(_ activity: ActivitySubmissionRequest) async throws -> ActivityResponse {
        return try await request(url: "\(baseURL)/activities", method: "POST", body: activity)
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
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
