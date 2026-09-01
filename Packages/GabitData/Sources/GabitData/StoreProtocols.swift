import Foundation

import GabitDomain

/// What can go wrong at the persistence boundary.
///
/// Deliberately small: the domain has no error cases of its own, and a store
/// that reports twenty kinds of failure pushes decisions into the view that
/// belong here.
public enum StoreError: Error, Equatable {

    /// An entry was asked for by id and is not in the store.
    case entryNotFound(UUID)

    /// The underlying store failed for a reason it described itself.
    case underlying(String)
}

/// Reads and writes the user's profile.
///
/// `@MainActor` rather than `Sendable`: SwiftData's `ModelContext` is not
/// sendable, and the whole app touches these stores from the main actor
/// anyway. Isolating the protocol keeps that fact visible instead of
/// scattering `@MainActor` over every conforming type.
@MainActor
public protocol ProfileStoring {

    /// The stored profile, or nil before onboarding has run.
    func loadProfile() throws -> Profile?

    func save(_ profile: Profile) throws
}

/// Reads and writes daily logs.
///
/// Days are addressed by any instant within them; conforming types normalise to
/// local midnight with `DayBoundary` so callers never have to.
@MainActor
public protocol DayLogStoring {

    /// The log for the day containing `day`. Never nil — an untouched day is an
    /// empty log, which is what every caller wants anyway.
    func log(on day: Date) throws -> DayLog

    /// Logs for every day in the range that has one, oldest first.
    func logs(from start: Date, to end: Date) throws -> [DayLog]

    func addFood(_ entry: FoodEntry, on day: Date) throws
    func addBurn(_ entry: BurnEntry, on day: Date) throws
    func removeFood(id: UUID, on day: Date) throws
    func removeBurn(id: UUID, on day: Date) throws
}

/// Reads and writes weight readings.
@MainActor
public protocol CheckInStoring {

    /// Every reading, oldest first.
    func checkIns() throws -> [WeightCheckIn]

    func add(_ checkIn: WeightCheckIn) throws
    func remove(id: UUID) throws
}

/// The three stores the app needs, gathered so the composition root can pass
/// one value around instead of three.
@MainActor
public protocol GabitStore: ProfileStoring, DayLogStoring, CheckInStoring {}
