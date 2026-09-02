import GabitData
import GabitDomain
import XCTest

@testable import GabitUI

@MainActor
final class ProgressViewModelTests: XCTestCase {

    private func makeModel(
        checkIns: [WeightCheckIn] = [],
        logs: [DayLog] = [],
        profile: Profile? = UIFixtures.profile()
    ) -> (ProgressViewModel, InMemoryStore) {
        let store = UIFixtures.store(profile: profile, logs: logs, checkIns: checkIns)
        let model = ProgressViewModel(
            store: store,
            clock: UIFixtures.clock(),
            formatting: UIFixtures.formatting()
        )
        return (model, store)
    }

    /// Weekly readings ending the day before "now", falling at a steady rate.
    private func steadyLoss(count: Int = 12, stepKg: Double = -0.5) -> [WeightCheckIn] {
        (0..<count).map { index in
            let daysBack = (count - 1 - index) * 7
            let takenAt =
                UIFixtures.calendar.date(
                    byAdding: .day,
                    value: -daysBack,
                    to: UIFixtures.now
                ) ?? UIFixtures.now
            return WeightCheckIn(
                weightKg: 82 + stepKg * Double(index),
                takenAt: takenAt
            )
        }
    }

    func test_currentWeight_isTheSevenDayAverage_notTheLastReading() {
        let readings = [
            WeightCheckIn(weightKg: 78.0, takenAt: UIFixtures.date(2026, 9, 2)),
            WeightCheckIn(weightKg: 80.0, takenAt: UIFixtures.date(2026, 9, 6, 7)),
        ]
        let (model, _) = makeModel(checkIns: readings)
        model.refresh()

        XCTAssertEqual(model.currentWeight, "79.0", "a heavy morning is mostly water")
    }

    func test_projection_isStatedWithTheEvidenceBehindIt() throws {
        let (model, _) = makeModel(checkIns: steadyLoss())
        model.refresh()

        let headline = try XCTUnwrap(model.projectionHeadline)
        XCTAssertTrue(headline.contains("you reach"), "got \(headline)")
        XCTAssertTrue(headline.contains("weeks out"), "got \(headline)")

        let footnote = try XCTUnwrap(model.projectionFootnote)
        XCTAssertTrue(footnote.contains("Based on 12 readings"), "got \(footnote)")
    }

    func test_projection_disappearsWhenTheTrendFlattens() {
        let (model, _) = makeModel(checkIns: steadyLoss(stepKg: 0))
        model.refresh()

        XCTAssertNil(model.projectionHeadline)
        XCTAssertNil(model.projectionFootnote, "the footnote must not survive its headline")
    }

    func test_projection_isAbsentWithoutAProfile() {
        let (model, _) = makeModel(checkIns: steadyLoss(), profile: nil)
        model.refresh()
        XCTAssertNil(model.projectionHeadline)
    }

    func test_projection_isAbsentWhenMaintaining() {
        var profile = UIFixtures.profile()
        profile.goal = .maintain
        let (model, _) = makeModel(checkIns: steadyLoss(), profile: profile)
        model.refresh()

        XCTAssertNil(model.projectionHeadline, "maintaining is not heading anywhere")
    }

    func test_changeSummary_reportsTheDeltaAcrossTheVisibleRange() {
        let (model, _) = makeModel(checkIns: steadyLoss())
        model.range = .twelveWeeks

        XCTAssertTrue(model.changeSummary.contains("12 w"), "got \(model.changeSummary)")
        XCTAssertTrue(model.changeSummary.hasPrefix("−"), "losing weight reads as negative")
    }

    func test_changeSummary_saysSoWhenThereIsNotEnoughData() {
        let (model, _) = makeModel()
        model.refresh()
        XCTAssertEqual(model.changeSummary, "not enough readings yet")
    }

    func test_changingRangeRefreshesTheChart() {
        let (model, _) = makeModel(checkIns: steadyLoss(count: 40))
        model.range = .oneYear
        let yearPoints = model.points.count

        model.range = .fourWeeks
        XCTAssertLessThan(model.points.count, yearPoints, "a shorter window plots fewer readings")
    }

    func test_points_areNormalisedIntoTheUnitSquare() {
        let (model, _) = makeModel(checkIns: steadyLoss())
        model.refresh()

        XCTAssertFalse(model.points.isEmpty)
        for point in model.points {
            XCTAssertTrue((0...1).contains(point.x), "x out of range: \(point.x)")
            XCTAssertTrue((0...1).contains(point.y), "y out of range: \(point.y)")
        }
    }

    func test_aFlatRunDoesNotCollapseTheChartOntoOneEdge() {
        let (model, _) = makeModel(checkIns: steadyLoss(stepKg: 0))
        model.refresh()

        for point in model.points {
            XCTAssertTrue((0...1).contains(point.y))
        }
    }

    func test_chartIsEmptyBelowTwoReadings() {
        let single = [WeightCheckIn(weightKg: 80, takenAt: UIFixtures.date(2026, 9, 5))]
        let (model, _) = makeModel(checkIns: single)
        model.refresh()

        XCTAssertTrue(model.points.isEmpty)
        XCTAssertTrue(model.axisLabels.isEmpty)
    }

    func test_adherenceStats_summariseTheVisibleRange() {
        let logs = (1...5).map { day in
            DayLog(
                date: UIFixtures.date(2026, 9, day),
                food: [UIFixtures.food("Steady", 1700, at: UIFixtures.date(2026, 9, day, 12))]
            )
        }
        let (model, _) = makeModel(logs: logs)
        model.refresh()

        XCTAssertEqual(model.stats.map(\.id), ["logged", "within", "balance"])
        XCTAssertEqual(model.stats[0].value, "5")
        XCTAssertEqual(model.stats[1].value, "100%")
        XCTAssertEqual(model.stats[2].value, "−480")
    }

    func test_addCheckIn_storesTheReadingAndRefreshes() throws {
        let (model, store) = makeModel(checkIns: steadyLoss())
        model.refresh()

        model.addCheckIn(weightKg: 76.2)

        let readings = try store.checkIns()
        XCTAssertEqual(readings.last?.weightKg, 76.2)
        XCTAssertTrue(model.hasReadings)
    }

    func test_withoutReadings_theScreenSaysSoRatherThanShowingZero() {
        let (model, _) = makeModel()
        model.refresh()

        XCTAssertFalse(model.hasReadings)
        XCTAssertEqual(model.currentWeight, "—")
    }
}
