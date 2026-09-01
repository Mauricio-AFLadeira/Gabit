import Foundation

import GabitDomain

/// The store the tests run against.
///
/// Not a mock: it is a complete, correct implementation of the same contract,
/// which is what makes a view-model test that passes here mean something. The
/// SwiftData store is checked against the same expectations in its own suite.
///
/// It also builds on Linux, so the domain-adjacent half of the test suite runs
/// in the container without a simulator.
@MainActor
public final class InMemoryStore: GabitStore {

    private var profile: Profile?
    private var logsByDay: [Date: DayLog] = [:]
    private var readings: [WeightCheckIn] = []
    private let calendar: Calendar

    /// - Parameter calendar: The calendar day boundaries are computed in.
    ///   Injected so a test can pin the time zone.
    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// Seeds the store, for previews and for tests that need a populated day.
    public func seed(profile: Profile? = nil, logs: [DayLog] = [], checkIns: [WeightCheckIn] = []) {
        if let profile { self.profile = profile }
        for log in logs {
            let key = DayBoundary.startOfDay(for: log.date, in: calendar)
            logsByDay[key] = DayLog(date: key, food: log.food, burn: log.burn)
        }
        readings.append(contentsOf: checkIns)
    }

    // MARK: - ProfileStoring

    public func loadProfile() throws -> Profile? { profile }

    public func save(_ profile: Profile) throws { self.profile = profile }

    // MARK: - DayLogStoring

    public func log(on day: Date) throws -> DayLog {
        let key = DayBoundary.startOfDay(for: day, in: calendar)
        return logsByDay[key] ?? DayLog(date: key)
    }

    public func logs(from start: Date, to end: Date) throws -> [DayLog] {
        let lower = DayBoundary.startOfDay(for: start, in: calendar)
        let upper = DayBoundary.startOfDay(for: end, in: calendar)
        return logsByDay.values
            .filter { $0.date >= lower && $0.date <= upper }
            .sorted { $0.date < $1.date }
    }

    public func addFood(_ entry: FoodEntry, on day: Date) throws {
        try mutate(on: day) { $0.food.append(entry) }
    }

    public func addBurn(_ entry: BurnEntry, on day: Date) throws {
        try mutate(on: day) { $0.burn.append(entry) }
    }

    public func removeFood(id: UUID, on day: Date) throws {
        try mutate(on: day) { log in
            guard let index = log.food.firstIndex(where: { $0.id == id }) else {
                throw StoreError.entryNotFound(id)
            }
            log.food.remove(at: index)
        }
    }

    public func removeBurn(id: UUID, on day: Date) throws {
        try mutate(on: day) { log in
            guard let index = log.burn.firstIndex(where: { $0.id == id }) else {
                throw StoreError.entryNotFound(id)
            }
            log.burn.remove(at: index)
        }
    }

    // MARK: - CheckInStoring

    public func checkIns() throws -> [WeightCheckIn] {
        readings.sorted { $0.takenAt < $1.takenAt }
    }

    public func add(_ checkIn: WeightCheckIn) throws {
        readings.append(checkIn)
    }

    public func remove(id: UUID) throws {
        guard let index = readings.firstIndex(where: { $0.id == id }) else {
            throw StoreError.entryNotFound(id)
        }
        readings.remove(at: index)
    }

    // MARK: - Private

    private func mutate(on day: Date, _ body: (inout DayLog) throws -> Void) throws {
        let key = DayBoundary.startOfDay(for: day, in: calendar)
        var log = logsByDay[key] ?? DayLog(date: key)
        try body(&log)
        logsByDay[key] = log
    }
}
