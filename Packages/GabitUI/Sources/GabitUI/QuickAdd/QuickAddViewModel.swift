import Foundation
import GabitData
import GabitDomain
import Observation

/// Quick add, where the two-tap claim is won or lost.
///
/// The recent strip is the fast path: tapping a suggestion logs it as it stands,
/// with no keypad and no save step. Everything else on the screen exists for the
/// food that is not a repeat.
@MainActor
@Observable
public final class QuickAddViewModel {

    private let store: any GabitStore
    private let clock: any GabitClock
    private let formatting: Formatting

    public var name = ""
    public var slot: MealSlot = .breakfast

    /// Digits as the keypad has entered them. A string rather than a number so
    /// that a half-typed "1" and a deliberate "0" stay distinguishable.
    public private(set) var energyDigits = ""

    public var proteinDigits = ""
    public var carbsDigits = ""
    public var fatDigits = ""

    public private(set) var suggestions: [SuggestionState] = []

    /// The largest energy a single entry may carry. Above this the user has
    /// almost certainly typed an extra digit.
    static let maximumKcal: Kcal = 9_999

    public init(
        store: any GabitStore,
        clock: any GabitClock,
        formatting: Formatting = Formatting()
    ) {
        self.store = store
        self.clock = clock
        self.formatting = formatting
    }

    /// What the energy field displays. Zero reads as an empty field, not "0".
    public var energyDisplay: String {
        energyDigits.isEmpty ? "" : formatting.kcal(energy)
    }

    public var energy: Kcal {
        Kcal(Int(energyDigits) ?? 0)
    }

    /// A name and a non-zero energy are the whole requirement. Macros are
    /// optional because a user who only knows the calories should not be blocked.
    public var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && energy > 0
    }

    public func refresh() {
        slot = defaultSlot(at: clock.now)
        suggestions = makeSuggestions()
    }

    // MARK: - Keypad

    public func appendDigit(_ digit: Int) {
        guard (0...9).contains(digit) else { return }
        let candidate = energyDigits + String(digit)
        // Drop the leading zero rather than accumulating "007".
        let normalised = candidate.drop { $0 == "0" }
        guard let value = Int(normalised), Kcal(value) <= Self.maximumKcal else { return }
        energyDigits = String(normalised)
    }

    public func deleteDigit() {
        guard !energyDigits.isEmpty else { return }
        energyDigits.removeLast()
    }

    /// The keypad's `×2` key: a second helping, without retyping.
    public func doubleEnergy() {
        let doubled = energy * 2
        guard doubled > 0, doubled <= Self.maximumKcal else { return }
        energyDigits = String(Int(doubled))
    }

    public func clearEnergy() {
        energyDigits = ""
    }

    // MARK: - Saving

    @discardableResult
    public func save() -> Bool {
        guard canSave else { return false }
        let entry = FoodEntry(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            kcal: energy,
            macros: enteredMacros(),
            slot: slot,
            loggedAt: clock.now
        )
        try? store.addFood(entry, on: clock.now)
        reset()
        return true
    }

    /// Logs a suggestion exactly as it stands. The second of the two taps.
    public func logSuggestion(id: UUID) {
        guard let source = recentEntries().first(where: { $0.id == id }) else { return }
        let entry = FoodEntry(
            name: source.name,
            kcal: source.kcal,
            macros: source.macros,
            slot: defaultSlot(at: clock.now),
            loggedAt: clock.now
        )
        try? store.addFood(entry, on: clock.now)
    }

    public func reset() {
        name = ""
        energyDigits = ""
        proteinDigits = ""
        carbsDigits = ""
        fatDigits = ""
    }

    // MARK: - Private

    /// Macros are all-or-nothing: a partial breakdown would show up on the
    /// Today screen as a real one with two of its three numbers at zero.
    private func enteredMacros() -> Macros? {
        guard
            let protein = Double(proteinDigits),
            let carbs = Double(carbsDigits),
            let fat = Double(fatDigits)
        else { return nil }
        return Macros(proteinG: protein, carbsG: carbs, fatG: fat)
    }

    private func recentEntries() -> [FoodEntry] {
        let today = clock.now
        let start = DayBoundary.startOfDay(offsetBy: -13, from: today, in: clock.calendar)
        let logs = (try? store.logs(from: start, to: today)) ?? []
        return RepeatMeal.recent(from: logs, limit: 4)
    }

    private func makeSuggestions() -> [SuggestionState] {
        recentEntries().map { entry in
            SuggestionState(
                id: entry.id,
                name: entry.name,
                kcal: formatting.kcal(entry.kcal),
                accessibilityLabel:
                    "Log \(entry.name), \(formatting.kcal(entry.kcal)) kilocalories"
            )
        }
    }

    /// The slot the clock suggests, so the common case needs no tap at all.
    private func defaultSlot(at date: Date) -> MealSlot {
        switch clock.calendar.component(.hour, from: date) {
        case 4..<11: .breakfast
        case 11..<16: .lunch
        case 16..<22: .dinner
        default: .snack
        }
    }
}
