import JWT
import Vapor

/// The claims signed into the bearer token handed back by `/auth/register`
/// and `/auth/login` — just enough to look the user back up per request.
struct UserPayload: JWTPayload, Authenticatable {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
    }

    var subject: SubjectClaim
    var expiration: ExpirationClaim

    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}

/// Reads the `Authorization: Bearer <token>` header, verifies the JWT
/// signature, and logs the resulting payload into `req.auth` for
/// `req.auth.require(UserPayload.self)` (or `UserPayload.guardMiddleware()`)
/// to pick up downstream.
struct UserPayloadAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        let payload = try request.jwt.verify(bearer.token, as: UserPayload.self)
        request.auth.login(payload)
    }
}
