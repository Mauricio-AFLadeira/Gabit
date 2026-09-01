#if canImport(SwiftData)

    import Foundation
    import SwiftData

    import GabitDomain

    // Persistence records are separate types from the domain values on purpose.
    // A `@Model` class is a reference type with change tracking attached; letting
    // one of those reach the domain would put SwiftData behind every pure
    // function and end the "no framework imports" rule in §4 on day one.
    //
    // Enums are stored as their raw strings and the goal is split into a kind
    // plus a rate, rather than persisted as opaque encoded data. It costs a few
    // lines in the mapper and buys a store you can inspect and migrate.

    @Model
    public final class ProfileRecord {

        public var sexRaw: String
        public var birthDate: Date
        public var heightCm: Double
        public var weightKg: Double
        public var activityRaw: String
        public var goalKindRaw: String
        public var goalRateKgPerWeek: Double

        public init(
            sexRaw: String,
            birthDate: Date,
            heightCm: Double,
            weightKg: Double,
            activityRaw: String,
            goalKindRaw: String,
            goalRateKgPerWeek: Double
        ) {
            self.sexRaw = sexRaw
            self.birthDate = birthDate
            self.heightCm = heightCm
            self.weightKg = weightKg
            self.activityRaw = activityRaw
            self.goalKindRaw = goalKindRaw
            self.goalRateKgPerWeek = goalRateKgPerWeek
        }
    }

    @Model
    public final class DayLogRecord {

        /// Local midnight of the day this record covers. Unique so a day cannot
        /// end up with two logs after a race or a bad merge.
        @Attribute(.unique) public var date: Date

        @Relationship(deleteRule: .cascade, inverse: \FoodEntryRecord.day)
        public var food: [FoodEntryRecord]

        @Relationship(deleteRule: .cascade, inverse: \BurnEntryRecord.day)
        public var burn: [BurnEntryRecord]

        public init(date: Date, food: [FoodEntryRecord] = [], burn: [BurnEntryRecord] = []) {
            self.date = date
            self.food = food
            self.burn = burn
        }
    }

    @Model
    public final class FoodEntryRecord {

        @Attribute(.unique) public var id: UUID
        public var name: String
        public var kcal: Double
        public var proteinG: Double?
        public var carbsG: Double?
        public var fatG: Double?
        public var slotRaw: String
        public var loggedAt: Date
        public var day: DayLogRecord?

        public init(
            id: UUID,
            name: String,
            kcal: Double,
            proteinG: Double?,
            carbsG: Double?,
            fatG: Double?,
            slotRaw: String,
            loggedAt: Date
        ) {
            self.id = id
            self.name = name
            self.kcal = kcal
            self.proteinG = proteinG
            self.carbsG = carbsG
            self.fatG = fatG
            self.slotRaw = slotRaw
            self.loggedAt = loggedAt
        }
    }

    @Model
    public final class BurnEntryRecord {

        @Attribute(.unique) public var id: UUID
        public var kindRaw: String
        public var name: String
        public var kcal: Double
        public var occurredAt: Date
        public var day: DayLogRecord?

        public init(id: UUID, kindRaw: String, name: String, kcal: Double, occurredAt: Date) {
            self.id = id
            self.kindRaw = kindRaw
            self.name = name
            self.kcal = kcal
            self.occurredAt = occurredAt
        }
    }

    @Model
    public final class WeightCheckInRecord {

        @Attribute(.unique) public var id: UUID
        public var weightKg: Double
        public var takenAt: Date

        public init(id: UUID, weightKg: Double, takenAt: Date) {
            self.id = id
            self.weightKg = weightKg
            self.takenAt = takenAt
        }
    }

    /// Every entity the store persists.
    ///
    /// There is one schema version so far, so there is no migration plan yet —
    /// a `SchemaMigrationPlan` with a single version tests nothing. When V2
    /// lands, this is where it goes, and the round-trip tests below become the
    /// fixture the migration is checked against.
    public enum GabitSchema {

        public static let all: [any PersistentModel.Type] = [
            ProfileRecord.self,
            DayLogRecord.self,
            FoodEntryRecord.self,
            BurnEntryRecord.self,
            WeightCheckInRecord.self,
        ]
    }

#endif
