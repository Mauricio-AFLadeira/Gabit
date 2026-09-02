import GabitDomain
import XCTest

/// The operation the two-tap claim in plan §8 rests on.
final class RepeatTests: XCTestCase {

    private let calendar = Fixtures.utc

    private func yesterday() -> DayLog {
        DayLog(
            date: Fixtures.date(2026, 9, 5),
            food: [
                Fixtures.food(
                    "Oats, whey, banana",
                    520,
                    slot: .breakfast,
                    macros: Macros(proteinG: 42, carbsG: 68, fatG: 9),
                    at: Fixtures.date(2026, 9, 5, 8, 15)
                ),
                Fixtures.food(
                    "Chicken & rice bowl",
                    735,
                    slot: .lunch,
                    at: Fixtures.date(2026, 9, 5, 13, 40)
                ),
            ]
        )
    }

    func test_repeatLastMeal_copiesEntries_intoTodaysSlot() {
        let copies = RepeatMeal.copy(
            yesterday().food,
            onto: Fixtures.date(2026, 9, 6),
            in: calendar
        )

        XCTAssertEqual(copies.map(\.slot), [.breakfast, .lunch])
        XCTAssertEqual(copies.map(\.name), ["Oats, whey, banana", "Chicken & rice bowl"])
        for copy in copies {
            XCTAssertTrue(
                DayBoundary.isSameDay(copy.loggedAt, Fixtures.date(2026, 9, 6), in: calendar),
                "the copy belongs to today"
            )
        }
    }

    func test_repeatLastMeal_givesEachCopyAFreshIdentity() {
        let source = yesterday().food
        let copies = RepeatMeal.copy(source, onto: Fixtures.date(2026, 9, 6), in: calendar)

        let originalIDs = Set(source.map(\.id))
        let copyIDs = Set(copies.map(\.id))
        XCTAssertTrue(
            originalIDs.isDisjoint(with: copyIDs),
            "sharing ids would make deleting today's breakfast delete yesterday's"
        )
        XCTAssertEqual(copyIDs.count, copies.count, "and the copies are distinct from each other")
    }

    func test_repeatLastMeal_preservesTimeOfDayAndMacros() throws {
        let copies = RepeatMeal.copy(
            yesterday().food,
            onto: Fixtures.date(2026, 9, 6),
            in: calendar
        )
        let breakfast = try XCTUnwrap(copies.first)

        let time = calendar.dateComponents([.hour, .minute], from: breakfast.loggedAt)
        XCTAssertEqual(time.hour, 8)
        XCTAssertEqual(time.minute, 15)
        XCTAssertEqual(breakfast.macros?.proteinG, 42)
        XCTAssertEqual(breakfast.kcal, 520, accuracy: 0.001)
    }

    func test_repeatLastMeal_ofAnEmptyDay_copiesNothing() {
        XCTAssertTrue(RepeatMeal.copy([], onto: Fixtures.referenceDay, in: calendar).isEmpty)
    }

    // MARK: - Recent suggestions

    func test_recent_deduplicatesByName_keepingTheNewest() {
        let logs = [
            DayLog(
                date: Fixtures.date(2026, 9, 5),
                food: [
                    Fixtures.food("Coffee, oat milk", 95, at: Fixtures.date(2026, 9, 5, 7, 0)),
                    Fixtures.food("Eggs ×3", 215, at: Fixtures.date(2026, 9, 5, 9, 0)),
                ]
            ),
            DayLog(
                date: Fixtures.date(2026, 9, 6),
                food: [Fixtures.food("coffee, oat milk", 95, at: Fixtures.date(2026, 9, 6, 7, 0))]
            ),
        ]

        let recent = RepeatMeal.recent(from: logs, limit: 4)
        XCTAssertEqual(recent.count, 2, "the same food twice is one suggestion")
        XCTAssertEqual(recent.first?.name, "coffee, oat milk", "newest first")
    }

    func test_recent_respectsTheLimit() {
        let log = DayLog(
            date: Fixtures.referenceDay,
            food: (0..<10).map { index in
                Fixtures.food(
                    "Food \(index)",
                    100,
                    at: Fixtures.date(2026, 9, 6, 8, index)
                )
            }
        )
        XCTAssertEqual(RepeatMeal.recent(from: [log], limit: 4).count, 4)
    }

    func test_recent_ofNoHistory_isEmpty() {
        XCTAssertTrue(RepeatMeal.recent(from: [], limit: 4).isEmpty)
    }
}
