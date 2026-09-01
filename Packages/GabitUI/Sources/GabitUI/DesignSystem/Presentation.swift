import Foundation

import GabitDomain

/// The resolved values a screen renders.
///
/// Plan §4 keeps views dumb: no arithmetic, no formatting decisions, no
/// conditionals beyond rendering what the view model already resolved. These
/// types are that contract written down. They hold strings, not numbers, so a
/// view-model test asserts the thing the user actually sees.
///
/// Colour is named by role rather than held as a `Color`: the state stays free
/// of SwiftUI, and the mapping to a palette entry stays in one place.
public enum MacroKind: String, Sendable, Hashable, CaseIterable {
    case protein
    case carbs
    case fat
}

/// One row of the macro split under the hero figure.
public struct MacroRowState: Sendable, Hashable, Identifiable {

    public let kind: MacroKind
    /// `Protein`
    public let name: String
    /// `132 / 170 g`
    public let value: String
    /// 0...1, already clamped.
    public let fraction: Double
    public let accessibilityLabel: String

    public var id: MacroKind { kind }

    public init(
        kind: MacroKind,
        name: String,
        value: String,
        fraction: Double,
        accessibilityLabel: String
    ) {
        self.kind = kind
        self.name = name
        self.value = value
        self.fraction = fraction
        self.accessibilityLabel = accessibilityLabel
    }
}

/// One row in the day's entry list.
public struct EntryRowState: Sendable, Hashable, Identifiable {

    public enum Kind: Sendable, Hashable {
        case food
        case burn
    }

    public let id: UUID
    public let kind: Kind
    /// `B`, `L`, `D`, `S` for meals; `↑` for a burn.
    public let badge: String
    /// `Chicken & rice bowl`
    public let title: String
    /// `13:40 · P 62 C 60 F 18`
    public let detail: String
    /// `735`, or `+240` for a burn.
    public let value: String
    /// What VoiceOver reads instead of the four fragments above.
    public let accessibilityLabel: String

    public init(
        id: UUID,
        kind: Kind,
        badge: String,
        title: String,
        detail: String,
        value: String,
        accessibilityLabel: String
    ) {
        self.id = id
        self.kind = kind
        self.badge = badge
        self.title = title
        self.detail = detail
        self.value = value
        self.accessibilityLabel = accessibilityLabel
    }
}

/// A food the quick-add strip offers for one-tap logging.
public struct SuggestionState: Sendable, Hashable, Identifiable {

    public let id: UUID
    public let name: String
    /// `520`
    public let kcal: String
    public let accessibilityLabel: String

    public init(id: UUID, name: String, kcal: String, accessibilityLabel: String) {
        self.id = id
        self.name = name
        self.kcal = kcal
        self.accessibilityLabel = accessibilityLabel
    }
}

extension MealSlot {

    /// The single-letter badge on an entry row.
    var badge: String {
        switch self {
        case .breakfast: "B"
        case .lunch: "L"
        case .dinner: "D"
        case .snack: "S"
        }
    }

    /// The name shown on the quick-add segment control.
    public var displayName: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        }
    }
}

/// One of the three small figures under the hero: `eaten 1,625`.
public struct LedgerChipState: Sendable, Hashable, Identifiable {

    public let id: String
    /// `eaten`
    public let label: String
    /// `1,625`
    public let value: String

    public init(id: String, label: String, value: String) {
        self.id = id
        self.label = label
        self.value = value
    }
}

/// A figure in the adherence row on Progress: `68` / `days logged`.
public struct StatState: Sendable, Hashable, Identifiable {

    public let id: String
    public let value: String
    public let caption: String
    public let accessibilityLabel: String

    public init(id: String, value: String, caption: String, accessibilityLabel: String) {
        self.id = id
        self.value = value
        self.caption = caption
        self.accessibilityLabel = accessibilityLabel
    }
}
