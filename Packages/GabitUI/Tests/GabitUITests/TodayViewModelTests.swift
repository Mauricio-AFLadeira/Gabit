import XCTest

import GabitData
import GabitDomain

@testable import GabitUI

/// Asserts the resolved state, not the view output. What a screen draws is the
/// snapshot tests' problem; what it is told to draw is this file's.
@MainActor
final class TodayViewModelTests: XCTestCase {

    private func makeModel(
        logs: [DayLog] = [],
        profile: Profile? = UIFixtures.profile(),
        at instant: Date = UIFixtures.now
    ) -> (TodayViewModel, InMemoryStore) {
        let store = UIFixtures.store(profile: profile, logs: logs)
        let model = TodayViewModel(
            store: store,
            clock: UIFixtures.clock(at: instant),
            formatting: UIFixtures.formatting()
        )
        return (model, store)
    }

    private func designDay() -> DayLog {
        DayLog(
            date: UIFixtures.date(2026, 9, 6),
            food: [
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
            ],
            burn: [
                BurnEntry(
                    kind: .workout,
                    name: "Lifting, 62 min",
                    kcal: 240,
                    occurredAt: UIFixtures.date(2026, 9, 6, 18)
                )
            ]
        )
    }

    func test_hero_showsRemainingEnergy_matchingTheDesignScreen() {
        let (model, _) = makeModel(logs: [designDay()])
        model.refresh()

        XCTAssertEqual(model.heroValue, "795")
        XCTAssertEqual(model.heroCaption, "kcal remaining")
        XCTAssertFalse(model.isOverBudget)
    }

    func test_ledger_reportsEatenBurnAndTargetSeparately() {
        let (model, _) = makeModel(logs: [designDay()])
        model.refresh()

        XCTAssertEqual(model.ledger.map(\.label), ["eaten", "burn", "target"])
        XCTAssertEqual(model.ledger.map(\.value), ["1,625", "+240", "2,180"])
    }

    func test_hero_switchesToOverBudget_whenTheDayExceedsItsAllowance() {
        let over = DayLog(
            date: UIFixtures.date(2026, 9, 6),
            food: [UIFixtures.food("Pizza, all of it", 2490, at: UIFixtures.date(2026, 9, 6, 20))]
        )
        let (model, _) = makeModel(logs: [over])
        model.refresh()

        XCTAssertTrue(model.isOverBudget)
        XCTAssertEqual(model.heroValue, "+310")
        XCTAssertEqual(model.heroCaption, "kcal over target")
    }

    func test_reassurance_appearsOnlyWhenOverBudgetAndTheWeekIsStillInDeficit() {
        var logs: [DayLog] = (1...5).map { day in
            DayLog(
                date: UIFixtures.date(2026, 9, day),
                food: [UIFixtures.food("Steady", 1700, at: UIFixtures.date(2026, 9, day, 12))]
            )
        }
        logs.append(
            DayLog(
                date: UIFixtures.date(2026, 9, 6),
                food: [UIFixtures.food("Too much", 2490, at: UIFixtures.date(2026, 9, 6, 20))]
            )
        )

        let (model, _) = makeModel(logs: logs)
        model.refresh()

        let reassurance = model.reassurance
        XCTAssertNotNil(reassurance)
        XCTAssertTrue(reassurance?.contains("7-day average") == true)
    }

    func test_reassurance_isAbsent_whenTheDayIsWithinBudget() {
        let (model, _) = makeModel(logs: [designDay()])
        model.refresh()
        XCTAssertNil(model.reassurance, "a tracker that always says it is fine is not worth trusting")
    }

    func test_entries_areOrderedByTimeAndCarryTheirSlotBadge() {
        let (model, _) = makeModel(logs: [designDay()])
        model.refresh()

        XCTAssertEqual(model.entries.map(\.badge), ["B", "L", "S", "↑"])
        XCTAssertEqual(model.entryCountLabel, "4 entries")
    }

    func test_burnRow_showsACreditRatherThanACost() {
        let (model, _) = makeModel(logs: [designDay()])
        model.refresh()

        let burn = model.entries.last
        XCTAssertEqual(burn?.kind, .burn)
        XCTAssertEqual(burn?.value, "+240")
    }

    func test_entryCountLabel_isSingularForOneEntry() {
        let single = DayLog(
            date: UIFixtures.date(2026, 9, 6),
            food: [UIFixtures.food("Only thing", 400, at: UIFixtures.date(2026, 9, 6, 9))]
        )
        let (model, _) = makeModel(logs: [single])
        model.refresh()
        XCTAssertEqual(model.entryCountLabel, "1 entry")
    }

    func test_macros_areMeasuredAgainstDerivedTargets() {
        let (model, _) = makeModel(logs: [designDay()])
        model.refresh()

        XCTAssertEqual(model.macros.map(\.kind), [.protein, .carbs, .fat])
        XCTAssertEqual(model.macros.first?.value, "104 / 152 g")
        for macro in model.macros {
            XCTAssertTrue((0...1).contains(macro.fraction))
        }
    }

    func test_repeatYesterday_isOfferedOnlyWhenYesterdayHasFood() {
        let (empty, _) = makeModel()
        empty.refresh()
        XCTAssertFalse(empty.canRepeatYesterday)

        let yesterday = DayLog(
            date: UIFixtures.date(2026, 9, 5),
            food: [UIFixtures.food("Oats", 520, at: UIFixtures.date(2026, 9, 5, 8))]
        )
        let (model, _) = makeModel(logs: [yesterday])
        model.refresh()
        XCTAssertTrue(model.canRepeatYesterday)
    }

    func test_repeatYesterday_copiesTheEntriesOntoToday() {
        let yesterday = DayLog(
            date: UIFixtures.date(2026, 9, 5),
            food: [
                UIFixtures.food("Oats", 520, slot: .breakfast, at: UIFixtures.date(2026, 9, 5, 8)),
                UIFixtures.food("Bowl", 735, slot: .lunch, at: UIFixtures.date(2026, 9, 5, 13)),
            ]
        )
        let (model, store) = makeModel(logs: [yesterday])
        model.refresh()

        model.repeatYesterday()

        let today = try? store.log(on: UIFixtures.now)
        XCTAssertEqual(today?.food.count, 2)
        XCTAssertEqual(model.entries.count, 2, "and the screen already reflects it")
    }

    func test_deleteEntry_removesItAndRefreshes() throws {
        let (model, _) = makeModel(logs: [designDay()])
        model.refresh()
        let first = try XCTUnwrap(model.entries.first)

        model.deleteEntry(id: first.id, kind: .food)

        XCTAssertFalse(model.entries.contains { $0.id == first.id })
    }

    func test_withoutAProfile_theScreenIsEmptyRatherThanWrong() {
        let (model, _) = makeModel(profile: nil)
        model.refresh()

        XCTAssertTrue(model.ledger.isEmpty)
        XCTAssertTrue(model.entries.isEmpty)
        XCTAssertFalse(model.isOverBudget)
    }

    func test_dateLabel_comesFromTheClock_notFromNow() {
        let (model, _) = makeModel(at: UIFixtures.date(2026, 9, 6, 18))
        model.refresh()
        XCTAssertTrue(model.dateLabel.contains("Sun"), "got \(model.dateLabel)")
    }
}
