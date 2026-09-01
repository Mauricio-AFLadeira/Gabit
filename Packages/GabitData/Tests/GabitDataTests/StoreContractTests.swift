import Foundation
import XCTest

import GabitDomain

@testable import GabitData

/// The behaviour every store must show, run against the in-memory one.
///
/// `SwiftDataStoreTests` inherits from this class and swaps in the real store,
/// so the fake cannot quietly drift away from the thing it stands in for —
/// which is the failure mode that makes fakes worthless.
class StoreContractTests: XCTestCase {

    var calendar: Calendar { Calendar.gabitUTC }

    /// Overridden by the SwiftData subclass. Returns nil when the store under
    /// test is unavailable on this platform, which skips the whole case.
    @MainActor
    func makeStore() throws -> (any GabitStore)? {
        InMemoryStore(calendar: calendar)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        guard let date = calendar.date(from: components) else {
            preconditionFailure("bad fixture date")
        }
        return date
    }

    private func profile() -> Profile {
        Profile(
            sex: .female,
            birthDate: date(1992, 4, 3),
            heightCm: 168,
            weightKg: 63.5,
            activity: .light,
            goal: .cut(rate: WeightRate(kgPerWeek: 0.35))
        )
    }

    // MARK: - Profile

    @MainActor
    func test_profile_isNil_beforeOnboardingHasRun() throws {
        guard let store = try makeStore() else { return }
        XCTAssertNil(try store.loadProfile())
    }

    @MainActor
    func test_profile_roundTripsThroughTheStore() throws {
        guard let store = try makeStore() else { return }
        let original = profile()
        try store.save(original)

        let loaded = try XCTUnwrap(try store.loadProfile())
        XCTAssertEqual(loaded, original)
    }

    @MainActor
    func test_profile_isReplacedRatherThanDuplicated_onASecondSave() throws {
        guard let store = try makeStore() else { return }
        try store.save(profile())

        var updated = profile()
        updated.weightKg = 61
        updated.goal = .maintain
        try store.save(updated)

        let loaded = try XCTUnwrap(try store.loadProfile())
        XCTAssertEqual(loaded.weightKg, 61, accuracy: 0.001)
        XCTAssertEqual(loaded.goal, .maintain)
    }

    // MARK: - Day logs

    @MainActor
    func test_log_forAnUntouchedDay_isEmptyRatherThanMissing() throws {
        guard let store = try makeStore() else { return }
        let log = try store.log(on: date(2026, 9, 6))
        XCTAssertTrue(log.isEmpty)
    }

    @MainActor
    func test_food_roundTripsWithItsMacros() throws {
        guard let store = try makeStore() else { return }
        let entry = FoodEntry(
            name: "Chicken & rice bowl",
            kcal: 735,
            macros: Macros(proteinG: 62, carbsG: 60, fatG: 18),
            slot: .lunch,
            loggedAt: date(2026, 9, 6, 13)
        )
        try store.addFood(entry, on: date(2026, 9, 6))

        let log = try store.log(on: date(2026, 9, 6))
        XCTAssertEqual(log.food.count, 1)
        XCTAssertEqual(log.food.first, entry)
    }

    @MainActor
    func test_foodWithoutMacros_roundTripsAsNil_notAsZeroes() throws {
        guard let store = try makeStore() else { return }
        let entry = FoodEntry(
            name: "Coffee, oat milk",
            kcal: 95,
            slot: .breakfast,
            loggedAt: date(2026, 9, 6, 7)
        )
        try store.addFood(entry, on: date(2026, 9, 6))

        let log = try store.log(on: date(2026, 9, 6))
        XCTAssertNil(log.food.first?.macros, "zeroes would read as a logged macro breakdown")
    }

    @MainActor
    func test_burn_roundTripsAndStaysOutOfTheIntakeTotal() throws {
        guard let store = try makeStore() else { return }
        try store.addFood(
            FoodEntry(name: "Lunch", kcal: 700, slot: .lunch, loggedAt: date(2026, 9, 6, 13)),
            on: date(2026, 9, 6)
        )
        try store.addBurn(
            BurnEntry(kind: .workout, name: "Lifting", kcal: 240, occurredAt: date(2026, 9, 6, 18)),
            on: date(2026, 9, 6)
        )

        let log = try store.log(on: date(2026, 9, 6))
        XCTAssertEqual(log.intake, 700, accuracy: 0.001)
        XCTAssertEqual(log.burned, 240, accuracy: 0.001)
    }

    @MainActor
    func test_entriesAreAddressedByAnyInstantWithinTheDay() throws {
        guard let store = try makeStore() else { return }
        try store.addFood(
            FoodEntry(name: "Breakfast", kcal: 400, slot: .breakfast, loggedAt: date(2026, 9, 6, 8)),
            on: date(2026, 9, 6, 8)
        )

        // Asked for with a different instant on the same day.
        let log = try store.log(on: date(2026, 9, 6, 21))
        XCTAssertEqual(log.food.count, 1, "the store normalises to local midnight so callers need not")
    }

    @MainActor
    func test_removeFood_deletesTheEntry() throws {
        guard let store = try makeStore() else { return }
        let entry = FoodEntry(name: "Mistake", kcal: 400, slot: .snack, loggedAt: date(2026, 9, 6))
        try store.addFood(entry, on: date(2026, 9, 6))
        try store.removeFood(id: entry.id, on: date(2026, 9, 6))

        XCTAssertTrue(try store.log(on: date(2026, 9, 6)).food.isEmpty)
    }

    @MainActor
    func test_removeFood_reportsAnUnknownEntry() throws {
        guard let store = try makeStore() else { return }
        let missing = UUID()
        XCTAssertThrowsError(try store.removeFood(id: missing, on: date(2026, 9, 6))) { error in
            XCTAssertEqual(error as? StoreError, .entryNotFound(missing))
        }
    }

    @MainActor
    func test_removeBurn_deletesTheEntry() throws {
        guard let store = try makeStore() else { return }
        let entry = BurnEntry(kind: .steps, name: "Walk", kcal: 120, occurredAt: date(2026, 9, 6))
        try store.addBurn(entry, on: date(2026, 9, 6))
        try store.removeBurn(id: entry.id, on: date(2026, 9, 6))

        XCTAssertTrue(try store.log(on: date(2026, 9, 6)).burn.isEmpty)
    }

    @MainActor
    func test_logsInRange_areReturnedOldestFirst_andExcludeTheOutside() throws {
        guard let store = try makeStore() else { return }
        for day in [3, 5, 6, 12] {
            try store.addFood(
                FoodEntry(
                    name: "Day \(day)",
                    kcal: 100,
                    slot: .lunch,
                    loggedAt: date(2026, 9, day)
                ),
                on: date(2026, 9, day)
            )
        }

        let range = try store.logs(from: date(2026, 9, 4), to: date(2026, 9, 6))
        XCTAssertEqual(range.count, 2)
        XCTAssertEqual(range.map { calendar.component(.day, from: $0.date) }, [5, 6])
    }

    @MainActor
    func test_entriesOnDifferentDays_doNotLeakIntoEachOther() throws {
        guard let store = try makeStore() else { return }
        try store.addFood(
            FoodEntry(name: "Yesterday", kcal: 500, slot: .lunch, loggedAt: date(2026, 9, 5)),
            on: date(2026, 9, 5)
        )
        try store.addFood(
            FoodEntry(name: "Today", kcal: 600, slot: .lunch, loggedAt: date(2026, 9, 6)),
            on: date(2026, 9, 6)
        )

        XCTAssertEqual(try store.log(on: date(2026, 9, 6)).intake, 600, accuracy: 0.001)
        XCTAssertEqual(try store.log(on: date(2026, 9, 5)).intake, 500, accuracy: 0.001)
    }

    // MARK: - Check-ins

    @MainActor
    func test_checkIns_roundTripAndAreOrderedOldestFirst() throws {
        guard let store = try makeStore() else { return }
        try store.add(WeightCheckIn(weightKg: 79, takenAt: date(2026, 9, 5)))
        try store.add(WeightCheckIn(weightKg: 80, takenAt: date(2026, 8, 29)))

        let readings = try store.checkIns()
        XCTAssertEqual(readings.map(\.weightKg), [80, 79])
    }

    @MainActor
    func test_removeCheckIn_reportsAnUnknownReading() throws {
        guard let store = try makeStore() else { return }
        let missing = UUID()
        XCTAssertThrowsError(try store.remove(id: missing)) { error in
            XCTAssertEqual(error as? StoreError, .entryNotFound(missing))
        }
    }

    @MainActor
    func test_removeCheckIn_deletesTheReading() throws {
        guard let store = try makeStore() else { return }
        let reading = WeightCheckIn(weightKg: 78.4, takenAt: date(2026, 9, 6))
        try store.add(reading)
        try store.remove(id: reading.id)

        XCTAssertTrue(try store.checkIns().isEmpty)
    }
}
