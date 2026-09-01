import XCTest

import GabitDomain

/// The three figures on the Progress screen.
final class AdherenceTests: XCTestCase {

    private let calendar = Fixtures.utc

    private func budget() -> EnergyBudget {
        dailyTarget(
            Fixtures.onboardingExampleProfile(),
            on: Fixtures.referenceDay,
            calendar: calendar
        )
    }

    private func day(_ dayOfMonth: Int, eating kcal: Kcal) -> DayLog {
        DayLog(
            date: Fixtures.date(2026, 9, dayOfMonth),
            food: [Fixtures.food("Whatever", kcal, at: Fixtures.date(2026, 9, dayOfMonth, 12, 0))]
        )
    }

    func test_adherence_ignoresDaysWithNothingLogged() {
        let logs = [
            day(1, eating: 2000),
            DayLog(date: Fixtures.date(2026, 9, 2)),
            day(3, eating: 2000),
        ]
        let result = adherence(over: logs, target: budget())

        XCTAssertEqual(
            result.daysLogged,
            2,
            "an unlogged day is missing data, not a perfect zero-calorie day"
        )
    }

    func test_adherence_countsTheDaysThatStayedWithinTarget() {
        let logs = [day(1, eating: 2000), day(2, eating: 2100), day(3, eating: 2500)]
        let result = adherence(over: logs, target: budget())

        XCTAssertEqual(result.daysLogged, 3)
        XCTAssertEqual(result.daysWithinTarget, 2)
        XCTAssertEqual(result.withinTargetFraction, 2.0 / 3.0, accuracy: 0.0001)
    }

    func test_adherence_averageBalance_isNegativeWhileInDeficit() {
        // Target 2,180; eating 1,980 every day is 200 under.
        let logs = (1...4).map { day($0, eating: 1980) }
        let result = adherence(over: logs, target: budget())

        XCTAssertEqual(result.averageBalance, -200, accuracy: 0.001)
    }

    func test_adherence_ofNothingLogged_isTheEmptySummary() {
        let result = adherence(over: [], target: budget())
        XCTAssertEqual(result, .none)
        XCTAssertEqual(result.withinTargetFraction, 0, accuracy: 0.001)
    }

    func test_adherence_countsADayThatLandsExactlyOnTargetAsWithinIt() {
        let logs = [day(1, eating: 2180)]
        XCTAssertEqual(adherence(over: logs, target: budget()).daysWithinTarget, 1)
    }
}
