import Foundation
import GabitData
import GabitDomain
import Observation

/// Everything the Today screen shows, already resolved.
///
/// The view reads these properties and lays them out. It performs no
/// arithmetic, makes no formatting decision and asks no question the model has
/// not already answered — which is what keeps the snapshot tests meaningful and
/// these tests fast.
@MainActor
@Observable
public final class TodayViewModel {

    private let store: any GabitStore
    private let clock: any GabitClock
    private let formatting: Formatting

    public private(set) var dateLabel = ""
    public private(set) var heroValue = ""
    public private(set) var heroCaption = ""
    public private(set) var heroAccessibilityLabel = ""
    public private(set) var isOverBudget = false
    public private(set) var ledger: [LedgerChipState] = []
    public private(set) var macros: [MacroRowState] = []
    public private(set) var entries: [EntryRowState] = []
    public private(set) var entryCountLabel = ""
    public private(set) var canRepeatYesterday = false

    /// The line shown only when the day is over budget and the trend is still
    /// good. Absent rather than empty when there is nothing reassuring to say —
    /// a tracker that insists everything is fine is not worth trusting.
    public private(set) var reassurance: String?

    public init(
        store: any GabitStore,
        clock: any GabitClock,
        formatting: Formatting = Formatting()
    ) {
        self.store = store
        self.clock = clock
        self.formatting = formatting
    }

    /// Rebuilds every displayed value from the store.
    ///
    /// Failures are swallowed into an empty day rather than thrown at the view:
    /// there is nothing a user can do about a read error on this screen, and a
    /// blank Today is a better answer than a crash.
    public func refresh() {
        let today = clock.now
        dateLabel = formatting.dayHeader(today)

        guard let profile = try? store.loadProfile() else {
            resetToEmpty()
            return
        }

        let budget = dailyTarget(profile, on: today, calendar: clock.calendar)
        let log = (try? store.log(on: today)) ?? DayLog(date: today)
        let result = balance(log, target: budget)

        isOverBudget = result.isOverBudget
        heroValue =
            result.isOverBudget
            ? formatting.signedKcal(result.overBy)
            : formatting.kcal(result.remaining)
        heroCaption = result.isOverBudget ? "kcal over target" : "kcal remaining"
        heroAccessibilityLabel =
            result.isOverBudget
            ? "\(formatting.kcal(result.overBy)) kilocalories over target"
            : "\(formatting.kcal(result.remaining)) kilocalories remaining"

        ledger = [
            LedgerChipState(id: "eaten", label: "eaten", value: formatting.kcal(result.intake)),
            LedgerChipState(id: "burn", label: "burn", value: formatting.signedKcal(result.burned)),
            LedgerChipState(id: "target", label: "target", value: formatting.kcal(budget.target)),
        ]

        macros = makeMacroRows(consumed: result.macros, targets: macroTargets(for: budget, profile: profile))
        entries = makeEntryRows(log)
        entryCountLabel = entries.count == 1 ? "1 entry" : "\(entries.count) entries"

        let yesterday = DayBoundary.startOfDay(offsetBy: -1, from: today, in: clock.calendar)
        canRepeatYesterday = ((try? store.log(on: yesterday))?.food.isEmpty == false)

        reassurance = result.isOverBudget ? makeReassurance(today: today, budget: budget) : nil
    }

    /// Copies yesterday's entries onto today. The two-tap path from plan §8.
    public func repeatYesterday() {
        let today = clock.now
        let yesterday = DayBoundary.startOfDay(offsetBy: -1, from: today, in: clock.calendar)
        guard let previous = try? store.log(on: yesterday), !previous.food.isEmpty else { return }

        for entry in RepeatMeal.copy(previous.food, onto: today, in: clock.calendar) {
            try? store.addFood(entry, on: today)
        }
        refresh()
    }

    public func deleteEntry(id: UUID, kind: EntryRowState.Kind) {
        switch kind {
        case .food: try? store.removeFood(id: id, on: clock.now)
        case .burn: try? store.removeBurn(id: id, on: clock.now)
        }
        refresh()
    }

    // MARK: - Private

    private func resetToEmpty() {
        heroValue = formatting.kcal(0)
        heroCaption = "kcal remaining"
        heroAccessibilityLabel = "No profile yet"
        isOverBudget = false
        ledger = []
        macros = []
        entries = []
        entryCountLabel = "0 entries"
        canRepeatYesterday = false
        reassurance = nil
    }

    private func makeMacroRows(consumed: Macros, targets: MacroTargets) -> [MacroRowState] {
        func row(_ kind: MacroKind, _ name: String, _ eaten: Double, _ target: Double) -> MacroRowState {
            let fraction = target > 0 ? min(max(eaten / target, 0), 1) : 0
            let value = "\(formatting.grams(eaten)) / \(formatting.grams(target)) g"
            return MacroRowState(
                kind: kind,
                name: name,
                value: value,
                fraction: fraction,
                accessibilityLabel:
                    "\(name), \(formatting.grams(eaten)) of \(formatting.grams(target)) grams"
            )
        }

        return [
            row(.protein, "Protein", consumed.proteinG, targets.proteinG),
            row(.carbs, "Carbs", consumed.carbsG, targets.carbsG),
            row(.fat, "Fat", consumed.fatG, targets.fatG),
        ]
    }

    private func makeEntryRows(_ log: DayLog) -> [EntryRowState] {
        let food = log.food.map { entry in
            let detail =
                entry.macros.map { "\(formatting.time(entry.loggedAt)) · \(formatting.macroSummary($0))" }
                ?? formatting.time(entry.loggedAt)
            return EntryRowState(
                id: entry.id,
                kind: .food,
                badge: entry.slot.badge,
                title: entry.name,
                detail: detail,
                value: formatting.kcal(entry.kcal),
                accessibilityLabel:
                    "\(entry.name), \(formatting.kcal(entry.kcal)) kilocalories, "
                    + "\(entry.slot.displayName), \(formatting.time(entry.loggedAt))"
            )
        }

        let burn = log.burn.map { entry in
            EntryRowState(
                id: entry.id,
                kind: .burn,
                badge: "↑",
                title: entry.name,
                detail: "\(formatting.time(entry.occurredAt)) · manual estimate",
                value: formatting.signedKcal(entry.kcal),
                accessibilityLabel:
                    "\(entry.name), \(formatting.kcal(entry.kcal)) kilocalories credited back, "
                    + "\(formatting.time(entry.occurredAt))"
            )
        }

        return (food + burn).sorted { lhs, rhs in
            sortKey(lhs, in: log) < sortKey(rhs, in: log)
        }
    }

    private func sortKey(_ row: EntryRowState, in log: DayLog) -> Date {
        switch row.kind {
        case .food: log.food.first { $0.id == row.id }?.loggedAt ?? .distantPast
        case .burn: log.burn.first { $0.id == row.id }?.occurredAt ?? .distantPast
        }
    }

    /// The over-budget screen's second sentence, when the week supports it.
    private func makeReassurance(today: Date, budget: EnergyBudget) -> String? {
        let start = DayBoundary.startOfDay(offsetBy: -6, from: today, in: clock.calendar)
        guard let week = try? store.logs(from: start, to: today) else { return nil }

        let summary = adherence(over: week, target: budget)
        guard summary.daysLogged >= 3, summary.averageBalance < 0 else { return nil }

        return "One day over doesn't move the trend. Your 7-day average is still "
            + "\(formatting.signedKcal(summary.averageBalance)) kcal, which keeps you on pace."
    }
}
