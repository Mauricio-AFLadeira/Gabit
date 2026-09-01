import Foundation
import Observation

import GabitData
import GabitDomain

/// How far back the trend chart looks.
public enum TrendRange: String, Sendable, Hashable, CaseIterable, Identifiable {
    case fourWeeks
    case twelveWeeks
    case oneYear

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .fourWeeks: "4 w"
        case .twelveWeeks: "12 w"
        case .oneYear: "1 y"
        }
    }

    var days: Int {
        switch self {
        case .fourWeeks: 28
        case .twelveWeeks: 84
        case .oneYear: 365
        }
    }
}

/// One plotted reading, normalised for drawing.
public struct TrendPoint: Sendable, Hashable, Identifiable {

    public let id: UUID
    /// 0...1 across the visible range.
    public let x: Double
    /// 0...1 across the visible weight span.
    public let y: Double

    public init(id: UUID, x: Double, y: Double) {
        self.id = id
        self.x = x
        self.y = y
    }
}

/// The Progress screen.
///
/// The projection is the interesting part: it is stated with the evidence
/// behind it, and it disappears entirely rather than degrading into a guess the
/// data does not support.
@MainActor
@Observable
public final class ProgressViewModel {

    private let store: any GabitStore
    private let clock: any GabitClock
    private let formatting: Formatting

    public var range: TrendRange = .twelveWeeks {
        didSet { refresh() }
    }

    public private(set) var currentWeight = ""
    public private(set) var changeSummary = ""
    public private(set) var points: [TrendPoint] = []
    public private(set) var axisLabels: [String] = []

    /// `At your average deficit you reach 75 kg around 14 November — roughly
    /// ten weeks out.` Nil when the trend does not support a projection.
    public private(set) var projectionHeadline: String?

    /// `Based on 34 readings. Recalculated every check-in; hidden when the
    /// trend flattens.`
    public private(set) var projectionFootnote: String?

    public private(set) var stats: [StatState] = []
    public private(set) var hasReadings = false

    public init(
        store: any GabitStore,
        clock: any GabitClock,
        formatting: Formatting = Formatting()
    ) {
        self.store = store
        self.clock = clock
        self.formatting = formatting
    }

    public func refresh() {
        let now = clock.now
        let readings = (try? store.checkIns()) ?? []
        hasReadings = !readings.isEmpty

        let start = DayBoundary.startOfDay(offsetBy: -range.days, from: now, in: clock.calendar)
        let visible = readings.filter { $0.takenAt >= start && $0.takenAt <= now }

        currentWeight = makeCurrentWeight(readings, now: now)
        changeSummary = makeChangeSummary(visible)
        points = makePoints(visible, from: start, to: now)
        axisLabels = makeAxisLabels(visible)
        buildProjection(readings, now: now)
        stats = makeStats(now: now)
    }

    public func addCheckIn(weightKg: Kg) {
        try? store.add(WeightCheckIn(weightKg: weightKg, takenAt: clock.now))
        refresh()
    }

    // MARK: - Private

    private func makeCurrentWeight(_ readings: [WeightCheckIn], now: Date) -> String {
        // The seven-day average, not the raw reading — the raw reading is mostly water.
        let average = trailingAverageWeight(readings, days: 7, endingAt: now, calendar: clock.calendar)
        guard let value = average ?? readings.last?.weightKg else { return "—" }
        return formatting.kilograms(value)
    }

    private func makeChangeSummary(_ visible: [WeightCheckIn]) -> String {
        guard let first = visible.first, let last = visible.last, visible.count >= 2 else {
            return "not enough readings yet"
        }
        let delta = last.weightKg - first.weightKg
        let sign = delta < 0 ? "−" : "+"
        return "\(sign)\(formatting.kilograms(abs(delta))) kg / \(range.title)"
    }

    private func makePoints(_ visible: [WeightCheckIn], from start: Date, to end: Date) -> [TrendPoint] {
        guard visible.count >= 2 else { return [] }

        let span = end.timeIntervalSince(start)
        let weights = visible.map(\.weightKg)
        let lowest = weights.min() ?? 0
        let highest = weights.max() ?? 1
        // A flat run would otherwise divide by zero and collapse the chart onto
        // one edge; give it a kilo of room and draw it down the middle.
        let range = max(highest - lowest, 1)

        return visible.map { reading in
            TrendPoint(
                id: reading.id,
                x: span > 0 ? reading.takenAt.timeIntervalSince(start) / span : 0,
                y: (reading.weightKg - lowest) / range
            )
        }
    }

    private func makeAxisLabels(_ visible: [WeightCheckIn]) -> [String] {
        guard let first = visible.first, let last = visible.last, visible.count >= 2 else {
            return []
        }
        let middle = visible[visible.count / 2]
        return [first, middle, last].map { formatting.dayHeader($0.takenAt) }
    }

    private func buildProjection(_ readings: [WeightCheckIn], now: Date) {
        guard
            let profile = try? store.loadProfile(),
            let goalWeight = targetWeight(for: profile),
            let result = projection(from: readings, target: goalWeight, calendar: clock.calendar)
        else {
            projectionHeadline = nil
            projectionFootnote = nil
            return
        }

        let weeks = Int((Double(result.daysRemaining) / 7).rounded())
        projectionHeadline =
            "At your average deficit you reach \(formatting.kilograms(result.targetKg)) kg around "
            + "\(formatting.longDate(result.reachedOn)) — roughly \(weeks) weeks out."
        projectionFootnote =
            "Based on \(result.readingCount) readings. "
            + "Recalculated every check-in; hidden when the trend flattens."
    }

    /// Where the user is heading.
    ///
    /// There is no explicit goal weight in the domain — the goal is a rate, by
    /// design — so the projection aims at a twelve-week horizon at the chosen
    /// rate. That keeps the promise to something the user has actually chosen.
    private func targetWeight(for profile: Profile) -> Kg? {
        switch profile.goal {
        case .cut(let rate): profile.weightKg - rate.kgPerWeek * 12
        case .bulk(let rate): profile.weightKg + rate.kgPerWeek * 12
        case .maintain: nil
        }
    }

    private func makeStats(now: Date) -> [StatState] {
        guard let profile = try? store.loadProfile() else { return [] }
        let budget = dailyTarget(profile, on: now, calendar: clock.calendar)
        let start = DayBoundary.startOfDay(offsetBy: -range.days, from: now, in: clock.calendar)
        let logs = (try? store.logs(from: start, to: now)) ?? []
        let summary = adherence(over: logs, target: budget)

        return [
            StatState(
                id: "logged",
                value: "\(summary.daysLogged)",
                caption: "days logged",
                accessibilityLabel: "\(summary.daysLogged) days logged"
            ),
            StatState(
                id: "within",
                value: formatting.percentage(summary.withinTargetFraction),
                caption: "within target",
                accessibilityLabel:
                    "\(formatting.percentage(summary.withinTargetFraction)) of days within target"
            ),
            StatState(
                id: "balance",
                value: formatting.signedKcal(summary.averageBalance),
                caption: "avg. balance",
                accessibilityLabel:
                    "Average balance \(formatting.signedKcal(summary.averageBalance)) kilocalories"
            ),
        ]
    }
}
