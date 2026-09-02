import XCTest

import GabitData
import GabitDomain

@testable import GabitUI

@MainActor
final class QuickAddViewModelTests: XCTestCase {

    private func makeModel(
        logs: [DayLog] = [],
        at instant: Date = UIFixtures.now
    ) -> (QuickAddViewModel, InMemoryStore) {
        let store = UIFixtures.store(logs: logs)
        let model = QuickAddViewModel(
            store: store,
            clock: UIFixtures.clock(at: instant),
            formatting: UIFixtures.formatting()
        )
        return (model, store)
    }

    // MARK: - Keypad

    func test_keypad_buildsTheNumberOneDigitAtATime() {
        let (model, _) = makeModel()
        model.appendDigit(5)
        model.appendDigit(2)
        model.appendDigit(0)

        XCTAssertEqual(model.energy, 520, accuracy: 0.001)
        XCTAssertEqual(model.energyDisplay, "520")
    }

    func test_keypad_doesNotAccumulateLeadingZeroes() {
        let (model, _) = makeModel()
        model.appendDigit(0)
        model.appendDigit(0)
        model.appendDigit(7)

        XCTAssertEqual(model.energyDisplay, "7")
    }

    func test_keypad_refusesADigitThatWouldExceedTheCeiling() {
        let (model, _) = makeModel()
        for _ in 0..<4 { model.appendDigit(9) }
        XCTAssertEqual(model.energy, 9_999, accuracy: 0.001)

        model.appendDigit(9)
        XCTAssertEqual(model.energy, 9_999, accuracy: 0.001, "a fifth digit is a typo, not a meal")
    }

    func test_doubleKey_doublesWhatIsAlreadyEntered() {
        let (model, _) = makeModel()
        model.appendDigit(2)
        model.appendDigit(6)
        model.appendDigit(0)

        model.doubleEnergy()

        XCTAssertEqual(model.energy, 520, accuracy: 0.001, "a second helping without retyping")
    }

    func test_doubleKey_doesNothingOnAnEmptyField() {
        let (model, _) = makeModel()
        model.doubleEnergy()
        XCTAssertEqual(model.energyDisplay, "")
    }

    func test_doubleKey_refusesToOverflowTheCeiling() {
        let (model, _) = makeModel()
        for digit in [8, 0, 0, 0] { model.appendDigit(digit) }
        model.doubleEnergy()
        XCTAssertEqual(model.energy, 8_000, accuracy: 0.001)
    }

    func test_deleteKey_removesTheLastDigit() {
        let (model, _) = makeModel()
        model.appendDigit(5)
        model.appendDigit(2)
        model.deleteDigit()

        XCTAssertEqual(model.energyDisplay, "5")
    }

    func test_deleteKey_onAnEmptyFieldIsHarmless() {
        let (model, _) = makeModel()
        model.deleteDigit()
        XCTAssertEqual(model.energyDisplay, "")
    }

    func test_emptyEnergy_displaysNothingRatherThanZero() {
        let (model, _) = makeModel()
        XCTAssertEqual(model.energyDisplay, "")
    }

    // MARK: - Saving

    func test_saveRequiresANameAndSomeEnergy() {
        let (model, _) = makeModel()
        XCTAssertFalse(model.canSave)

        model.name = "   "
        model.appendDigit(5)
        XCTAssertFalse(model.canSave, "whitespace is not a name")

        model.name = "Greek yoghurt, 200 g"
        XCTAssertTrue(model.canSave)
    }

    func test_save_writesTheEntryAndClearsTheForm() throws {
        let (model, store) = makeModel()
        model.name = "Greek yoghurt, 200 g"
        model.slot = .breakfast
        for digit in [1, 4, 8] { model.appendDigit(digit) }

        XCTAssertTrue(model.save())

        let log = try store.log(on: UIFixtures.now)
        let entry = try XCTUnwrap(log.food.first)
        XCTAssertEqual(entry.name, "Greek yoghurt, 200 g")
        XCTAssertEqual(entry.kcal, 148, accuracy: 0.001)
        XCTAssertEqual(entry.slot, .breakfast)
        XCTAssertEqual(model.name, "", "the form is ready for the next entry")
    }

    func test_save_trimsTheName() throws {
        let (model, store) = makeModel()
        model.name = "  Eggs ×3  "
        for digit in [2, 1, 5] { model.appendDigit(digit) }
        XCTAssertTrue(model.save())

        let entry = try XCTUnwrap(try store.log(on: UIFixtures.now).food.first)
        XCTAssertEqual(entry.name, "Eggs ×3")
    }

    func test_save_isRefusedWhenTheFormIsIncomplete() {
        let (model, _) = makeModel()
        model.name = "No calories given"
        XCTAssertFalse(model.save())
    }

    func test_macros_areAllOrNothing() throws {
        let (model, store) = makeModel()
        model.name = "Half remembered"
        for digit in [3, 0, 0] { model.appendDigit(digit) }
        model.proteinDigits = "20"
        model.fatDigits = "4"
        // Carbs deliberately left blank.

        XCTAssertTrue(model.save())
        let entry = try XCTUnwrap(try store.log(on: UIFixtures.now).food.first)
        XCTAssertNil(entry.macros, "a partial breakdown would show on Today as a real one")
    }

    func test_macros_areStoredWhenAllThreeAreGiven() throws {
        let (model, store) = makeModel()
        model.name = "Yoghurt"
        for digit in [1, 4, 8] { model.appendDigit(digit) }
        model.proteinDigits = "20"
        model.carbsDigits = "8"
        model.fatDigits = "4"

        XCTAssertTrue(model.save())
        let entry = try XCTUnwrap(try store.log(on: UIFixtures.now).food.first)
        XCTAssertEqual(entry.macros, Macros(proteinG: 20, carbsG: 8, fatG: 4))
    }

    // MARK: - Suggestions, the fast path

    func test_suggestions_offerRecentFoodsNewestFirst() {
        let logs = [
            DayLog(
                date: UIFixtures.date(2026, 9, 5),
                food: [
                    UIFixtures.food("Coffee, oat milk", 95, at: UIFixtures.date(2026, 9, 5, 7)),
                    UIFixtures.food("Eggs ×3", 215, at: UIFixtures.date(2026, 9, 5, 9)),
                ]
            )
        ]
        let (model, _) = makeModel(logs: logs)
        model.refresh()

        XCTAssertEqual(model.suggestions.map(\.name), ["Eggs ×3", "Coffee, oat milk"])
        XCTAssertEqual(model.suggestions.first?.kcal, "215")
    }

    func test_logSuggestion_writesTheEntryWithoutAnySaveStep() throws {
        let logs = [
            DayLog(
                date: UIFixtures.date(2026, 9, 5),
                food: [UIFixtures.food("Oats, whey, banana", 520, at: UIFixtures.date(2026, 9, 5, 8))]
            )
        ]
        let (model, store) = makeModel(logs: logs)
        model.refresh()

        let suggestion = try XCTUnwrap(model.suggestions.first)
        model.logSuggestion(id: suggestion.id)

        let today = try store.log(on: UIFixtures.now)
        XCTAssertEqual(today.food.count, 1, "one tap on the strip is the whole interaction")
        XCTAssertEqual(today.food.first?.kcal, 520)
    }

    func test_loggedSuggestion_isANewEntryNotTheOldOne() throws {
        let source = UIFixtures.food("Oats", 520, at: UIFixtures.date(2026, 9, 5, 8))
        let (model, store) = makeModel(
            logs: [DayLog(date: UIFixtures.date(2026, 9, 5), food: [source])]
        )
        model.refresh()
        model.logSuggestion(id: source.id)

        let copy = try XCTUnwrap(try store.log(on: UIFixtures.now).food.first)
        XCTAssertNotEqual(copy.id, source.id)
    }

    // MARK: - Defaults

    func test_slot_defaultsToTheMealTheClockSuggests() {
        let (breakfast, _) = makeModel(at: UIFixtures.date(2026, 9, 6, 8))
        breakfast.refresh()
        XCTAssertEqual(breakfast.slot, .breakfast)

        let (dinner, _) = makeModel(at: UIFixtures.date(2026, 9, 6, 19))
        dinner.refresh()
        XCTAssertEqual(dinner.slot, .dinner, "the common case should need no tap at all")

        let (snack, _) = makeModel(at: UIFixtures.date(2026, 9, 6, 23))
        snack.refresh()
        XCTAssertEqual(snack.slot, .snack)
    }
}
