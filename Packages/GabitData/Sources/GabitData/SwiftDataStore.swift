#if canImport(SwiftData)

    import Foundation
    import SwiftData

    import GabitDomain

    /// The live store.
    ///
    /// Implements the same three protocols as `InMemoryStore` and nothing more.
    /// Everything SwiftData-shaped — `ModelContext`, `FetchDescriptor`, the
    /// record classes — stops at this file's boundary.
        public final class SwiftDataStore: GabitStore {

        private let context: ModelContext
        private let calendar: Calendar

        public init(context: ModelContext, calendar: Calendar = .current) {
            self.context = context
            self.calendar = calendar
        }

        /// Builds a container over the app's schema.
        ///
        /// - Parameter inMemory: Keeps everything in memory, for tests and previews.
        /// - Returns: A container over every entity in `GabitSchema`.
        /// - Throws: Whatever SwiftData raises when the store cannot be opened.
        public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
            let schema = Schema(GabitSchema.all)
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
            return try ModelContainer(for: schema, configurations: [configuration])
        }

        // MARK: - ProfileStoring

        public func loadProfile() throws -> Profile? {
            try fetchProfileRecord()?.domainValue
        }

        public func save(_ profile: Profile) throws {
            // One profile per install, so update in place rather than inserting a
            // second row that later reads would have to choose between.
            if let existing = try fetchProfileRecord() {
                existing.update(from: profile)
            } else {
                context.insert(ProfileRecord(profile))
            }
            try context.save()
        }

        // MARK: - DayLogStoring

        public func log(on day: Date) throws -> DayLog {
            let key = DayBoundary.startOfDay(for: day, in: calendar)
            return try fetchDayRecord(key)?.domainValue ?? DayLog(date: key)
        }

        public func logs(from start: Date, to end: Date) throws -> [DayLog] {
            let lower = DayBoundary.startOfDay(for: start, in: calendar)
            let upper = DayBoundary.startOfDay(for: end, in: calendar)
            let descriptor = FetchDescriptor<DayLogRecord>(
                predicate: #Predicate { $0.date >= lower && $0.date <= upper },
                sortBy: [SortDescriptor(\.date)]
            )
            return try context.fetch(descriptor).map(\.domainValue)
        }

        public func addFood(_ entry: FoodEntry, on day: Date) throws {
            let record = try dayRecord(forInserting: day)
            let food = FoodEntryRecord(entry)
            context.insert(food)
            record.food.append(food)
            try context.save()
        }

        public func addBurn(_ entry: BurnEntry, on day: Date) throws {
            let record = try dayRecord(forInserting: day)
            let burn = BurnEntryRecord(entry)
            context.insert(burn)
            record.burn.append(burn)
            try context.save()
        }

        public func removeFood(id: UUID, on day: Date) throws {
            let key = DayBoundary.startOfDay(for: day, in: calendar)
            guard
                let record = try fetchDayRecord(key),
                let index = record.food.firstIndex(where: { $0.id == id })
            else { throw StoreError.entryNotFound(id) }

            let food = record.food.remove(at: index)
            context.delete(food)
            try context.save()
        }

        public func removeBurn(id: UUID, on day: Date) throws {
            let key = DayBoundary.startOfDay(for: day, in: calendar)
            guard
                let record = try fetchDayRecord(key),
                let index = record.burn.firstIndex(where: { $0.id == id })
            else { throw StoreError.entryNotFound(id) }

            let burn = record.burn.remove(at: index)
            context.delete(burn)
            try context.save()
        }

        // MARK: - CheckInStoring

        public func checkIns() throws -> [WeightCheckIn] {
            let descriptor = FetchDescriptor<WeightCheckInRecord>(
                sortBy: [SortDescriptor(\.takenAt)]
            )
            return try context.fetch(descriptor).map(\.domainValue)
        }

        public func add(_ checkIn: WeightCheckIn) throws {
            context.insert(WeightCheckInRecord(checkIn))
            try context.save()
        }

        public func remove(id: UUID) throws {
            let descriptor = FetchDescriptor<WeightCheckInRecord>(
                predicate: #Predicate { $0.id == id }
            )
            guard let record = try context.fetch(descriptor).first else {
                throw StoreError.entryNotFound(id)
            }
            context.delete(record)
            try context.save()
        }

        // MARK: - Private

        private func fetchProfileRecord() throws -> ProfileRecord? {
            var descriptor = FetchDescriptor<ProfileRecord>()
            descriptor.fetchLimit = 1
            return try context.fetch(descriptor).first
        }

        private func fetchDayRecord(_ key: Date) throws -> DayLogRecord? {
            var descriptor = FetchDescriptor<DayLogRecord>(
                predicate: #Predicate { $0.date == key }
            )
            descriptor.fetchLimit = 1
            return try context.fetch(descriptor).first
        }

        /// The record for a day, created if this is the first entry on it.
        private func dayRecord(forInserting day: Date) throws -> DayLogRecord {
            let key = DayBoundary.startOfDay(for: day, in: calendar)
            if let existing = try fetchDayRecord(key) { return existing }

            let record = DayLogRecord(date: key)
            context.insert(record)
            return record
        }
    }

#endif
