import Foundation

/// Where one day ends and the next begins.
///
/// Always the user's *local* midnight. Storing or comparing days in UTC is the
/// classic version of this bug: a meal logged at 22:00 in São Paulo lands on
/// tomorrow's log in UTC, and the day the user is looking at silently gains an
/// entry they did not make today.
public enum DayBoundary {

    /// The local midnight that starts the day containing `date`.
    public static func startOfDay(for date: Date, in calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Whether two instants fall on the same local day.
    public static func isSameDay(_ lhs: Date, _ rhs: Date, in calendar: Calendar) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }

    /// The local midnight `days` before the day containing `date`.
    public static func startOfDay(
        offsetBy days: Int,
        from date: Date,
        in calendar: Calendar
    ) -> Date {
        let start = startOfDay(for: date, in: calendar)
        return calendar.date(byAdding: .day, value: days, to: start) ?? start
    }
}
