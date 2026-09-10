import Foundation
import Vapor

struct RegisterRequest: Content, Validatable {
    var email: String
    var password: String

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}

struct LoginRequest: Content {
    var email: String
    var password: String
}

struct UserResponse: Content {
    var id: UUID
    var email: String

    init(_ user: User) throws {
        self.id = try user.requireID()
        self.email = user.email
    }
}

struct AuthResponse: Content {
    var token: String
    var user: UserResponse
}
