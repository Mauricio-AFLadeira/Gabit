import Foundation

/// Which part of the day an entry belongs to.
public enum MealSlot: String, Sendable, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack

    public var id: String { rawValue }
}

/// Protein, carbohydrate and fat in grams.
///
/// Optional on an entry: a user who only knows the calorie count should not be
/// blocked from logging, and a partial day's macros are still worth showing.
public struct Macros: Sendable, Codable, Hashable {

    public var proteinG: Double
    public var carbsG: Double
    public var fatG: Double

    public init(proteinG: Double = 0, carbsG: Double = 0, fatG: Double = 0) {
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
    }

    public static let zero = Macros()

    public static func + (lhs: Macros, rhs: Macros) -> Macros {
        Macros(
            proteinG: lhs.proteinG + rhs.proteinG,
            carbsG: lhs.carbsG + rhs.carbsG,
            fatG: lhs.fatG + rhs.fatG
        )
    }
}

/// Something the user ate.
public struct FoodEntry: Sendable, Codable, Hashable, Identifiable {

    public let id: UUID
    public var name: String
    public var kcal: Kcal
    public var macros: Macros?
    public var slot: MealSlot
    public var loggedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        kcal: Kcal,
        macros: Macros? = nil,
        slot: MealSlot,
        loggedAt: Date
    ) {
        self.id = id
        self.name = name
        self.kcal = kcal
        self.macros = macros
        self.slot = slot
        self.loggedAt = loggedAt
    }
}

/// How a burn entry was arrived at.
public enum BurnKind: String, Sendable, Codable, CaseIterable {
    case workout
    case steps
    case manual
}

/// Energy the user spent beyond their activity baseline.
public struct BurnEntry: Sendable, Codable, Hashable, Identifiable {

    public let id: UUID
    public var kind: BurnKind
    public var name: String
    public var kcal: Kcal
    public var occurredAt: Date

    public init(
        id: UUID = UUID(),
        kind: BurnKind,
        name: String,
        kcal: Kcal,
        occurredAt: Date
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.kcal = kcal
        self.occurredAt = occurredAt
    }
}

/// One day's two ledgers.
///
/// Food and burn are kept apart deliberately — the second modelling decision in
/// plan §3. Folding a workout into "negative food" is the bug most of these apps
/// ship: it corrupts the intake total that macro targets are measured against.
public struct DayLog: Sendable, Codable, Hashable {

    /// The day this log covers, normalised to local midnight by `DayBoundary`.
    public let date: Date
    public var food: [FoodEntry]
    public var burn: [BurnEntry]

    public init(date: Date, food: [FoodEntry] = [], burn: [BurnEntry] = []) {
        self.date = date
        self.food = food
        self.burn = burn
    }

    /// Total energy eaten. Never reduced by burn.
    public var intake: Kcal {
        food.reduce(0) { $0 + $1.kcal }
    }

    /// Total energy credited back by logged activity.
    public var burned: Kcal {
        burn.reduce(0) { $0 + $1.kcal }
    }

    /// Macros summed across entries that carry them.
    public var macros: Macros {
        food.compactMap(\.macros).reduce(Macros.zero, +)
    }

    /// Entries in a slot, oldest first.
    public func entries(in slot: MealSlot) -> [FoodEntry] {
        food.filter { $0.slot == slot }.sorted { $0.loggedAt < $1.loggedAt }
    }

    public var isEmpty: Bool { food.isEmpty && burn.isEmpty }
}

/// A weight reading.
public struct WeightCheckIn: Sendable, Codable, Hashable, Identifiable {

    public let id: UUID
    public var weightKg: Kg
    public var takenAt: Date

    public init(id: UUID = UUID(), weightKg: Kg, takenAt: Date) {
        self.id = id
        self.weightKg = weightKg
        self.takenAt = takenAt
    }
}
