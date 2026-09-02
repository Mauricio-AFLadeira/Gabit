import GabitDomain
import XCTest

/// A projection is a promise about the future, so the rules that make it stay
/// silent matter more than the arithmetic that produces it.
final class ProjectionTests: XCTestCase {

    private let calendar = Fixtures.utc

    /// Four weekly readings falling half a kilo a week: 80.0, 79.5, 79.0, 78.5.
    private func losingHalfAKiloPerWeek() -> [WeightCheckIn] {
        Fixtures.checkIns(from: 80, stepKg: -0.5, count: 4, in: calendar)
    }

    func test_projection_returnsNil_whenTrendIsFlatOrWrongDirection() {
        let flat = Fixtures.checkIns(from: 80, stepKg: 0, count: 6, in: calendar)
        XCTAssertNil(projection(from: flat, target: 75, calendar: calendar), "a flat trend reaches nothing")

        let gaining = Fixtures.checkIns(from: 80, stepKg: 0.5, count: 6, in: calendar)
        XCTAssertNil(
            projection(from: gaining, target: 75, calendar: calendar),
            "a rising trend never arrives at a lower target"
        )
    }

    func test_projection_returnsNil_belowTheMinimumNumberOfReadings() {
        let two = Fixtures.checkIns(from: 80, stepKg: -0.5, count: 2, in: calendar)
        XCTAssertEqual(ProjectionRules.minimumReadings, 3)
        XCTAssertNil(projection(from: two, target: 75, calendar: calendar))
    }

    func test_projection_reachesTheTargetOnTheTrendLine() throws {
        // From 78.5 kg down to 75.0 kg at 0.5 kg/week is 3.5 kg, or 49 days.
        let result = try XCTUnwrap(
            projection(from: losingHalfAKiloPerWeek(), target: 75, calendar: calendar)
        )
        XCTAssertEqual(result.daysRemaining, 49)

        let lastReading = Fixtures.date(2026, 7, 5)  // 2026-06-14 plus three weeks
        let expected = try XCTUnwrap(calendar.date(byAdding: .day, value: 49, to: lastReading))
        XCTAssertEqual(result.reachedOn, expected)
    }

    func test_projection_reportsTheObservedWeeklyRate() throws {
        let result = try XCTUnwrap(
            projection(from: losingHalfAKiloPerWeek(), target: 75, calendar: calendar)
        )
        XCTAssertEqual(result.kgPerWeek, -0.5, accuracy: 0.0001)
    }

    func test_projection_countsTheReadingsItWasFittedTo() throws {
        let result = try XCTUnwrap(
            projection(from: losingHalfAKiloPerWeek(), target: 75, calendar: calendar)
        )
        XCTAssertEqual(result.readingCount, 4, "the user is told how much to trust it")
    }

    func test_projection_returnsNil_whenTheTargetIsAlreadyReached() {
        XCTAssertNil(
            projection(from: losingHalfAKiloPerWeek(), target: 78.5, calendar: calendar),
            "there is nothing left to project"
        )
    }

    func test_projection_returnsNil_beyondTheMaximumHorizon() {
        // 0.06 kg/week clears the flat threshold but needs over three years to
        // cover ten kilos — a date that far out invites more trust than it earns.
        let crawling = Fixtures.checkIns(from: 80, stepKg: -0.06, count: 6, in: calendar)
        XCTAssertNil(projection(from: crawling, target: 70, calendar: calendar))
    }

    func test_projection_isUnaffectedByTheOrderReadingsArriveIn() throws {
        let ordered = losingHalfAKiloPerWeek()
        let shuffled = Array(ordered.reversed())

        let fromOrdered = try XCTUnwrap(projection(from: ordered, target: 75, calendar: calendar))
        let fromShuffled = try XCTUnwrap(projection(from: shuffled, target: 75, calendar: calendar))
        XCTAssertEqual(fromOrdered, fromShuffled)
    }

    func test_projection_survivesASingleNoisyReading() throws {
        // One heavy morning must not flip the sign, because the trend is fitted
        // across every reading rather than differenced end to end.
        var readings = Fixtures.checkIns(from: 80, stepKg: -0.5, count: 8, in: calendar)
        readings[7] = WeightCheckIn(weightKg: readings[7].weightKg + 1.2, takenAt: readings[7].takenAt)

        let result = try XCTUnwrap(projection(from: readings, target: 74, calendar: calendar))
        XCTAssertLessThan(result.kgPerWeek, 0, "still losing despite the spike")
    }

    // MARK: - Trailing average

    func test_trailingAverageWeight_averagesOnlyTheWindow() throws {
        let end = Fixtures.date(2026, 9, 6)
        let readings = [
            WeightCheckIn(weightKg: 90, takenAt: Fixtures.date(2026, 8, 1)),
            WeightCheckIn(weightKg: 80, takenAt: Fixtures.date(2026, 9, 2)),
            WeightCheckIn(weightKg: 78, takenAt: Fixtures.date(2026, 9, 5)),
        ]
        let average = try XCTUnwrap(
            trailingAverageWeight(readings, days: 7, endingAt: end, calendar: calendar)
        )
        XCTAssertEqual(average, 79, accuracy: 0.001, "the reading from August is outside the window")
    }

    func test_trailingAverageWeight_returnsNil_whenTheWindowIsEmpty() {
        let readings = [WeightCheckIn(weightKg: 90, takenAt: Fixtures.date(2026, 1, 1))]
        XCTAssertNil(
            trailingAverageWeight(
                readings,
                days: 7,
                endingAt: Fixtures.date(2026, 9, 6),
                calendar: calendar
            )
        )
    }
}
