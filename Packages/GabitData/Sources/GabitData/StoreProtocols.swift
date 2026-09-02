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
/// Deliberately not `Sendable` and deliberately not isolated. SwiftData's
/// `ModelContext` is not sendable, so the live store is confined to one
/// isolation domain — but that is a fact about the implementation and the
/// caller, not about the contract. Pinning `@MainActor` here would drag the
/// in-memory fake onto the main actor as well, and with it every test that
/// touches a store, which on Linux breaks XCTest's method discovery outright.
public protocol ProfileStoring {

    /// The stored profile, or nil before onboarding has run.
    func loadProfile() throws -> Profile?

    func save(_ profile: Profile) throws
}

/// Reads and writes daily logs.
///
/// Days are addressed by any instant within them; conforming types normalise to
/// local midnight with `DayBoundary` so callers never have to.
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
public protocol CheckInStoring {

    /// Every reading, oldest first.
    func checkIns() throws -> [WeightCheckIn]

    func add(_ checkIn: WeightCheckIn) throws
    func remove(id: UUID) throws
}

/// The three stores the app needs, gathered so the composition root can pass
/// one value around instead of three.
public protocol GabitStore: ProfileStoring, DayLogStoring, CheckInStoring {}
