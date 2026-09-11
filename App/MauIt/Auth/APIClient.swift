import Foundation

/// Base URL for the Vapor backend (`Sources/Server`). The simulator reaches
/// the Docker Compose `app` service through the host's loopback interface,
/// so `localhost` resolves correctly with zero setup; a physical device
/// needs the Mac's LAN IP here instead.
enum APIConfig {
    static let baseURL = URL(string: "http://localhost:8080")!
}

private struct RegisterPayload: Encodable {
    let name: String
    let email: String
    let password: String
    let phone: String?
}

private struct LoginPayload: Encodable {
    let email: String
    let password: String
}

struct APIClient {
    var baseURL = APIConfig.baseURL

    private let session = URLSession.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func register(name: String, email: String, password: String, phone: String?) async throws -> AuthSession {
        try await send(
            path: "auth/register", body: RegisterPayload(name: name, email: email, password: password, phone: phone))
    }

    func login(email: String, password: String) async throws -> AuthSession {
        try await send(path: "auth/login", body: LoginPayload(email: email, password: password))
    }

    private func send<Body: Encodable>(path: String, body: Body) async throws -> AuthSession {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.fromErrorBody(data)
        }

        do {
            return try decoder.decode(AuthSession.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }
}
