import XCTest

@testable import MauItKit

final class EnergyMathTests: XCTestCase {
    func testLoseFatSubtractsFromMaintenance() {
        let target = EnergyMath.dailyTarget(maintenance: 2500, direction: .loseFat, ratePerWeek: 0.5)
        XCTAssertEqual(target, 2500 - Int((0.5 * EnergyMath.kcalPerKgFat / 7).rounded()))
    }

    func testBuildMassAddsToMaintenance() {
        let target = EnergyMath.dailyTarget(maintenance: 2500, direction: .buildMass, ratePerWeek: 0.25)
        XCTAssertEqual(target, 2500 + Int((0.25 * EnergyMath.kcalPerKgFat / 7).rounded()))
    }

    func testRecompositionSubtractsLikeLoseFat() {
        let recomposition = EnergyMath.dailyTarget(maintenance: 2200, direction: .recomposition, ratePerWeek: 0.3)
        let loseFat = EnergyMath.dailyTarget(maintenance: 2200, direction: .loseFat, ratePerWeek: 0.3)
        XCTAssertEqual(recomposition, loseFat)
    }

    func testZeroRateReturnsMaintenance() {
        for direction in GoalDirection.allCases {
            let target = EnergyMath.dailyTarget(maintenance: 2000, direction: direction, ratePerWeek: 0)
            XCTAssertEqual(target, 2000, "\(direction) at rate 0 should equal maintenance")
        }
    }
}
