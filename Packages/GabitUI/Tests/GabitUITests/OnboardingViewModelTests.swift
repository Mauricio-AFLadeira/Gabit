import XCTest

import GabitData
import GabitDomain

@testable import GabitUI

@MainActor
final class OnboardingViewModelTests: XCTestCase {

    private func makeModel() -> (OnboardingViewModel, InMemoryStore) {
        let store = UIFixtures.store(profile: nil)
        let model = OnboardingViewModel(
            store: store,
            clock: UIFixtures.clock(),
            formatting: UIFixtures.formatting()
        )
        return (model, store)
    }

    /// Puts the model on the design's worked example.
    private func configureAsDesignExample(_ model: OnboardingViewModel) {
        model.sex = .male
        model.birthDate = UIFixtures.date(1984, 1, 15)
        model.heightCm = 176
        model.weightKg = 76
        model.activity = .moderate
        model.choice = .loseFat
        model.rateKgPerWeek = 0.35
    }

    func test_target_isDerived_neverTyped() {
        let (model, _) = makeModel()
        configureAsDesignExample(model)

        XCTAssertEqual(model.targetDisplay, "2,180")
        XCTAssertEqual(model.maintenanceDisplay, "maintenance 2,565")
    }

    func test_target_movesWithTheRate() {
        let (model, _) = makeModel()
        configureAsDesignExample(model)
        let gentle = model.targetDisplay

        model.rateKgPerWeek = 0.75
        XCTAssertNotEqual(model.targetDisplay, gentle, "the derived number tracks the choice")
    }

    func test_bulk_raisesTheTargetAboveMaintenance() {
        let (model, _) = makeModel()
        configureAsDesignExample(model)
        model.choice = .buildMass

        let budget = dailyTarget(model.draftProfile, on: UIFixtures.now, calendar: UIFixtures.calendar)
        XCTAssertGreaterThan(budget.target, budget.maintenance)
    }

    func test_recomposition_offersNoRate_andRunsAtAFixedGentleDeficit() {
        let (model, _) = makeModel()
        configureAsDesignExample(model)
        model.choice = .recomposition

        XCTAssertFalse(model.choice.offersRateChoice)
        XCTAssertEqual(model.displayedRate, 0.15, accuracy: 0.001)
        XCTAssertEqual(model.draftProfile.goal, .cut(rate: WeightRate(kgPerWeek: 0.15)))
    }

    func test_aggressiveRate_surfacesTheDomainWarning() {
        // 0.80 kg/week clears the aggressive threshold while still leaving the
        // target above basal rate, so this isolates the one warning. Going to
        // 1.0 would clamp as well and raise both.
        let (model, _) = makeModel()
        configureAsDesignExample(model)
        model.rateKgPerWeek = 0.80

        XCTAssertEqual(model.warnings.count, 1, "got \(model.warnings)")
        XCTAssertTrue(model.warnings[0].contains("fast rate"))
    }

    func test_noWarningsAtAGentleRate() {
        let (model, _) = makeModel()
        configureAsDesignExample(model)
        XCTAssertTrue(model.warnings.isEmpty)
    }

    func test_clampWarning_explainsWhatTheDomainDid() {
        let (model, _) = makeModel()
        configureAsDesignExample(model)
        model.activity = .sedentary
        model.rateKgPerWeek = 1.0

        XCTAssertTrue(
            model.warnings.contains { $0.contains("resting requirement") },
            "got \(model.warnings)"
        )
    }

    func test_stepsAdvanceAndGoBack() {
        let (model, _) = makeModel()
        XCTAssertEqual(model.step, .measurements)

        model.advance()
        XCTAssertEqual(model.step, .goal)

        model.back()
        XCTAssertEqual(model.step, .measurements)

        model.back()
        XCTAssertEqual(model.step, .measurements, "there is nothing before the first step")
    }

    func test_finish_writesTheProfile() throws {
        let (model, store) = makeModel()
        configureAsDesignExample(model)

        XCTAssertTrue(model.finish())

        let saved = try XCTUnwrap(try store.loadProfile())
        XCTAssertEqual(saved.weightKg, 76, accuracy: 0.001)
        XCTAssertEqual(saved.goal, .cut(rate: WeightRate(kgPerWeek: 0.35)))
    }

    func test_defaultBirthDate_comesFromTheClock() {
        let (model, _) = makeModel()
        let age = model.draftProfile.age(on: UIFixtures.now, calendar: UIFixtures.calendar)
        XCTAssertEqual(age, 30, "a default in the middle of the range the formula was fitted on")
    }

    func test_rateDisplay_showsTwoDecimals() {
        let (model, _) = makeModel()
        model.rateKgPerWeek = 0.35
        XCTAssertEqual(model.rateDisplay, "0.35")
    }
}
