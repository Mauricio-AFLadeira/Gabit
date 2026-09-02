import Foundation
import GabitDomain

/// Shared fixtures.
///
/// Every date here is explicit and every calendar is pinned. Nothing in the
/// suite calls `Date()`, so a run in São Paulo and a run on a UTC CI runner
/// assert the same thing.
enum Fixtures {

    static let utc = Calendar.gabitUTC

    static var saoPaulo: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .gmt
        return calendar
    }

    static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0,
        in calendar: Calendar = utc
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        guard let date = calendar.date(from: components) else {
            preconditionFailure("Fixture date \(year)-\(month)-\(day) is not representable")
        }
        return date
    }

    /// The day the design's Today screen shows: Sun 06 Sep.
    static let referenceDay = date(2026, 9, 6)

    /// Turns 80 kg, 180 cm and a round age into a basal rate of exactly 1750,
    /// which keeps the energy assertions readable.
    ///
    /// 10 × 80 + 6.25 × 180 − 5 × 36 + 5 = 1750
    static func profile(
        sex: Sex = .male,
        heightCm: Cm = 180,
        weightKg: Kg = 80,
        activity: Activity = .moderate,
        goal: Goal = .cut(rate: .steady),
        birthDate: Date = date(1990, 1, 1)
    ) -> Profile {
        Profile(
            sex: sex,
            birthDate: birthDate,
            heightCm: heightCm,
            weightKg: weightKg,
            activity: activity,
            goal: goal
        )
    }

    /// The exact profile behind the worked example on the design's onboarding
    /// screen: maintenance 2,565 and, at 0.35 kg/week, a target of 2,180.
    ///
    /// 76 kg, 176 cm, 42 years old, moderately active.
    static func onboardingExampleProfile() -> Profile {
        Profile(
            sex: .male,
            birthDate: date(1984, 1, 15),
            heightCm: 176,
            weightKg: 76,
            activity: .moderate,
            goal: .cut(rate: WeightRate(kgPerWeek: 0.35))
        )
    }

    static func food(
        _ name: String,
        _ kcal: Kcal,
        slot: MealSlot = .lunch,
        macros: Macros? = nil,
        at loggedAt: Date = referenceDay
    ) -> FoodEntry {
        FoodEntry(name: name, kcal: kcal, macros: macros, slot: slot, loggedAt: loggedAt)
    }

    static func burn(
        _ name: String,
        _ kcal: Kcal,
        kind: BurnKind = .workout,
        at occurredAt: Date = referenceDay
    ) -> BurnEntry {
        BurnEntry(kind: kind, name: name, kcal: kcal, occurredAt: occurredAt)
    }

    static func checkIns(
        startingAt start: Date = date(2026, 6, 14),
        from first: Kg,
        stepKg: Double,
        count: Int,
        everyDays: Int = 7,
        in calendar: Calendar = utc
    ) -> [WeightCheckIn] {
        (0..<count).map { index in
            let takenAt =
                calendar.date(byAdding: .day, value: index * everyDays, to: start) ?? start
            return WeightCheckIn(weightKg: first + stepKg * Double(index), takenAt: takenAt)
        }
    }
}
