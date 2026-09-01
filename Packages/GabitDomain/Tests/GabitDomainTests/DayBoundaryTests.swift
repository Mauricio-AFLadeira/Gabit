import XCTest

import GabitDomain

/// Time zones, which is where trackers like this one quietly go wrong.
final class DayBoundaryTests: XCTestCase {

    func test_dayLog_rollsOverAtLocalMidnight_notUTC() {
        // 02:00 UTC on the 6th is 23:00 on the 5th in São Paulo. A meal logged
        // then belongs to the 5th — the day the user was actually living in.
        let lateEvening = Fixtures.date(2026, 9, 6, 2, 0, in: Fixtures.utc)

        let localStart = DayBoundary.startOfDay(for: lateEvening, in: Fixtures.saoPaulo)
        let utcStart = DayBoundary.startOfDay(for: lateEvening, in: Fixtures.utc)

        XCTAssertNotEqual(localStart, utcStart, "the two calendars must not agree here")

        let fifthLocally = Fixtures.date(2026, 9, 5, 20, 0, in: Fixtures.saoPaulo)
        XCTAssertTrue(
            DayBoundary.isSameDay(lateEvening, fifthLocally, in: Fixtures.saoPaulo),
            "still the 5th for the user"
        )
        XCTAssertFalse(
            DayBoundary.isSameDay(lateEvening, fifthLocally, in: Fixtures.utc),
            "already the 6th in UTC — which is exactly the bug"
        )
    }

    func test_dayBoundary_startOfDay_isMidnightInTheGivenZone() {
        let noon = Fixtures.date(2026, 9, 6, 12, 0, in: Fixtures.saoPaulo)
        let start = DayBoundary.startOfDay(for: noon, in: Fixtures.saoPaulo)

        let components = Fixtures.saoPaulo.dateComponents([.hour, .minute, .day], from: start)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.day, 6)
    }

    func test_dayBoundary_offsetByDays_walksLocalMidnights() {
        let day = Fixtures.date(2026, 9, 6, 15, 30, in: Fixtures.utc)
        let sixDaysBack = DayBoundary.startOfDay(offsetBy: -6, from: day, in: Fixtures.utc)
        XCTAssertEqual(sixDaysBack, Fixtures.date(2026, 8, 31, in: Fixtures.utc))
    }

    func test_dayBoundary_offsetByDays_crossesAMonthBoundary() {
        let day = Fixtures.date(2026, 3, 2, in: Fixtures.utc)
        let threeBack = DayBoundary.startOfDay(offsetBy: -3, from: day, in: Fixtures.utc)
        XCTAssertEqual(threeBack, Fixtures.date(2026, 2, 27, in: Fixtures.utc))
    }

    func test_fixedClock_doesNotMoveBetweenReads() {
        let clock = FixedClock(now: Fixtures.referenceDay)
        XCTAssertEqual(clock.now, clock.now)
        XCTAssertEqual(clock.now, Fixtures.referenceDay)
    }
}
