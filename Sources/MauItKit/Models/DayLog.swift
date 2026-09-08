import Foundation

/// One day's worth of intake, credited burn and macro progress — the model
/// behind the Today screen, in both its on-track and over-budget states.
public struct DayLog: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let date: Date
    public let targetCalories: Int
    public let eatenCalories: Int
    public let burnCalories: Int
    public let proteinGrams: Int
    public let proteinTarget: Int
    public let carbsGrams: Int
    public let carbsTarget: Int
    public let fatGrams: Int
    public let fatTarget: Int
    public let entries: [FoodEntry]
    /// A short, non-scolding read on the day — shown only in the over-budget
    /// state, where the screen owes the user context rather than a warning.
    public let insightNote: String?

    public init(
        id: UUID = UUID(),
        date: Date,
        targetCalories: Int,
        eatenCalories: Int,
        burnCalories: Int,
        proteinGrams: Int,
        proteinTarget: Int,
        carbsGrams: Int,
        carbsTarget: Int,
        fatGrams: Int,
        fatTarget: Int,
        entries: [FoodEntry],
        insightNote: String? = nil
    ) {
        self.id = id
        self.date = date
        self.targetCalories = targetCalories
        self.eatenCalories = eatenCalories
        self.burnCalories = burnCalories
        self.proteinGrams = proteinGrams
        self.proteinTarget = proteinTarget
        self.carbsGrams = carbsGrams
        self.carbsTarget = carbsTarget
        self.fatGrams = fatGrams
        self.fatTarget = fatTarget
        self.entries = entries
        self.insightNote = insightNote
    }

    /// Positive while under budget, negative once burn-credited intake
    /// exceeds the target — the sign the whole Today screen keys off of.
    public var remainingCalories: Int {
        targetCalories - eatenCalories + burnCalories
    }

    public var isOverBudget: Bool {
        remainingCalories < 0
    }

    /// Fraction of the target ring the "eaten, net of burn" arc should fill.
    public var consumedFraction: Double {
        min(1, max(0, Double(eatenCalories - burnCalories) / Double(targetCalories)))
    }

    /// Fraction of the target the thin burn arc credits back.
    public var burnFraction: Double {
        min(1, max(0, Double(burnCalories) / Double(targetCalories)))
    }

    public var weekdayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE dd MMM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
