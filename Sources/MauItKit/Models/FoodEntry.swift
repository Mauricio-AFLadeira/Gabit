import Foundation

/// Macro grams for a single entry — never shown without its two siblings,
/// since a macro is only meaningful relative to protein, carbs and fat together.
public struct MacroBreakdown: Sendable, Equatable {
    public let proteinGrams: Int
    public let carbsGrams: Int
    public let fatGrams: Int

    public init(proteinGrams: Int, carbsGrams: Int, fatGrams: Int) {
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
    }
}

/// What kind of row this is — a logged meal, or a manually-estimated burn.
/// Burn entries credit the day's budget instead of spending it.
public enum FoodEntryKind: Sendable, Equatable {
    case meal(MealType)
    case exercise
}

public struct FoodEntry: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let kind: FoodEntryKind
    public let title: String
    public let time: String
    public let calories: Int
    public let macros: MacroBreakdown?

    public init(
        id: UUID = UUID(),
        kind: FoodEntryKind,
        title: String,
        time: String,
        calories: Int,
        macros: MacroBreakdown? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.time = time
        self.calories = calories
        self.macros = macros
    }
}

/// A tappable "recent" chip on the quick-add screen — logs as-is in one tap.
public struct QuickAddItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let title: String
    public let calories: Int

    public init(id: UUID = UUID(), title: String, calories: Int) {
        self.id = id
        self.title = title
        self.calories = calories
    }
}
