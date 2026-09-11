import Fluent
import Foundation
import XCTVapor

@testable import Server

/// Runs the real `configure(_:)` against a dedicated `mauit_test` database
/// (see `docker/postgres-init/`) rather than mocking Fluent — the point of
/// these tests is to catch schema/query mistakes a mock would paper over.
///
/// One `Application` is built and migrated once for the whole class and
/// reused by every test (XCTest otherwise gives each test method its own
/// instance): tearing a Vapor `Application` down and spinning up a fresh one
/// per test repeatedly churns the Postgres connection pool, which is prone
/// to hanging on Linux. Tests stay isolated by using a unique email per test
/// rather than by resetting the schema between tests — read the row you
/// just wrote, don't assume the table starts empty. The one exception is
/// the `users` table itself: it's wiped once, right after migrating, so
/// leftover rows from a previous `swift test` run (the schema is never
/// reverted between process runs — see above) can't cause a spurious
/// duplicate-email conflict here.
final class AuthControllerTests: XCTestCase {
    // XCTest runs this class's tests serially (no concurrent test execution
    // configured), so setUp always finishes writing this before the next
    // test's setUp reads it — safe despite the annotation being required.
    nonisolated(unsafe) private static var sharedApp: Application?

    var app: Application!

    override func setUp() async throws {
        if let sharedApp = Self.sharedApp {
            app = sharedApp
            return
        }

        setenv("DATABASE_NAME", ProcessInfo.processInfo.environment["DATABASE_TEST_NAME"] ?? "mauit_test", 1)

        let newApp = try await Application.make(.testing)
        try await configure(newApp)
        try await newApp.autoMigrate()
        try await User.query(on: newApp.db).delete()
        Self.sharedApp = newApp
        app = newApp
    }

    func testRegisterCreatesUserAndReturnsToken() async throws {
        try await app.testable().test(
            .POST, "auth/register",
            beforeRequest: { req in
                try req.content.encode(
                    RegisterRequest(
                        name: "Ada Lovelace", email: "ada@example.com", password: "supersecret1", phone: nil))
            },
            afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let body = try res.content.decode(AuthResponse.self)
                XCTAssertEqual(body.user.name, "Ada Lovelace")
                XCTAssertEqual(body.user.email, "ada@example.com")
                XCTAssertNil(body.user.phone)
                XCTAssertFalse(body.token.isEmpty)
            }
        )
    }

    func testRegisterStoresLowercasedEmailAndOptionalPhone() async throws {
        try await app.testable().test(
            .POST, "auth/register",
            beforeRequest: { req in
                try req.content.encode(
                    RegisterRequest(
                        name: "Grace Hopper", email: "Grace@Example.com", password: "supersecret1",
                        phone: "+15550001234"))
            },
            afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let body = try res.content.decode(AuthResponse.self)
                XCTAssertEqual(body.user.email, "grace@example.com")
                XCTAssertEqual(body.user.phone, "+15550001234")
            }
        )
    }

    func testRegisterRejectsShortPassword() async throws {
        try await app.testable().test(
            .POST, "auth/register",
            beforeRequest: { req in
                try req.content.encode(
                    RegisterRequest(name: "Short Pass", email: "short@example.com", password: "short", phone: nil))
            },
            afterResponse: { res async throws in
                XCTAssertEqual(res.status, .badRequest)
            }
        )
    }

    func testRegisterRejectsDuplicateEmail() async throws {
        try await registerUser(email: "dup@example.com", password: "supersecret1")

        try await app.testable().test(
            .POST, "auth/register",
            beforeRequest: { req in
                try req.content.encode(
                    RegisterRequest(
                        name: "Someone Else", email: "dup@example.com", password: "supersecret2", phone: nil))
            },
            afterResponse: { res async throws in
                XCTAssertEqual(res.status, .conflict)
            }
        )
    }

    func testLoginWithCorrectCredentialsSucceeds() async throws {
        try await registerUser(email: "login@example.com", password: "supersecret1")

        try await app.testable().test(
            .POST, "auth/login",
            beforeRequest: { req in
                try req.content.encode(LoginRequest(email: "login@example.com", password: "supersecret1"))
            },
            afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let body = try res.content.decode(AuthResponse.self)
                XCTAssertEqual(body.user.email, "login@example.com")
            }
        )
    }

    func testLoginWithWrongPasswordFails() async throws {
        try await registerUser(email: "wrongpass@example.com", password: "supersecret1")

        try await app.testable().test(
            .POST, "auth/login",
            beforeRequest: { req in
                try req.content.encode(LoginRequest(email: "wrongpass@example.com", password: "notTheRightOne"))
            },
            afterResponse: { res async throws in
                XCTAssertEqual(res.status, .unauthorized)
            }
        )
    }

    func testLoginWithUnknownEmailFails() async throws {
        try await app.testable().test(
            .POST, "auth/login",
            beforeRequest: { req in
                try req.content.encode(LoginRequest(email: "nobody@example.com", password: "whatever1"))
            },
            afterResponse: { res async throws in
                XCTAssertEqual(res.status, .unauthorized)
            }
        )
    }

    func testMeReturnsUserForValidToken() async throws {
        let token = try await registerUser(email: "me@example.com", password: "supersecret1")

        try await app.testable().test(
            .GET, "auth/me",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            },
            afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                let user = try res.content.decode(UserResponse.self)
                XCTAssertEqual(user.email, "me@example.com")
            }
        )
    }

    func testMeRejectsMissingToken() async throws {
        try await app.testable().test(
            .GET, "auth/me",
            afterResponse: { res async throws in
                XCTAssertEqual(res.status, .unauthorized)
            }
        )
    }

    func testMeRejectsGarbageToken() async throws {
        try await app.testable().test(
            .GET, "auth/me",
            beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: "not-a-real-token")
            },
            afterResponse: { res async throws in
                XCTAssertEqual(res.status, .unauthorized)
            }
        )
    }

    @discardableResult
    private func registerUser(email: String, password: String) async throws -> String {
        var token = ""
        try await app.testable().test(
            .POST, "auth/register",
            beforeRequest: { req in
                try req.content.encode(RegisterRequest(name: "Test User", email: email, password: password, phone: nil))
            },
            afterResponse: { res async throws in
                XCTAssertEqual(res.status, .ok)
                token = try res.content.decode(AuthResponse.self).token
            }
        )
        return token
    }
}
