#if canImport(UIKit)

    import SnapshotTesting
    import SwiftUI
    import XCTest

    import GabitData
    import GabitDomain

    @testable import GabitUI

    /// The accessibility regression net from plan §5.
    ///
    /// Six baselines: Today, quick add and the over-budget state, each at the
    /// default Dynamic Type size and at the largest accessibility size. The
    /// second of each pair is the one that earns its keep — clipped text at
    /// `accessibilityExtraExtraExtraLarge` is the failure these catch, and it is
    /// the failure nobody notices by hand.
    ///
    /// Light only: the foundations sheet specifies `iPhone · light only · v0.1`,
    /// which narrows plan §5's "light and dark" to one scheme for this version.
    /// Dark comes back with a dark palette, and doubles this file.
    final class SnapshotTests: XCTestCase {

        /// Flip to true, run once, flip back to re-record every baseline.
        private let recording = false

        private let device = ViewImageConfig.iPhone13

        override func invokeTest() {
            withSnapshotTesting(record: recording ? .all : .missing) {
                super.invokeTest()
            }
        }

        // MARK: - Fixtures

        @MainActor
        private func todayModel(over: Bool = false) -> TodayViewModel {
            let food: [FoodEntry] =
                over
                ? [
                    UIFixtures.food(
                        "Pizza, half",
                        910,
                        slot: .dinner,
                        macros: Macros(proteinG: 38, carbsG: 96, fatG: 34),
                        at: UIFixtures.date(2026, 9, 6, 20)
                    ),
                    UIFixtures.food(
                        "Chicken & rice bowl",
                        735,
                        slot: .lunch,
                        macros: Macros(proteinG: 62, carbsG: 60, fatG: 18),
                        at: UIFixtures.date(2026, 9, 6, 13)
                    ),
                    UIFixtures.food("Earlier", 845, slot: .breakfast, at: UIFixtures.date(2026, 9, 6, 8)),
                ]
                : [
                    UIFixtures.food(
                        "Oats, whey, banana",
                        520,
                        slot: .breakfast,
                        macros: Macros(proteinG: 42, carbsG: 68, fatG: 9),
                        at: UIFixtures.date(2026, 9, 6, 8)
                    ),
                    UIFixtures.food(
                        "Chicken & rice bowl",
                        735,
                        slot: .lunch,
                        macros: Macros(proteinG: 62, carbsG: 60, fatG: 18),
                        at: UIFixtures.date(2026, 9, 6, 13)
                    ),
                    UIFixtures.food("Snacks", 370, slot: .snack, at: UIFixtures.date(2026, 9, 6, 16)),
                ]

            let burn =
                over
                ? []
                : [
                    BurnEntry(
                        kind: .workout,
                        name: "Lifting, 62 min",
                        kcal: 240,
                        occurredAt: UIFixtures.date(2026, 9, 6, 18)
                    )
                ]

            let store = UIFixtures.store(
                logs: [DayLog(date: UIFixtures.date(2026, 9, 6), food: food, burn: burn)]
            )
            let model = TodayViewModel(
                store: store,
                clock: UIFixtures.clock(),
                formatting: UIFixtures.formatting()
            )
            model.refresh()
            return model
        }

        @MainActor
        private func quickAddModel() -> QuickAddViewModel {
            let store = UIFixtures.store(
                logs: [
                    DayLog(
                        date: UIFixtures.date(2026, 9, 5),
                        food: [
                            UIFixtures.food("Oats, whey, banana", 520, at: UIFixtures.date(2026, 9, 5, 8)),
                            UIFixtures.food("Chicken bowl", 735, at: UIFixtures.date(2026, 9, 5, 13)),
                            UIFixtures.food("Coffee, oat milk", 95, at: UIFixtures.date(2026, 9, 5, 7)),
                            UIFixtures.food("Eggs ×3", 215, at: UIFixtures.date(2026, 9, 5, 9)),
                        ]
                    )
                ]
            )
            let model = QuickAddViewModel(
                store: store,
                clock: UIFixtures.clock(),
                formatting: UIFixtures.formatting()
            )
            model.refresh()
            return model
        }

        private func assertBoth(
            _ view: some View,
            named name: String,
            file: StaticString = #filePath,
            testName: String = #function,
            line: UInt = #line
        ) {
            assertSnapshot(
                of: view,
                as: .image(layout: .device(config: device)),
                named: "\(name)-default",
                file: file,
                testName: testName,
                line: line
            )
            assertSnapshot(
                of: view,
                as: .image(
                    layout: .device(config: device),
                    traits: UITraitCollection(
                        preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge
                    )
                ),
                named: "\(name)-axxxl",
                file: file,
                testName: testName,
                line: line
            )
        }

        // MARK: - Baselines

        @MainActor
        func test_today() {
            assertBoth(
                TodayView(model: todayModel(), onLogFood: {}, onLogBurn: {}),
                named: "today"
            )
        }

        @MainActor
        func test_todayOverBudget() {
            assertBoth(
                TodayView(model: todayModel(over: true), onLogFood: {}, onLogBurn: {}),
                named: "today-over-budget"
            )
        }

        @MainActor
        func test_quickAdd() {
            assertBoth(
                QuickAddView(model: quickAddModel(), onDismiss: {}),
                named: "quick-add"
            )
        }
    }

#endif
