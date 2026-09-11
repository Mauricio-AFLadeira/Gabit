import Fluent
import Foundation

/// A registered account. Only what auth needs — profile fields (goal,
/// targets, ...) belong to their own tables once those screens get a
/// backend, keyed by `$user.id`.
final class User: Model, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @OptionalField(key: "phone")
    var phone: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, name: String, email: String, passwordHash: String, phone: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
        self.phone = phone
    }
}
