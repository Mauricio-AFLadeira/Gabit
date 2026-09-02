import Foundation

/// Where a day stands against its budget.
///
/// The two ledgers stay separate all the way through: `intake` is what was
/// eaten and is never reduced by activity, while `burned` raises the allowance.
/// A screen that wants "remaining" asks for `remaining`; it does not do the
/// arithmetic itself.
public struct EnergyBalance: Sendable, Hashable {

    /// The day's target, before any burn is credited.
    public let target: Kcal

    /// Everything eaten. Independent of `burned` by design.
    public let intake: Kcal

    /// Everything credited back by logged activity.
    public let burned: Kcal

    /// Macros summed across the entries that carried them.
    public let macros: Macros

    public init(target: Kcal, intake: Kcal, burned: Kcal, macros: Macros) {
        self.target = target
        self.intake = intake
        self.burned = burned
        self.macros = macros
    }

    /// What the user may eat today once activity is credited.
    public var allowance: Kcal { target + burned }

    /// Allowance not yet eaten. Negative once the day is over budget.
    public var remaining: Kcal { allowance - intake }

    /// Whether the day has genuinely exceeded its budget.
    ///
    /// The one condition that unlocks red in the UI, per the foundations sheet.
    public var isOverBudget: Bool { remaining < 0 }

    /// How far over, as a positive number. Zero when within budget.
    public var overBy: Kcal { max(0, -remaining) }

    /// Progress through the allowance, clamped to 0...1 for ring rendering.
    ///
    /// Clamped here rather than in the view so that the over-budget screen does
    /// not have to special-case an arc that would otherwise wrap past full.
    public var consumedFraction: Double {
        guard allowance > 0 else { return 0 }
        return min(max(intake / allowance, 0), 1)
    }
}

/// Reduces a day's two ledgers against its target.
public func balance(_ log: DayLog, target: EnergyBudget) -> EnergyBalance {
    EnergyBalance(
        target: target.target,
        intake: log.intake,
        burned: log.burned,
        macros: log.macros
    )
}

/// Grams of each macro the user should aim at, given a budget.
///
/// Protein is set from body mass rather than from a percentage of energy, which
/// is what keeps it stable while the calorie target moves. Fat takes a floor
/// share for hormonal health, and carbohydrate absorbs the remainder — so a
/// bigger day shows up as more carbs, which is how people actually eat.
public struct MacroTargets: Sendable, Hashable {

    public let proteinG: Double
    public let carbsG: Double
    public let fatG: Double

    static let kcalPerGramProtein: Double = 4
    static let kcalPerGramCarb: Double = 4
    static let kcalPerGramFat: Double = 9

    public init(proteinG: Double, carbsG: Double, fatG: Double) {
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
    }
}

/// Derives macro targets for a profile's daily budget.
///
/// - Parameters:
///   - budget: The day's energy target.
///   - profile: Supplies the body mass protein is scaled from.
/// - Returns: Grams of protein, carbohydrate and fat to aim at today.
public func macroTargets(for budget: EnergyBudget, profile: Profile) -> MacroTargets {
    // 2.0 g/kg on a cut protects lean mass while in deficit; 1.6 g/kg otherwise
    // is the usual maintenance recommendation.
    let proteinPerKg: Double
    switch profile.goal {
    case .cut: proteinPerKg = 2.0
    case .maintain, .bulk: proteinPerKg = 1.6
    }

    let proteinG = (profile.weightKg * proteinPerKg).rounded()
    let fatG = (budget.target * 0.25 / MacroTargets.kcalPerGramFat).rounded()

    let proteinKcal = proteinG * MacroTargets.kcalPerGramProtein
    let fatKcal = fatG * MacroTargets.kcalPerGramFat
    let carbsG = max(0, (budget.target - proteinKcal - fatKcal) / MacroTargets.kcalPerGramCarb).rounded()

    return MacroTargets(proteinG: proteinG, carbsG: carbsG, fatG: fatG)
}
