import Foundation

/// The one piece of arithmetic the onboarding screen relies on: a daily
/// calorie target is derived from maintenance, direction and rate — never
/// typed by the user directly.
public enum EnergyMath {

    /// Rough energy density of a kilogram of body fat, used to convert a
    /// weekly rate of change into a daily calorie delta.
    public static let kcalPerKgFat: Double = 7700

    public static func dailyTarget(
        maintenance: Int,
        direction: GoalDirection,
        ratePerWeek: Double
    ) -> Int {
        let dailyDelta = ratePerWeek * kcalPerKgFat / 7
        let signedDelta = direction.isSurplus ? dailyDelta : -dailyDelta
        return Int((Double(maintenance) + signedDelta).rounded())
    }
}
