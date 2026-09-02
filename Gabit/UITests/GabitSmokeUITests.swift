import XCTest

/// The one UI test from plan §5: onboard, log a meal, watch the budget change.
///
/// Smoke only. It exists to guard the wiring the unit tests cannot see — that
/// the composition root builds a real store, that the screens are reachable and
/// that a write on one screen shows up on another. Everything it could assert
/// about arithmetic is asserted faster elsewhere.
final class GabitSmokeUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func test_onboardThenLogAMeal_changesTheRemainingBudget() {
        let app = XCUIApplication()
        app.launchArguments += ["-gabit-ui-testing"]
        app.launch()

        // Step one of onboarding, straight through on its defaults.
        let firstContinue = app.buttons["Continue"]
        XCTAssertTrue(firstContinue.waitForExistence(timeout: 10))
        firstContinue.tap()

        // Step two: pick a direction, then finish.
        app.buttons.containing(NSPredicate(format: "label CONTAINS 'Lose fat'")).firstMatch.tap()
        app.buttons["Continue"].tap()

        let logFood = app.buttons["Log food"]
        XCTAssertTrue(logFood.waitForExistence(timeout: 10), "Today should be showing")

        let before = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'kilocalories remaining'")
        ).firstMatch
        XCTAssertTrue(before.waitForExistence(timeout: 5))
        let remainingBefore = before.label

        logFood.tap()

        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Oats, whey, banana")

        for digit in ["5", "2", "0"] {
            app.buttons[digit].tap()
        }
        app.buttons["Save"].tap()

        let after = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'kilocalories remaining'")
        ).firstMatch
        XCTAssertTrue(after.waitForExistence(timeout: 5))
        XCTAssertNotEqual(after.label, remainingBefore, "logging a meal must move the budget")
    }
}
