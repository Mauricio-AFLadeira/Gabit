import XCTest

@testable import MauItKit

final class SignedFormattingTests: XCTestCase {
    func testPositiveIntegerGetsPlusSign() {
        XCTAssertEqual(SignedFormatting.integer(120), "+120")
    }

    func testNegativeIntegerGetsTypographicMinus() {
        XCTAssertEqual(SignedFormatting.integer(-120), "\u{2212}120")
    }

    func testZeroIntegerGetsPlusSign() {
        XCTAssertEqual(SignedFormatting.integer(0), "+0")
    }

    func testPositiveDecimalDefaultsToOneFractionDigit() {
        XCTAssertEqual(SignedFormatting.decimal(1.27), "+1.3")
    }

    func testNegativeDecimalGetsTypographicMinus() {
        XCTAssertEqual(SignedFormatting.decimal(-0.5), "\u{2212}0.5")
    }

    func testDecimalRespectsFractionDigits() {
        XCTAssertEqual(SignedFormatting.decimal(2.0, fractionDigits: 0), "+2")
    }
}
