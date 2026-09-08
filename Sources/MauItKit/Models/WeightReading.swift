import Foundation

/// One point on the weight trend line.
public struct WeightReading: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let date: Date
    public let kg: Double

    public init(id: UUID = UUID(), date: Date, kg: Double) {
        self.id = id
        self.date = date
        self.kg = kg
    }
}

/// A three-part sentence with one bold clause in the middle — the shape the
/// projection callout needs ("At your average deficit you reach **75 kg
/// around 14 November** — roughly ten weeks out.") without smuggling markup
/// into a plain string.
public struct EmphasizedSentence: Sendable, Equatable {
    public let prefix: String
    public let emphasis: String
    public let suffix: String

    public init(prefix: String, emphasis: String, suffix: String) {
        self.prefix = prefix
        self.emphasis = emphasis
        self.suffix = suffix
    }
}

/// Everything the Progress screen shows: the trend line, the projection
/// callout and the adherence tally.
public struct ProgressSummary: Sendable, Equatable {
    public let readings: [WeightReading]
    public let projection: EmphasizedSentence
    public let projectionFootnote: String
    public let daysLogged: Int
    public let percentWithinTarget: Int
    public let averageDailyBalance: Int

    public init(
        readings: [WeightReading],
        projection: EmphasizedSentence,
        projectionFootnote: String,
        daysLogged: Int,
        percentWithinTarget: Int,
        averageDailyBalance: Int
    ) {
        self.readings = readings
        self.projection = projection
        self.projectionFootnote = projectionFootnote
        self.daysLogged = daysLogged
        self.percentWithinTarget = percentWithinTarget
        self.averageDailyBalance = averageDailyBalance
    }

    public var currentWeightKg: Double {
        readings.last?.kg ?? 0
    }

    public var deltaKg: Double {
        (readings.first?.kg ?? 0) - (readings.last?.kg ?? 0)
    }

    public var spanWeeks: Int {
        guard let first = readings.first?.date, let last = readings.last?.date else { return 0 }
        return Int(last.timeIntervalSince(first) / (7 * 24 * 3600))
    }

    public var deltaLabel: String {
        "\(SignedFormatting.decimal(-deltaKg)) kg / \(spanWeeks) w"
    }
}
