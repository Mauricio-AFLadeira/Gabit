import Foundation
import XCTest

@testable import MauItKit

final class DayLogTests: XCTestCase {
    private func makeDay(target: Int, eaten: Int, burn: Int = 0) -> DayLog {
        DayLog(
            date: Date(),
            targetCalories: target,
            eatenCalories: eaten,
            burnCalories: burn,
            proteinGrams: 0,
            proteinTarget: 0,
            carbsGrams: 0,
            carbsTarget: 0,
            fatGrams: 0,
            fatTarget: 0,
            entries: []
        )
    }

    func testUnderBudgetIsNotOverBudget() {
        let day = makeDay(target: 2000, eaten: 1500)
        XCTAssertEqual(day.remainingCalories, 500)
        XCTAssertFalse(day.isOverBudget)
    }

    func testEatingPastTargetIsOverBudget() {
        let day = makeDay(target: 2000, eaten: 2200)
        XCTAssertEqual(day.remainingCalories, -200)
        XCTAssertTrue(day.isOverBudget)
    }

    func testBurnCreditsBackIntoBudget() {
        let day = makeDay(target: 2000, eaten: 2200, burn: 300)
        XCTAssertEqual(day.remainingCalories, 100)
        XCTAssertFalse(day.isOverBudget)
    }

    func testConsumedFractionIsClampedToOne() {
        let day = makeDay(target: 1000, eaten: 5000)
        XCTAssertEqual(day.consumedFraction, 1)
    }

    func testConsumedFractionIsClampedToZero() {
        let day = makeDay(target: 1000, eaten: 0, burn: 500)
        XCTAssertEqual(day.consumedFraction, 0)
    }
}
