import GabitData
import GabitDomain
import Observation
import SwiftUI

/// What the app is showing: onboarding until there is a profile, then the tabs.
@MainActor
@Observable
public final class AppModel {

    private let store: any GabitStore
    private let clock: any GabitClock
    private let formatting: Formatting

    public private(set) var hasProfile = false

    public init(
        store: any GabitStore,
        clock: any GabitClock,
        formatting: Formatting = Formatting()
    ) {
        self.store = store
        self.clock = clock
        self.formatting = formatting
        refresh()
    }

    public func refresh() {
        hasProfile = ((try? store.loadProfile()) ?? nil) != nil
    }

    public func makeOnboarding() -> OnboardingViewModel {
        OnboardingViewModel(store: store, clock: clock, formatting: formatting)
    }

    public func makeToday() -> TodayViewModel {
        TodayViewModel(store: store, clock: clock, formatting: formatting)
    }

    public func makeQuickAdd() -> QuickAddViewModel {
        QuickAddViewModel(store: store, clock: clock, formatting: formatting)
    }

    public func makeProgress() -> ProgressViewModel {
        ProgressViewModel(store: store, clock: clock, formatting: formatting)
    }

    /// Logs a burn straight from the Today screen's second action. Small enough
    /// not to deserve a screen of its own on a two-day clock.
    public func logBurn(name: String, kcal: Kcal) {
        try? store.addBurn(
            BurnEntry(kind: .workout, name: name, kcal: kcal, occurredAt: clock.now),
            on: clock.now
        )
    }
}

/// The top of the view tree.
public struct RootView: View {

    private let model: AppModel

    @State private var today: TodayViewModel
    @State private var progress: ProgressViewModel
    @State private var isQuickAdding = false
    @State private var isLoggingBurn = false

    public init(model: AppModel) {
        self.model = model
        _today = State(initialValue: model.makeToday())
        _progress = State(initialValue: model.makeProgress())
    }

    public var body: some View {
        Group {
            if model.hasProfile {
                main
            } else {
                OnboardingView(model: model.makeOnboarding()) {
                    model.refresh()
                    today.refresh()
                }
            }
        }
        .tint(Palette.fuel)
    }

    private var main: some View {
        TabView {
            TodayView(
                model: today,
                onLogFood: { isQuickAdding = true },
                onLogBurn: { isLoggingBurn = true }
            )
            .tabItem { Label("Today", systemImage: "circle.dashed") }

            ProgressScreen(model: progress)
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .sheet(isPresented: $isQuickAdding) {
            QuickAddView(model: model.makeQuickAdd()) {
                isQuickAdding = false
                today.refresh()
            }
        }
        .sheet(isPresented: $isLoggingBurn) {
            BurnSheet { name, kcal in
                model.logBurn(name: name, kcal: kcal)
                isLoggingBurn = false
                today.refresh()
            } onCancel: {
                isLoggingBurn = false
            }
        }
    }
}

/// Logging a workout: a name and an estimate, credited to today's budget.
struct BurnSheet: View {

    let onSave: (String, Kcal) -> Void
    let onCancel: () -> Void

    @State private var name = ""
    @State private var kcalText = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (Double(kcalText) ?? 0) > 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.Space.lg) {
            HStack {
                Button("Cancel", action: onCancel)
                    .foregroundStyle(Palette.inkSoft)
                    .gabitHitTarget()
                Spacer()
                Text("Log a workout")
                    .font(Typography.body.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Button("Save") {
                    onSave(
                        name.trimmingCharacters(in: .whitespacesAndNewlines),
                        Kcal(Double(kcalText) ?? 0)
                    )
                }
                .foregroundStyle(canSave ? Palette.fuel : Palette.inkSoft)
                .disabled(!canSave)
                .gabitHitTarget()
            }

            VStack(alignment: .leading, spacing: Layout.Space.xs) {
                SectionLabel("What")
                TextField("Lifting, 62 min", text: $name)
                    .font(Typography.body)
                    .frame(minHeight: Layout.minimumHitTarget)
            }
            .gabitCard()

            VStack(alignment: .leading, spacing: Layout.Space.xs) {
                SectionLabel("Estimated burn")
                HStack(alignment: .firstTextBaseline, spacing: Layout.Space.xs) {
                    TextField("240", text: $kcalText)
                        .font(Typography.rowTitle)
                        .gabitTabularNumerals()
                    Text("kcal")
                        .gabitLabelStyle()
                }
                .frame(minHeight: Layout.minimumHitTarget)

                // Says out loud what the domain does, so the number is not
                // mistaken for a licence to eat it twice.
                Text("Credited to today's budget. It does not change what you have eaten.")
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .gabitCard()

            Spacer()
        }
        .gabitGutter()
        .padding(.top, Layout.Space.lg)
        .background(Palette.canvas)
    }
}
