import SwiftData
import SwiftUI

import GabitData
import GabitDomain
import GabitUI

/// The composition root, and nothing else.
///
/// This is the one place in the repository that calls `Date()` — by way of
/// `SystemClock` — and the one place that knows a `ModelContainer` exists.
/// Everything downstream receives what it needs through an initialiser, which
/// is what makes "the day rolls over at midnight" a testable behaviour rather
/// than a hope.
@main
struct GabitApp: App {

    private let model: AppModel

    init() {
        let clock = SystemClock()
        let store = Self.makeStore(calendar: clock.calendar)
        model = AppModel(store: store, clock: clock)
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
    }

    /// The live store, falling back to an in-memory one if the container cannot
    /// be opened.
    ///
    /// A tracker that refuses to launch because its database is unreadable is
    /// worse than one that lets you keep logging for the session and shows the
    /// problem later. The fallback is deliberate, and it is the same complete
    /// implementation the tests run against — not a stub.
    @MainActor
    private static func makeStore(calendar: Calendar) -> any GabitStore {
        do {
            let container = try SwiftDataStore.makeContainer()
            return SwiftDataStore(context: ModelContext(container), calendar: calendar)
        } catch {
            assertionFailure("Falling back to an in-memory store: \(error)")
            return InMemoryStore(calendar: calendar)
        }
    }
}
