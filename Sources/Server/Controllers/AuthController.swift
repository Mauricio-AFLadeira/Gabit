import Fluent
import Foundation
import Vapor

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("register", use: register)
        auth.post("login", use: login)

        let protected = auth.grouped(UserPayloadAuthenticator(), UserPayload.guardMiddleware())
        protected.get("me", use: me)
    }

    @Sendable
    func register(req: Request) async throws -> AuthResponse {
        try RegisterRequest.validate(content: req)
        let payload = try req.content.decode(RegisterRequest.self)
        let email = payload.email.lowercased()

        guard try await User.query(on: req.db).filter(\.$email == email).first() == nil else {
            throw Abort(.conflict, reason: "Email already registered.")
        }

        let user = User(
            name: payload.name,
            email: email,
            passwordHash: try Bcrypt.hash(payload.password),
            phone: payload.phone
        )
        try await user.save(on: req.db)

        return try AuthResponse(token: signToken(for: user, req: req), user: UserResponse(user))
    }

    @Sendable
    func login(req: Request) async throws -> AuthResponse {
        let payload = try req.content.decode(LoginRequest.self)

        guard
            let user = try await User.query(on: req.db)
                .filter(\.$email == payload.email.lowercased())
                .first(),
            try Bcrypt.verify(payload.password, created: user.passwordHash)
        else {
            throw Abort(.unauthorized, reason: "Invalid email or password.")
        }

        return try AuthResponse(token: signToken(for: user, req: req), user: UserResponse(user))
    }

    @Sendable
    func me(req: Request) async throws -> UserResponse {
        let payload = try req.auth.require(UserPayload.self)
        guard
            let id = UUID(uuidString: payload.subject.value),
            let user = try await User.find(id, on: req.db)
        else {
            throw Abort(.unauthorized)
        }
        return try UserResponse(user)
    }

    private func signToken(for user: User, req: Request) throws -> String {
        let payload = UserPayload(
            subject: .init(value: try user.requireID().uuidString),
            expiration: .init(value: Date().addingTimeInterval(60 * 60 * 24 * 7))
        )
        return try req.jwt.sign(payload)
    }
}
