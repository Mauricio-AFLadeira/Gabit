#if canImport(SwiftData)

    import Foundation
    import SwiftData
    import XCTest

    import GabitDomain

    @testable import GabitData

    /// Runs the whole store contract against the real SwiftData implementation.
    ///
    /// Inheriting the cases rather than restating them is the point: the fake the
    /// view-model tests trust and the store the app ships are held to one set of
    /// expectations, so they cannot drift apart.
    final class SwiftDataStoreTests: StoreContractTests {

        override func makeStore() throws -> (any GabitStore)? {
            let container = try SwiftDataStore.makeContainer(inMemory: true)
            return SwiftDataStore(context: ModelContext(container), calendar: calendar)
        }

        func test_secondEntryOnADay_reusesTheSameDayRecord() throws {
            let container = try SwiftDataStore.makeContainer(inMemory: true)
            let context = ModelContext(container)
            let store = SwiftDataStore(context: context, calendar: calendar)

            var components = DateComponents()
            components.year = 2026
            components.month = 9
            components.day = 6
            let day = try XCTUnwrap(calendar.date(from: components))

            try store.addFood(
                FoodEntry(name: "Breakfast", kcal: 400, slot: .breakfast, loggedAt: day),
                on: day
            )
            try store.addFood(
                FoodEntry(name: "Lunch", kcal: 700, slot: .lunch, loggedAt: day),
                on: day
            )

            let records = try context.fetch(FetchDescriptor<DayLogRecord>())
            XCTAssertEqual(records.count, 1, "a day must not end up with two log records")
            XCTAssertEqual(records.first?.food.count, 2)
        }

        func test_deletingADayRecord_cascadesToItsEntries() throws {
            let container = try SwiftDataStore.makeContainer(inMemory: true)
            let context = ModelContext(container)
            let store = SwiftDataStore(context: context, calendar: calendar)

            var components = DateComponents()
            components.year = 2026
            components.month = 9
            components.day = 6
            let day = try XCTUnwrap(calendar.date(from: components))

            try store.addFood(
                FoodEntry(name: "Breakfast", kcal: 400, slot: .breakfast, loggedAt: day),
                on: day
            )

            let record = try XCTUnwrap(try context.fetch(FetchDescriptor<DayLogRecord>()).first)
            context.delete(record)
            try context.save()

            let orphans = try context.fetch(FetchDescriptor<FoodEntryRecord>())
            XCTAssertTrue(orphans.isEmpty, "cascade delete must not leave orphaned entries")
        }
    }

    /// The mapper's fallbacks, which the contract tests never reach because they
    /// only ever write values this build already understands.
    final class MappingTests: XCTestCase {

        func test_unknownSexOrActivity_fallsBackRatherThanRefusingToLaunch() {
            let record = ProfileRecord(
                sexRaw: "something-newer",
                birthDate: Date(timeIntervalSince1970: 0),
                heightCm: 170,
                weightKg: 70,
                activityRaw: "hyperactive",
                goalKindRaw: "cut",
                goalRateKgPerWeek: 0.5
            )

            let profile = record.domainValue
            XCTAssertEqual(profile.activity, .moderate)
            XCTAssertEqual(profile.goal, .cut(rate: WeightRate(kgPerWeek: 0.5)))
        }

        func test_unknownGoalKind_readsAsMaintain() {
            let record = ProfileRecord(
                sexRaw: "female",
                birthDate: Date(timeIntervalSince1970: 0),
                heightCm: 170,
                weightKg: 70,
                activityRaw: "light",
                goalKindRaw: "recomposition",
                goalRateKgPerWeek: 0.2
            )
            XCTAssertEqual(record.domainValue.goal, .maintain)
        }

        func test_goalRoundTripsThroughItsKindAndRate() {
            let profile = Profile(
                sex: .male,
                birthDate: Date(timeIntervalSince1970: 0),
                heightCm: 180,
                weightKg: 80,
                activity: .high,
                goal: .bulk(rate: WeightRate(kgPerWeek: 0.25))
            )
            XCTAssertEqual(ProfileRecord(profile).domainValue, profile)
        }

        func test_partialMacros_readBackAsNil() {
            let record = FoodEntryRecord(
                id: UUID(),
                name: "Half-remembered",
                kcal: 300,
                proteinG: 20,
                carbsG: nil,
                fatG: 5,
                slotRaw: "lunch",
                loggedAt: Date(timeIntervalSince1970: 0)
            )
            XCTAssertNil(record.domainValue.macros, "a partial breakdown is not a breakdown")
        }

        func test_unknownMealSlot_readsAsSnack() {
            let record = FoodEntryRecord(
                id: UUID(),
                name: "Second lunch",
                kcal: 300,
                proteinG: nil,
                carbsG: nil,
                fatG: nil,
                slotRaw: "brunch",
                loggedAt: Date(timeIntervalSince1970: 0)
            )
            XCTAssertEqual(record.domainValue.slot, .snack)
        }
    }

#endif
