import XCTest

import GabitDomain

/// The ledger rules from plan §3, including the one this app exists to get
/// right: burn credits the budget, it does not cancel out food.
final class BalanceTests: XCTestCase {

    private let day = Fixtures.referenceDay
    private let calendar = Fixtures.utc

    private func exampleBudget() -> EnergyBudget {
        dailyTarget(Fixtures.onboardingExampleProfile(), on: day, calendar: calendar)
    }

    func test_balance_creditsBurnWithoutAlteringIntakeTotal() {
        let log = DayLog(
            date: day,
            food: [Fixtures.food("Chicken & rice bowl", 735)],
            burn: [Fixtures.burn("Lifting, 62 min", 240)]
        )
        let result = balance(log, target: exampleBudget())

        XCTAssertEqual(result.intake, 735, accuracy: 0.001, "burn must not be netted off intake")
        XCTAssertEqual(result.burned, 240, accuracy: 0.001)
        XCTAssertEqual(result.allowance, 2180 + 240, accuracy: 0.001)
    }

    func test_balance_remaining_matchesTheTodayScreenWorkedExample() {
        // The design shows eaten 1,625 · burn +240 · target 2,180 → 795 remaining.
        let log = DayLog(
            date: day,
            food: [
                Fixtures.food("Oats, whey, banana", 520, slot: .breakfast),
                Fixtures.food("Chicken & rice bowl", 735, slot: .lunch),
                Fixtures.food("Coffee and snacks", 370, slot: .snack),
            ],
            burn: [Fixtures.burn("Lifting, 62 min", 240)]
        )
        let result = balance(log, target: exampleBudget())

        XCTAssertEqual(result.intake, 1625, accuracy: 0.001)
        XCTAssertEqual(result.remaining, 795, accuracy: 0.001)
        XCTAssertFalse(result.isOverBudget)
    }

    func test_balance_overBudget_matchesTheOverBudgetScreenWorkedExample() {
        // The design shows eaten 2,490 · burn +0 · target 2,180 → 310 over.
        let log = DayLog(
            date: day,
            food: [
                Fixtures.food("Pizza, half", 910, slot: .dinner),
                Fixtures.food("Chicken & rice bowl", 735, slot: .lunch),
                Fixtures.food("The rest of the day", 845, slot: .breakfast),
            ]
        )
        let result = balance(log, target: exampleBudget())

        XCTAssertTrue(result.isOverBudget)
        XCTAssertEqual(result.overBy, 310, accuracy: 0.001)
    }

    func test_balance_isNotOverBudget_whenExactlyOnTarget() {
        let log = DayLog(date: day, food: [Fixtures.food("Exactly the target", 2180)])
        let result = balance(log, target: exampleBudget())

        XCTAssertEqual(result.remaining, 0, accuracy: 0.001)
        XCTAssertFalse(result.isOverBudget, "landing on the target is not over it")
    }

    func test_balance_ofAnEmptyDay_leavesTheWholeTargetRemaining() {
        let result = balance(DayLog(date: day), target: exampleBudget())
        XCTAssertEqual(result.remaining, 2180, accuracy: 0.001)
        XCTAssertEqual(result.consumedFraction, 0, accuracy: 0.001)
    }

    func test_balance_consumedFraction_isClampedToOne_whenOverBudget() {
        let log = DayLog(date: day, food: [Fixtures.food("Far too much", 5000)])
        let result = balance(log, target: exampleBudget())
        XCTAssertEqual(result.consumedFraction, 1, accuracy: 0.001)
    }

    func test_balance_consumedFraction_isZero_whenThereIsNoAllowance() {
        let zero = EnergyBudget(basalRate: 0, maintenance: 0, target: 0)
        let result = balance(DayLog(date: day), target: zero)
        XCTAssertEqual(result.consumedFraction, 0, accuracy: 0.001)
    }

    // MARK: - Day log

    func test_dayLog_macros_sumOnlyTheEntriesThatCarryThem() {
        let log = DayLog(
            date: day,
            food: [
                Fixtures.food("With macros", 500, macros: Macros(proteinG: 40, carbsG: 50, fatG: 10)),
                Fixtures.food("Calories only", 200),
            ]
        )
        XCTAssertEqual(log.macros.proteinG, 40, accuracy: 0.001)
        XCTAssertEqual(log.intake, 700, accuracy: 0.001, "a missing macro breakdown must not drop the calories")
    }

    func test_dayLog_entriesInSlot_areReturnedOldestFirst() {
        let later = Fixtures.food("Later", 100, slot: .lunch, at: Fixtures.date(2026, 9, 6, 14, 0))
        let earlier = Fixtures.food("Earlier", 100, slot: .lunch, at: Fixtures.date(2026, 9, 6, 12, 0))
        let other = Fixtures.food("Breakfast", 100, slot: .breakfast)
        let log = DayLog(date: day, food: [later, earlier, other])

        XCTAssertEqual(log.entries(in: .lunch).map(\.name), ["Earlier", "Later"])
    }

    func test_dayLog_isEmpty_onlyWhenBothLedgersAreEmpty() {
        XCTAssertTrue(DayLog(date: day).isEmpty)
        XCTAssertFalse(DayLog(date: day, burn: [Fixtures.burn("Walk", 100)]).isEmpty)
    }

    // MARK: - Macro targets

    func test_macroTargets_setProteinFromBodyMass_notFromAShareOfEnergy() {
        let profile = Fixtures.profile(weightKg: 80, goal: .cut(rate: .steady))
        let targets = macroTargets(for: exampleBudget(), profile: profile)
        XCTAssertEqual(targets.proteinG, 160, accuracy: 0.001, "2.0 g/kg on a cut")
    }

    func test_macroTargets_onACut_holdProteinHigherThanOnMaintenance() {
        let cutting = macroTargets(
            for: exampleBudget(),
            profile: Fixtures.profile(weightKg: 80, goal: .cut(rate: .steady))
        )
        let maintaining = macroTargets(
            for: exampleBudget(),
            profile: Fixtures.profile(weightKg: 80, goal: .maintain)
        )
        XCTAssertGreaterThan(cutting.proteinG, maintaining.proteinG)
    }

    func test_macroTargets_sumBackToTheEnergyTarget() {
        let budget = exampleBudget()
        let targets = macroTargets(for: budget, profile: Fixtures.profile(weightKg: 80))
        let total = targets.proteinG * 4 + targets.carbsG * 4 + targets.fatG * 9
        XCTAssertEqual(total, budget.target, accuracy: 5, "gram rounding may drift a little, not a lot")
    }
}
