import Foundation

/// How consistently the user has been logging and staying on target.
///
/// The three figures on the Progress screen. Days with nothing logged are
/// excluded rather than counted as a perfect zero-calorie day — otherwise
/// forgetting to log would improve the numbers.
public struct Adherence: Sendable, Hashable {

    public let daysLogged: Int
    public let daysWithinTarget: Int

    /// Mean signed balance across logged days. Negative while in deficit.
    public let averageBalance: Kcal

    public init(daysLogged: Int, daysWithinTarget: Int, averageBalance: Kcal) {
        self.daysLogged = daysLogged
        self.daysWithinTarget = daysWithinTarget
        self.averageBalance = averageBalance
    }

    /// Share of logged days that stayed within budget, 0...1.
    public var withinTargetFraction: Double {
        guard daysLogged > 0 else { return 0 }
        return Double(daysWithinTarget) / Double(daysLogged)
    }

    public static let none = Adherence(daysLogged: 0, daysWithinTarget: 0, averageBalance: 0)
}

/// Summarises a run of days against a target.
public func adherence(over logs: [DayLog], target: EnergyBudget) -> Adherence {
    let logged = logs.filter { !$0.isEmpty }
    guard !logged.isEmpty else { return .none }

    let balances = logged.map { balance($0, target: target) }
    let withinTarget = balances.filter { !$0.isOverBudget }.count
    let total = balances.reduce(Kcal(0)) { $0 + ($1.intake - $1.allowance) }

    return Adherence(
        daysLogged: logged.count,
        daysWithinTarget: withinTarget,
        averageBalance: (total / Double(balances.count)).roundedToKcal
    )
}
