import Foundation

/// The direction a user picks in onboarding — everything downstream (the
/// daily calorie target, the sign of the rate slider) is derived from this.
public enum GoalDirection: String, CaseIterable, Identifiable, Equatable, Sendable {
    case loseFat
    case recomposition
    case buildMass

    public var id: Self { self }

    public var title: String {
        switch self {
        case .loseFat: return "Lose fat"
        case .recomposition: return "Recomposition"
        case .buildMass: return "Build mass"
        }
    }

    public var subtitle: String {
        switch self {
        case .loseFat: return "Eat below maintenance"
        case .recomposition: return "Slight deficit, protein held high"
        case .buildMass: return "Controlled surplus"
        }
    }

    /// Whether this direction adds to or subtracts from maintenance calories.
    public var isSurplus: Bool {
        self == .buildMass
    }
}
