import Foundation
import Vapor

struct RegisterRequest: Content, Validatable {
    var name: String
    var email: String
    var password: String
    var phone: String?

    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
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
    var name: String
    var email: String
    var phone: String?

    init(_ user: User) throws {
        self.id = try user.requireID()
        self.name = user.name
        self.email = user.email
        self.phone = user.phone
    }
}

struct AuthResponse: Content {
    var token: String
    var user: UserResponse
}
