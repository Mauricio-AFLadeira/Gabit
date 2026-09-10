import Foundation

/// The four logging buckets offered on the quick-add screen.
public enum MealType: String, CaseIterable, Identifiable, Equatable, Sendable {
    case breakfast
    case lunch
    case dinner
    case snack

    public var id: Self { self }

    public var label: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }

    /// Single-character glyph used on the round entry-row avatar in place of
    /// a hand-drawn icon set — the design's stated stand-in for SF Symbols.
    public var glyph: String {
        switch self {
        case .breakfast: return "B"
        case .lunch: return "L"
        case .dinner: return "D"
        case .snack: return "S"
        }
    }
}
