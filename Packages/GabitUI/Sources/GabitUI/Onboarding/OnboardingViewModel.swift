import Foundation
import GabitData
import GabitDomain
import Observation

/// The direction the user picks, in their words rather than the domain's.
public enum GoalChoice: String, Sendable, Hashable, CaseIterable, Identifiable {
    case loseFat
    case recomposition
    case buildMass

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .loseFat: "Lose fat"
        case .recomposition: "Recomposition"
        case .buildMass: "Build mass"
        }
    }

    public var subtitle: String {
        switch self {
        case .loseFat: "Eat below maintenance"
        case .recomposition: "Slight deficit, protein held high"
        case .buildMass: "Controlled surplus"
        }
    }

    /// Recomposition runs at a fixed gentle deficit, so it offers no rate to
    /// pick — the whole point of it is that the number is small and steady.
    public var offersRateChoice: Bool {
        self != .recomposition
    }

    static let recompositionRate = WeightRate(kgPerWeek: 0.15)

    func goal(rate: Double) -> Goal {
        switch self {
        case .loseFat: .cut(rate: WeightRate(kgPerWeek: rate))
        case .recomposition: .cut(rate: Self.recompositionRate)
        case .buildMass: .bulk(rate: WeightRate(kgPerWeek: rate))
        }
    }
}

/// Onboarding, in two steps: the measurements the formula needs, then the goal.
///
/// The goal step is the one screen where the domain shows itself — the user
/// picks a direction and a rate, and the target is derived. It is never typed,
/// which is what stops it going stale as the weight changes.
@MainActor
@Observable
public final class OnboardingViewModel {

    public enum Step: Int, Sendable, Hashable, CaseIterable {
        case measurements
        case goal
    }

    private let store: any GabitStore
    private let clock: any GabitClock
    private let formatting: Formatting

    public private(set) var step: Step = .measurements

    public var sex: Sex = .female
    public var birthDate: Date
    public var heightCm: Cm = 170
    public var weightKg: Kg = 70
    public var activity: Activity = .moderate

    public var choice: GoalChoice = .loseFat
    public var rateKgPerWeek: Double = 0.35

    /// The slider's ends, from the design: gentle on the left, aggressive on the right.
    public let rateRange: ClosedRange<Double> = 0.1...1.0

    public init(
        store: any GabitStore,
        clock: any GabitClock,
        formatting: Formatting = Formatting()
    ) {
        self.store = store
        self.clock = clock
        self.formatting = formatting
        // A default that puts the user in the middle of the range the formula
        // was fitted on, rather than at an implausible extreme.
        self.birthDate =
            clock.calendar.date(byAdding: .year, value: -30, to: clock.now) ?? clock.now
    }

    /// The profile as configured so far.
    public var draftProfile: Profile {
        Profile(
            sex: sex,
            birthDate: birthDate,
            heightCm: heightCm,
            weightKg: weightKg,
            activity: activity,
            goal: choice.goal(rate: rateKgPerWeek)
        )
    }

    private var budget: EnergyBudget {
        dailyTarget(draftProfile, on: clock.now, calendar: clock.calendar)
    }

    /// `2,180` — the derived target, front and centre.
    public var targetDisplay: String { formatting.kcal(budget.target) }

    /// `maintenance 2,565`
    public var maintenanceDisplay: String {
        "maintenance \(formatting.kcal(budget.maintenance))"
    }

    /// `0.35`
    public var rateDisplay: String {
        String(format: "%.2f", displayedRate)
    }

    public var displayedRate: Double {
        choice.offersRateChoice ? rateKgPerWeek : GoalChoice.recompositionRate.kgPerWeek
    }

    /// The warnings the domain raised, in the user's words. The UI renders
    /// these; it does not decide when they apply.
    public var warnings: [String] {
        budget.warnings.sorted { $0.rawValue < $1.rawValue }.map { warning in
            switch warning {
            case .aggressiveRate:
                "That is a fast rate. It is harder to hold on to muscle, and harder to stick to."
            case .clampedToBasalRate:
                "We have held your target at your resting requirement. "
                    + "Eating below it is not a faster cut."
            }
        }
    }

    public var targetAccessibilityLabel: String {
        "Your daily target, \(formatting.kcal(budget.target)) kilocalories. "
            + "Maintenance is \(formatting.kcal(budget.maintenance))."
    }

    // MARK: - Navigation

    public func advance() {
        if step == .measurements { step = .goal }
    }

    public func back() {
        if step == .goal { step = .measurements }
    }

    /// Writes the profile. Returns false when the store refused it, so the view
    /// can stay put rather than dismissing onto a screen with no profile behind it.
    @discardableResult
    public func finish() -> Bool {
        do {
            try store.save(draftProfile)
            return true
        } catch {
            return false
        }
    }
}
