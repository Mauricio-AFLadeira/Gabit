import Foundation

/// Mirrors `Sources/Server/DTOs/AuthDTOs.swift`. The app and the server are
/// different SPM targets (the app never links `Server`), so the shape is
/// duplicated here — deliberately small enough that keeping the two in sync
/// by hand is cheaper than sharing a module across a Linux/iOS boundary.
struct AuthUser: Codable, Equatable {
    let id: UUID
    let name: String
    let email: String
    let phone: String?
}

struct AuthSession: Codable, Equatable {
    let token: String
    let user: AuthUser
}

/// The `{ "error": true, "reason": "..." }` body Vapor's `Abort` produces.
private struct APIErrorBody: Decodable {
    let reason: String
}

enum APIError: LocalizedError {
    case server(String)
    case invalidResponse
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .server(let reason): return reason
        case .invalidResponse: return "Something went wrong. Please try again."
        case .transport: return "Couldn't reach the server. Check your connection."
        }
    }

    /// Turns a non-2xx response body into a server-message error where
    /// possible, falling back to a generic one.
    static func fromErrorBody(_ data: Data) -> APIError {
        guard let body = try? JSONDecoder().decode(APIErrorBody.self, from: data) else {
            return .invalidResponse
        }
        return .server(body.reason)
    }
}
