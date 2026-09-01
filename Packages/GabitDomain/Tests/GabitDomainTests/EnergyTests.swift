import XCTest

import GabitDomain

/// Every rule in plan §3 that concerns the energy math. Names state the rule,
/// not the method call, so a reviewer can audit coverage by reading them.
final class EnergyTests: XCTestCase {

    private let day = Fixtures.referenceDay
    private let calendar = Fixtures.utc

    // MARK: - Basal rate

    func test_basalRate_forAMaleProfile_matchesMifflinStJeor() {
        // 10 × 80 + 6.25 × 180 − 5 × 36 + 5
        let rate = basalRate(Fixtures.profile(), on: day, calendar: calendar)
        XCTAssertEqual(rate, 1750, accuracy: 0.001)
    }

    func test_basalRate_forAFemaleProfile_appliesTheMinus161Offset() {
        let male = basalRate(Fixtures.profile(sex: .male), on: day, calendar: calendar)
        let female = basalRate(Fixtures.profile(sex: .female), on: day, calendar: calendar)
        XCTAssertEqual(male - female, 166, accuracy: 0.001)
    }

    func test_basalRate_fallsByFiveKcalPerYearOfAge() {
        let younger = Fixtures.profile(birthDate: Fixtures.date(1991, 1, 1))
        let older = Fixtures.profile(birthDate: Fixtures.date(1990, 1, 1))
        let difference =
            basalRate(younger, on: day, calendar: calendar)
            - basalRate(older, on: day, calendar: calendar)
        XCTAssertEqual(difference, 5, accuracy: 0.001)
    }

    func test_age_isComputedFromTheGivenDate_neverFromNow() {
        let profile = Fixtures.profile(birthDate: Fixtures.date(1990, 6, 1))
        XCTAssertEqual(profile.age(on: Fixtures.date(2026, 5, 31), calendar: calendar), 35)
        XCTAssertEqual(profile.age(on: Fixtures.date(2026, 6, 1), calendar: calendar), 36)
    }

    // MARK: - Maintenance

    func test_maintenance_scalesBasalRateByTheActivityMultiplier() {
        let profile = Fixtures.profile(activity: .moderate)
        let expected = basalRate(profile, on: day, calendar: calendar) * 1.55
        XCTAssertEqual(maintenance(profile, on: day, calendar: calendar), expected, accuracy: 0.001)
    }

    func test_activityMultipliers_spanTheConventionalRange() {
        XCTAssertEqual(Activity.sedentary.multiplier, 1.2, accuracy: 0.001)
        XCTAssertEqual(Activity.athlete.multiplier, 1.9, accuracy: 0.001)
        let ordered = Activity.allCases.map(\.multiplier)
        XCTAssertEqual(ordered, ordered.sorted(), "multipliers must increase with activity")
    }

    // MARK: - Daily target

    func test_dailyTarget_forHalfKgWeeklyCut_isMaintenanceMinus550() {
        let budget = dailyTarget(
            Fixtures.profile(goal: .cut(rate: .steady)),
            on: day,
            calendar: calendar
        )
        XCTAssertEqual(budget.offsetFromMaintenance, -550, accuracy: 0.001)
    }

    func test_dailyTarget_forMaintain_equalsMaintenance() {
        let budget = dailyTarget(Fixtures.profile(goal: .maintain), on: day, calendar: calendar)
        XCTAssertEqual(budget.target, budget.maintenance, accuracy: 0.001)
        XCTAssertTrue(budget.warnings.isEmpty)
    }

    func test_dailyTarget_forBulk_addsTheRateAsASurplus() {
        let budget = dailyTarget(
            Fixtures.profile(goal: .bulk(rate: WeightRate(kgPerWeek: 0.25))),
            on: day,
            calendar: calendar
        )
        XCTAssertEqual(budget.offsetFromMaintenance, 275, accuracy: 0.001)
    }

    func test_dailyTarget_neverDropsBelowBasalRate() {
        // Sedentary maintenance is 2,100 against a basal rate of 1,750; a
        // 1.5 kg/week cut asks for 1,650 off, which would land at 450.
        let budget = dailyTarget(
            Fixtures.profile(activity: .sedentary, goal: .cut(rate: WeightRate(kgPerWeek: 1.5))),
            on: day,
            calendar: calendar
        )
        XCTAssertEqual(budget.target, budget.basalRate, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(budget.target, 1750)
    }

    func test_dailyTarget_whenClamped_reportsTheClampAsAWarning() {
        let budget = dailyTarget(
            Fixtures.profile(activity: .sedentary, goal: .cut(rate: WeightRate(kgPerWeek: 1.5))),
            on: day,
            calendar: calendar
        )
        XCTAssertTrue(budget.hasWarning(.clampedToBasalRate))
    }

    func test_dailyTarget_forAGentleRate_raisesNoAggressiveWarning() {
        let budget = dailyTarget(
            Fixtures.profile(goal: .cut(rate: .gentle)),
            on: day,
            calendar: calendar
        )
        XCTAssertFalse(budget.hasWarning(.aggressiveRate))
    }

    func test_dailyTarget_forAnAggressiveRate_warnsButStillReturnsATarget() {
        // The domain says so; it does not refuse. The user is an adult.
        let budget = dailyTarget(
            Fixtures.profile(activity: .athlete, goal: .cut(rate: WeightRate(kgPerWeek: 1.0))),
            on: day,
            calendar: calendar
        )
        XCTAssertTrue(budget.hasWarning(.aggressiveRate))
        XCTAssertGreaterThan(budget.target, 0)
    }

    func test_dailyTarget_matchesTheOnboardingScreenWorkedExample() {
        // The design shows maintenance 2,565 and, at 0.35 kg/week, a target of 2,180.
        let budget = dailyTarget(Fixtures.onboardingExampleProfile(), on: day, calendar: calendar)
        XCTAssertEqual(budget.maintenance, 2565, accuracy: 0.001)
        XCTAssertEqual(budget.target, 2180, accuracy: 0.001)
    }

    // MARK: - Rates

    func test_weightRate_dailyOffset_dividesTheEnergyOfAKiloOverSevenDays() {
        XCTAssertEqual(WeightRate.steady.dailyEnergyOffset, 550, accuracy: 0.001)
        XCTAssertEqual(WeightRate(kgPerWeek: 0.35).dailyEnergyOffset, 385, accuracy: 0.001)
    }

    func test_weightRate_takesTheMagnitude_becauseDirectionComesFromTheGoal() {
        XCTAssertEqual(WeightRate(kgPerWeek: -0.5).kgPerWeek, 0.5, accuracy: 0.001)
    }

    func test_weightRate_isClampedToAPhysicallySensibleRange() {
        XCTAssertEqual(WeightRate(kgPerWeek: 9).kgPerWeek, 1.5, accuracy: 0.001)
    }

    func test_goalOffset_isNegativeForACutAndPositiveForABulk() {
        XCTAssertLessThan(Goal.cut(rate: .steady).dailyEnergyOffset, 0)
        XCTAssertGreaterThan(Goal.bulk(rate: .steady).dailyEnergyOffset, 0)
        XCTAssertEqual(Goal.maintain.dailyEnergyOffset, 0, accuracy: 0.001)
    }

    func test_maintainHasNoRate_soNoRateWarningIsPossible() {
        XCTAssertNil(Goal.maintain.rate)
    }
}
