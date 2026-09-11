import Fluent
import FluentPostgresDriver
import JWT
import Vapor

/// Wires up the database connection, migrations and JWT signer, then hands
/// off to `routes(_:)`. Every value is read from the environment so the same
/// binary runs unchanged in the compose `db` service and in any other
/// deployment target — see `.env.example` for the variables it expects.
func configure(_ app: Application) async throws {
    let dbConfig = SQLPostgresConfiguration(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "mauit",
        password: Environment.get("DATABASE_PASSWORD") ?? "mauit",
        database: Environment.get("DATABASE_NAME") ?? "mauit",
        tls: .disable
    )
    app.databases.use(.postgres(configuration: dbConfig), as: .psql)

    app.migrations.add(CreateUser())
    app.migrations.add(AddNameAndPhoneToUser())

    let jwtSecret = Environment.get("JWT_SECRET") ?? "insecure-dev-secret-change-me"
    app.jwt.signers.use(.hs256(key: jwtSecret))

    if Environment.get("AUTO_MIGRATE").flatMap(Bool.init) ?? false {
        try await app.autoMigrate()
    }

    try routes(app)
}
