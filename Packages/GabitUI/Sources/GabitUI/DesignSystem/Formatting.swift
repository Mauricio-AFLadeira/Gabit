import Foundation

import GabitDomain

/// Every string a screen shows is produced here, not in a view.
///
/// Plan §4 keeps formatting decisions out of the views along with the
/// arithmetic; putting them behind a type also means the thousands separator and
/// the date style are testable, and that a view model can be asserted against a
/// string a reviewer can read.
public struct Formatting: Sendable {

    private let locale: Locale
    private let calendar: Calendar

    public init(locale: Locale = .autoupdatingCurrent, calendar: Calendar = .current) {
        self.locale = locale
        self.calendar = calendar
    }

    /// Whole kilocalories with a thousands separator: `1,240`.
    public func kcal(_ value: Kcal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value.rounded())) ?? "0"
    }

    /// Signed kilocalories, used where the sign carries the meaning: `+240`.
    public func signedKcal(_ value: Kcal) -> String {
        let magnitude = kcal(abs(value))
        return value < 0 ? "−\(magnitude)" : "+\(magnitude)"
    }

    /// Weight to one decimal place: `78.4`.
    public func kilograms(_ value: Kg) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "0.0"
    }

    /// Whole grams: `132`.
    public func grams(_ value: Double) -> String {
        kcal(value)
    }

    /// The Today header's date: `Sun 06 Sep`.
    public func dayHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEE dd MMM")
        return formatter.string(from: date)
    }

    /// An entry's time: `08:15`.
    public func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("j:mm")
        return formatter.string(from: date)
    }

    /// A projection's arrival: `14 November`.
    public func longDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("d MMMM")
        return formatter.string(from: date)
    }

    /// A whole percentage: `81%`.
    public func percentage(_ fraction: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: fraction)) ?? "0%"
    }

    /// The compact macro summary on an entry row: `P 42 C 68 F 9`.
    public func macroSummary(_ macros: Macros) -> String {
        "P \(grams(macros.proteinG)) C \(grams(macros.carbsG)) F \(grams(macros.fatG))"
    }
}
