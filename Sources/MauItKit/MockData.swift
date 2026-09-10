import Foundation

/// Hand-authored sample data standing in for the persistence layer this
/// prototype deliberately doesn't have. Every screen renders from here.
public enum MockData {

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }

    // MARK: - Onboarding

    public static let maintenanceCalories = 2565
    public static let defaultDirection: GoalDirection = .recomposition
    public static let defaultRatePerWeek = 0.35
    public static let minRatePerWeek = 0.1
    public static let maxRatePerWeek = 1.0

    // MARK: - Today

    public static let onTrackDay = DayLog(
        date: date(2026, 9, 6),
        targetCalories: 2180,
        eatenCalories: 1625,
        burnCalories: 240,
        proteinGrams: 132,
        proteinTarget: 170,
        carbsGrams: 128,
        carbsTarget: 230,
        fatGrams: 46,
        fatTarget: 72,
        entries: [
            FoodEntry(
                kind: .meal(.breakfast),
                title: "Oats, whey, banana",
                time: "08:15",
                calories: 520,
                macros: MacroBreakdown(proteinGrams: 42, carbsGrams: 68, fatGrams: 9)
            ),
            FoodEntry(
                kind: .meal(.lunch),
                title: "Chicken & rice bowl",
                time: "13:40",
                calories: 735,
                macros: MacroBreakdown(proteinGrams: 62, carbsGrams: 60, fatGrams: 18)
            ),
            FoodEntry(
                kind: .exercise,
                title: "Lifting, 62 min",
                time: "18:05",
                calories: 240
            ),
        ]
    )

    public static let overBudgetDay = DayLog(
        date: date(2026, 9, 4),
        targetCalories: 2180,
        eatenCalories: 2490,
        burnCalories: 0,
        proteinGrams: 150,
        proteinTarget: 170,
        carbsGrams: 210,
        carbsTarget: 230,
        fatGrams: 70,
        fatTarget: 72,
        entries: [
            FoodEntry(
                kind: .meal(.dinner),
                title: "Pizza, half",
                time: "20:50",
                calories: 910,
                macros: MacroBreakdown(proteinGrams: 38, carbsGrams: 96, fatGrams: 34)
            ),
            FoodEntry(
                kind: .meal(.lunch),
                title: "Chicken & rice bowl",
                time: "13:20",
                calories: 735,
                macros: MacroBreakdown(proteinGrams: 62, carbsGrams: 60, fatGrams: 18)
            ),
        ],
        insightNote:
            "One day over doesn't move the trend. Your 7-day average is still \u{2212}390 kcal, which keeps you on pace."
    )

    // MARK: - Quick add

    public static let recentQuickAdds = [
        QuickAddItem(title: "Oats, whey, banana", calories: 520),
        QuickAddItem(title: "Chicken bowl", calories: 735),
        QuickAddItem(title: "Coffee, oat milk", calories: 95),
        QuickAddItem(title: "Eggs \u{00D7}3", calories: 215),
    ]

    // MARK: - Progress

    public static let progressSummary: ProgressSummary = {
        let start = date(2026, 6, 14)
        let weights: [Double] = [
            81.3, 81.0, 81.1, 80.7, 80.4, 80.6, 80.0, 79.7, 79.9, 79.3, 79.0, 78.7, 78.4,
        ]
        let readings = weights.enumerated().map { index, kg in
            WeightReading(date: start.addingTimeInterval(Double(index) * 7 * 24 * 3600), kg: kg)
        }
        return ProgressSummary(
            readings: readings,
            projection: EmphasizedSentence(
                prefix: "At your average deficit you reach ",
                emphasis: "75 kg around 14 November",
                suffix: " — roughly ten weeks out."
            ),
            projectionFootnote: "Based on 34 readings. Recalculated every check-in; hidden when the trend flattens.",
            daysLogged: 68,
            percentWithinTarget: 81,
            averageDailyBalance: -480
        )
    }()
}
