import Foundation

/// When the user reaches their target weight, if the current trend holds.
public struct Projection: Sendable, Hashable {

    /// The weight being projected towards.
    public let targetKg: Kg

    /// The day the trend reaches `targetKg`.
    public let reachedOn: Date

    /// Whole days from the latest reading to `reachedOn`.
    public let daysRemaining: Int

    /// Observed trend, signed: negative while losing.
    public let kgPerWeek: Double

    /// How many readings the trend was fitted to. Shown so the user can judge
    /// how much to trust it.
    public let readingCount: Int

    public init(
        targetKg: Kg,
        reachedOn: Date,
        daysRemaining: Int,
        kgPerWeek: Double,
        readingCount: Int
    ) {
        self.targetKg = targetKg
        self.reachedOn = reachedOn
        self.daysRemaining = daysRemaining
        self.kgPerWeek = kgPerWeek
        self.readingCount = readingCount
    }
}

/// Rules for when a projection is honest enough to show.
public enum ProjectionRules {

    /// Below three readings there is no trend, only noise.
    public static let minimumReadings = 3

    /// A trend flatter than this is treated as no trend at all. Half a kilo a
    /// month is roughly the point where day-to-day water weight stops drowning
    /// the signal.
    public static let flatThresholdKgPerWeek: Double = 0.05

    /// Beyond this the projection is arithmetic rather than information, and
    /// showing a date five years out invites more trust than it deserves.
    public static let maximumHorizonDays = 730
}

/// Projects the date the user reaches `target`, or nothing if the data does not
/// support a projection.
///
/// Returns `nil` — rather than a number nobody should act on — when:
///
/// - there are fewer than `ProjectionRules.minimumReadings` readings;
/// - the fitted trend is flatter than `flatThresholdKgPerWeek`;
/// - the trend points away from the target;
/// - the target is already reached;
/// - the date would land beyond `maximumHorizonDays`.
///
/// The trend is an ordinary least-squares fit over every reading, which is less
/// jumpy than differencing the first and last and does not need the readings to
/// be evenly spaced.
public func projection(
    from checkIns: [WeightCheckIn],
    target: Kg,
    calendar: Calendar = .current
) -> Projection? {
    let readings = checkIns.sorted { $0.takenAt < $1.takenAt }
    guard readings.count >= ProjectionRules.minimumReadings,
        let first = readings.first,
        let latest = readings.last
    else { return nil }

    let origin = DayBoundary.startOfDay(for: first.takenAt, in: calendar)
    let points: [(x: Double, y: Double)] = readings.map { reading in
        (x: reading.takenAt.timeIntervalSince(origin) / 86_400, y: reading.weightKg)
    }

    guard let slopePerDay = leastSquaresSlope(points) else { return nil }

    let kgPerWeek = slopePerDay * 7
    guard abs(kgPerWeek) >= ProjectionRules.flatThresholdKgPerWeek else { return nil }

    // Compare the target against the fitted value at the latest reading rather
    // than the raw reading: a single heavy morning should not flip the sign.
    let fittedLatest = fittedValue(points, at: points[points.count - 1].x) ?? latest.weightKg
    let gap = target - fittedLatest
    guard abs(gap) >= ProjectionRules.flatThresholdKgPerWeek else { return nil }
    guard gap.sign == slopePerDay.sign else { return nil }

    let days = gap / slopePerDay
    guard days.isFinite, days > 0, days <= Double(ProjectionRules.maximumHorizonDays) else { return nil }

    let wholeDays = Int(days.rounded())
    guard
        let reachedOn = calendar.date(
            byAdding: .day,
            value: wholeDays,
            to: DayBoundary.startOfDay(for: latest.takenAt, in: calendar)
        )
    else { return nil }

    return Projection(
        targetKg: target,
        reachedOn: reachedOn,
        daysRemaining: wholeDays,
        kgPerWeek: kgPerWeek,
        readingCount: readings.count
    )
}

/// Trailing average of the readings taken within `days` of the latest one.
///
/// The number the Progress screen shows instead of the raw reading, because the
/// raw reading is mostly water.
public func trailingAverageWeight(
    _ checkIns: [WeightCheckIn],
    days: Int = 7,
    endingAt end: Date,
    calendar: Calendar = .current
) -> Kg? {
    let cutoff = DayBoundary.startOfDay(offsetBy: -(days - 1), from: end, in: calendar)
    let window = checkIns.filter { $0.takenAt >= cutoff && $0.takenAt <= end }
    guard !window.isEmpty else { return nil }
    return window.reduce(0) { $0 + $1.weightKg } / Double(window.count)
}

// MARK: - Fitting

/// Slope of the least-squares line through `points`, or nil when every point
/// shares an x value and the slope is undefined.
private func leastSquaresSlope(_ points: [(x: Double, y: Double)]) -> Double? {
    let n = Double(points.count)
    guard n >= 2 else { return nil }

    let meanX = points.reduce(0) { $0 + $1.x } / n
    let meanY = points.reduce(0) { $0 + $1.y } / n

    var covariance: Double = 0
    var variance: Double = 0
    for point in points {
        let dx = point.x - meanX
        covariance += dx * (point.y - meanY)
        variance += dx * dx
    }

    guard variance > 0 else { return nil }
    let slope = covariance / variance
    return slope.isFinite ? slope : nil
}

/// The fitted line's value at `x`.
private func fittedValue(_ points: [(x: Double, y: Double)], at x: Double) -> Double? {
    guard let slope = leastSquaresSlope(points) else { return nil }
    let n = Double(points.count)
    let meanX = points.reduce(0) { $0 + $1.x } / n
    let meanY = points.reduce(0) { $0 + $1.y } / n
    return meanY + slope * (x - meanX)
}
