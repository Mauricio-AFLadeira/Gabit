import XCTest

/// The one UI test from plan §5: onboard, log a meal, watch the budget change.
///
/// Smoke only. It exists to guard the wiring the unit tests cannot see — that
/// the composition root builds a real store, that the screens are reachable and
/// that a write on one screen shows up on another. Everything it could assert
/// about arithmetic is asserted faster elsewhere.
///
/// `@MainActor` because XCUIApplication and every element query are main-actor
/// isolated. This target is only ever built by Xcode, so the attribute costs
/// nothing here — unlike on the SwiftPM test targets, where it breaks XCTest's
/// method discovery on Linux.
@MainActor
final class GabitSmokeUITests: XCTestCase {

    /// The hero figure on Today, addressed by identifier rather than by its
    /// label: merging the figure and caption into one accessibility element
    /// makes it an "other" element, which `app.staticTexts` does not match.
    private let heroIdentifier = "today.hero"

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
        XCTAssertTrue(firstContinue.waitForExistence(timeout: 30))
        firstContinue.tap()

        // Step two: pick a direction, then finish.
        app.buttons.containing(NSPredicate(format: "label CONTAINS 'Lose fat'")).firstMatch.tap()
        app.buttons["Continue"].tap()

        let logFood = app.buttons["Log food"]
        XCTAssertTrue(logFood.waitForExistence(timeout: 30), "Today should be showing")

        let hero = app.descendants(matching: .any)[heroIdentifier]
        XCTAssertTrue(hero.waitForExistence(timeout: 10), "the hero figure should be on Today")
        let remainingBefore = hero.label

        logFood.tap()

        // Energy first, while the custom keypad is the only thing on screen.
        // Tapping the name field raises the system keyboard, which would cover
        // the keypad and make these keys unhittable.
        for digit in ["5", "2", "0"] {
            let key = app.buttons[digit]
            XCTAssertTrue(key.waitForExistence(timeout: 10), "keypad key \(digit) should be present")
            key.tap()
        }

        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText("Oats, whey, banana")

        // Save sits in the top toolbar, so the keyboard never covers it.
        app.buttons["Save"].tap()

        XCTAssertTrue(hero.waitForExistence(timeout: 10))
        XCTAssertNotEqual(hero.label, remainingBefore, "logging a meal must move the budget")
    }
}
