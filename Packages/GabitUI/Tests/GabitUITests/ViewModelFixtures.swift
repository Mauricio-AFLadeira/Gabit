import Foundation
import GabitData
import GabitDomain

@testable import GabitUI

/// Shared setup for the view-model tests.
///
/// Every one of them runs against the in-memory store and a clock frozen at a
/// known instant, so "what does Today show at 18:00 on the 6th" is a question
/// with one answer on every machine.
enum UIFixtures {

    static let calendar = Calendar.gabitUTC

    /// Sunday 6 September 2026, 18:00 — the day the design's Today screen shows.
    static let now = date(2026, 9, 6, 18)

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        guard let date = calendar.date(from: components) else {
            preconditionFailure("bad fixture date")
        }
        return date
    }

    static func clock(at instant: Date = now) -> FixedClock {
        FixedClock(now: instant, calendar: calendar)
    }

    /// The profile behind the design's worked example: maintenance 2,565 and a
    /// target of 2,180 at 0.35 kg/week.
    static func profile() -> Profile {
        Profile(
            sex: .male,
            birthDate: date(1984, 1, 15),
            heightCm: 176,
            weightKg: 76,
            activity: .moderate,
            goal: .cut(rate: WeightRate(kgPerWeek: 0.35))
        )
    }

    /// A formatter pinned to a locale, so assertions on separators hold wherever
    /// the suite runs.
    static func formatting() -> Formatting {
        Formatting(locale: Locale(identifier: "en_GB"), calendar: calendar)
    }

    @MainActor
    static func store(
        profile: Profile? = UIFixtures.profile(),
        logs: [DayLog] = [],
        checkIns: [WeightCheckIn] = []
    ) -> InMemoryStore {
        let store = InMemoryStore(calendar: calendar)
        store.seed(profile: profile, logs: logs, checkIns: checkIns)
        return store
    }

    static func food(
        _ name: String,
        _ kcal: Kcal,
        slot: MealSlot = .lunch,
        macros: Macros? = nil,
        at loggedAt: Date
    ) -> FoodEntry {
        FoodEntry(name: name, kcal: kcal, macros: macros, slot: slot, loggedAt: loggedAt)
    }
}
