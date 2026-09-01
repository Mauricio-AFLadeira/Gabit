import Foundation

/// A warning the domain raises about a target. The UI renders it; it never
/// decides one.
public enum EnergyWarning: String, Sendable, Codable, Hashable, CaseIterable {

    /// The chosen rate is fast enough to risk muscle loss and poor adherence.
    case aggressiveRate

    /// The derived target would have fallen below basal rate and was clamped up
    /// to it. The user is seeing a target gentler than the one they asked for.
    case clampedToBasalRate
}

/// The daily energy allowance, with the arithmetic that produced it kept intact.
///
/// Carrying `maintenance` and `basalRate` alongside the target is what lets the
/// Today and Onboarding screens show their working without recomputing anything
/// — and keeps that arithmetic out of the views, per plan §4.
public struct EnergyBudget: Sendable, Codable, Hashable {

    /// Energy burned at complete rest.
    public let basalRate: Kcal

    /// Basal rate scaled by the activity multiplier.
    public let maintenance: Kcal

    /// What the user should eat today.
    public let target: Kcal

    /// Anything the user should know about how `target` was arrived at.
    public let warnings: Set<EnergyWarning>

    public init(basalRate: Kcal, maintenance: Kcal, target: Kcal, warnings: Set<EnergyWarning> = []) {
        self.basalRate = basalRate
        self.maintenance = maintenance
        self.target = target
        self.warnings = warnings
    }

    /// Signed difference between the target and maintenance.
    ///
    /// Negative on a cut. This is the *delivered* offset, so after a clamp it
    /// reports what the user actually gets, not what they asked for.
    public var offsetFromMaintenance: Kcal { target - maintenance }

    public func hasWarning(_ warning: EnergyWarning) -> Bool { warnings.contains(warning) }
}

/// Basal metabolic rate by Mifflin–St Jeor.
///
///     10 × kg + 6.25 × cm − 5 × age + (male: +5, female: −161)
///
/// - Parameters:
///   - profile: The user's measurements and sex.
///   - date: The instant to compute age at.
///   - calendar: The calendar to compute age in.
public func basalRate(_ profile: Profile, on date: Date, calendar: Calendar = .current) -> Kcal {
    let age = Double(profile.age(on: date, calendar: calendar))
    return 10 * profile.weightKg
        + 6.25 * profile.heightCm
        - 5 * age
        + profile.sex.basalOffset
}

/// Total daily energy expenditure: basal rate scaled by how much the user moves.
public func maintenance(_ profile: Profile, on date: Date, calendar: Calendar = .current) -> Kcal {
    basalRate(profile, on: date, calendar: calendar) * profile.activity.multiplier
}

/// The daily allowance, derived from the goal rather than typed by the user.
///
/// Two guardrails live here rather than in the view, so that they hold for every
/// caller and can be tested without a screen:
///
/// - The target is clamped so it can never fall below basal rate. Eating under
///   your resting requirement is not a faster cut, it is a worse one.
/// - A rate above `WeightRate.aggressiveThreshold` surfaces as a warning. The
///   domain does not refuse it — the user is an adult — it just says so.
public func dailyTarget(_ profile: Profile, on date: Date, calendar: Calendar = .current) -> EnergyBudget {
    let basal = basalRate(profile, on: date, calendar: calendar)
    let maintenanceRate = basal * profile.activity.multiplier
    let requested = maintenanceRate + profile.goal.dailyEnergyOffset

    var warnings: Set<EnergyWarning> = []
    if profile.goal.rate?.isAggressive == true {
        warnings.insert(.aggressiveRate)
    }

    let target: Kcal
    if requested < basal {
        target = basal
        warnings.insert(.clampedToBasalRate)
    } else {
        target = requested
    }

    return EnergyBudget(
        basalRate: basal.roundedToKcal,
        maintenance: maintenanceRate.roundedToKcal,
        target: target.roundedToKcal,
        warnings: warnings
    )
}
