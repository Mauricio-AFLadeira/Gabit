import Foundation

/// Biological sex, as the Mifflin–St Jeor equation uses it.
///
/// The equation has exactly two coefficients, so this type has exactly two
/// cases. It is a parameter of a formula, not a statement about the user, and
/// the onboarding copy says so.
public enum Sex: String, Sendable, Codable, CaseIterable {
    case female
    case male

    /// The constant term Mifflin–St Jeor adds after the mass, height and age terms.
    var basalOffset: Kcal {
        switch self {
        case .male: 5
        case .female: -161
        }
    }
}

/// How much the user moves, expressed as the multiplier applied to basal rate.
public enum Activity: String, Sendable, Codable, CaseIterable {
    case sedentary
    case light
    case moderate
    case high
    case athlete

    /// The conventional Harris–Benedict activity factors, 1.2 through 1.9.
    public var multiplier: Double {
        switch self {
        case .sedentary: 1.2
        case .light: 1.375
        case .moderate: 1.55
        case .high: 1.725
        case .athlete: 1.9
        }
    }
}

/// How fast the user intends to change weight, in kilograms per week.
///
/// A rate rather than a calorie number is the first of the two modelling
/// decisions in plan §3: the daily target is *derived* from it, so it
/// recomputes as weight changes instead of going quietly stale.
public struct WeightRate: Sendable, Codable, Hashable {

    /// Kilograms per week. Always positive; direction comes from the `Goal`.
    public let kgPerWeek: Double

    /// Above this, the deficit stops being comfortably sustainable and the
    /// domain raises a warning the UI renders.
    public static let aggressiveThreshold: Double = 0.75

    public static let gentle = WeightRate(kgPerWeek: 0.25)
    public static let steady = WeightRate(kgPerWeek: 0.5)

    /// Creates a rate, clamping to a physically sensible range.
    ///
    /// - Parameter kgPerWeek: Magnitude of the intended weekly change. Negative
    ///   values are treated as their magnitude, since direction is the `Goal`'s job.
    public init(kgPerWeek: Double) {
        self.kgPerWeek = min(max(abs(kgPerWeek), 0), 1.5)
    }

    /// The daily energy offset this rate implies.
    public var dailyEnergyOffset: Kcal {
        kgPerWeek * kcalPerKgOfFat / 7
    }

    /// Whether this rate is fast enough to warrant a warning.
    public var isAggressive: Bool {
        kgPerWeek > Self.aggressiveThreshold
    }
}

/// The direction the user is working in.
public enum Goal: Sendable, Codable, Hashable {
    case cut(rate: WeightRate)
    case maintain
    case bulk(rate: WeightRate)

    /// Signed daily adjustment applied to maintenance.
    ///
    /// Negative for a cut, positive for a bulk, zero for maintain.
    public var dailyEnergyOffset: Kcal {
        switch self {
        case .cut(let rate): -rate.dailyEnergyOffset
        case .maintain: 0
        case .bulk(let rate): rate.dailyEnergyOffset
        }
    }

    /// The rate behind the goal, absent when maintaining.
    public var rate: WeightRate? {
        switch self {
        case .cut(let rate), .bulk(let rate): rate
        case .maintain: nil
        }
    }
}

/// Everything the energy math needs to know about the user.
public struct Profile: Sendable, Codable, Hashable {

    public var sex: Sex
    public var birthDate: Date
    public var heightCm: Cm
    public var weightKg: Kg
    public var activity: Activity
    public var goal: Goal

    public init(
        sex: Sex,
        birthDate: Date,
        heightCm: Cm,
        weightKg: Kg,
        activity: Activity,
        goal: Goal
    ) {
        self.sex = sex
        self.birthDate = birthDate
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.activity = activity
        self.goal = goal
    }

    /// Age in whole years at `date`, in the given calendar.
    ///
    /// Takes the date explicitly rather than reaching for `Date()`: a birthday
    /// that lands mid-session should not make a test flaky.
    public func age(on date: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.year], from: birthDate, to: date).year ?? 0
    }
}
