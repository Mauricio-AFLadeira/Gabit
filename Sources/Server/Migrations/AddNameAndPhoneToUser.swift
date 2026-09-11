import Fluent

/// Adds the fields the register screen collects beyond email/password.
/// `name` backfills existing rows with an empty string before going
/// `NOT NULL`; `phone` stays nullable since it's optional in the app.
struct AddNameAndPhoneToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("name", .string, .required, .sql(.default("")))
            .field("phone", .string)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("name")
            .deleteField("phone")
            .update()
    }
}
