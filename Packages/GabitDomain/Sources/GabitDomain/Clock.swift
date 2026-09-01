import Foundation

/// The only way the domain and the view models learn what time it is.
///
/// Plan §4 calls this protocol `Clock`. It is `GabitClock` here because the
/// standard library already exports a `Clock` protocol: a file importing both
/// `GabitDomain` and Swift Concurrency could not then write `Clock` unqualified
/// without an ambiguity error. The concept is unchanged.
///
/// `Date()` is called in exactly one place in this repository — the composition
/// root, which builds a `SystemClock`. Everything else takes a clock through its
/// initialiser, which is what turns "the day rolls over at midnight" from a hope
/// into a test.
public protocol GabitClock: Sendable {

    /// The current instant.
    var now: Date { get }

    /// The calendar to interpret that instant in.
    ///
    /// Carried on the clock rather than read from `Calendar.current` at the point
    /// of use, so a test can pin the time zone along with the instant.
    var calendar: Calendar { get }
}

/// The live clock. Built once, in the composition root.
public struct SystemClock: GabitClock {

    public var now: Date { Date() }
    public var calendar: Calendar { Calendar.current }

    public init() {}
}

/// A clock frozen at an instant, for tests and previews.
public struct FixedClock: GabitClock {

    public let now: Date
    public let calendar: Calendar

    public init(now: Date, calendar: Calendar = .gabitUTC) {
        self.now = now
        self.calendar = calendar
    }
}

extension Calendar {

    /// A Gregorian calendar pinned to UTC.
    ///
    /// Only for tests that are not themselves about time zones — the ones that
    /// are pin their own zone explicitly, so that a machine in São Paulo and a
    /// CI runner in UTC agree on what they assert.
    public static var gabitUTC: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }
}
