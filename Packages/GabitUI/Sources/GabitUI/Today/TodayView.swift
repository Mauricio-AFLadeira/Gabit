import GabitDomain
import SwiftUI

/// Today: one number owns the screen.
///
/// The over-budget state is this same view — the design's screen 05 is not a
/// different screen, it is Today with `isOverBudget` set. Red is the only thing
/// that changes, plus the reassurance line and a pair of offered actions. That
/// is the whole point of resolving state in the view model: the branch is one
/// boolean, not a second screen to keep in sync.
public struct TodayView: View {

    /// Addressed by the smoke test. Kept here so the test and the view cannot
    /// drift apart silently.
    public static let heroIdentifier = "today.hero"

    // A plain stored property is enough: @Observable tracks the properties
    // body reads, and this view needs no two-way binding.
    private let model: TodayViewModel
    private let onLogFood: () -> Void
    private let onLogBurn: () -> Void

    public init(
        model: TodayViewModel,
        onLogFood: @escaping () -> Void,
        onLogBurn: @escaping () -> Void
    ) {
        self.model = model
        self.onLogFood = onLogFood
        self.onLogBurn = onLogBurn
    }

    private var heroTint: Color {
        model.isOverBudget ? Palette.overBudget : Palette.ink
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Palette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Layout.Space.md) {
                    header
                    hero
                    if let reassurance = model.reassurance {
                        reassuranceCard(reassurance)
                    }
                    macroCard
                    entriesCard
                    Color.clear.frame(height: Layout.actionBarClearance)
                }
                .gabitGutter()
                .padding(.top, Layout.Space.xs)
            }

            actionBar
        }
        .onAppear { model.refresh() }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Today")
                .font(Typography.largeTitle)
                .foregroundStyle(Palette.ink)
            Spacer()
            Text(model.dateLabel)
                .gabitLabelStyle()
        }
        .padding(.top, Layout.Space.sm)
    }

    private var hero: some View {
        VStack(spacing: Layout.Space.md) {
            HeroFigure(
                value: model.heroValue,
                caption: model.heroCaption,
                tint: heroTint,
                accessibilityLabel: model.heroAccessibilityLabel,
                identifier: TodayView.heroIdentifier
            )

            HStack(spacing: Layout.Space.sm) {
                ForEach(model.ledger) { chip in
                    HStack(spacing: Layout.Space.xxs) {
                        Text(chip.label)
                            .gabitLabelStyle()
                        Text(chip.value)
                            .font(Typography.mono(12))
                            .foregroundStyle(Palette.ink)
                            .gabitTabularNumerals()
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(.vertical, Layout.Space.xl)
        .gabitCard()
    }

    private func reassuranceCard(_ text: String) -> some View {
        Text(text)
            .font(Typography.secondary)
            .foregroundStyle(Palette.ink)
            .fixedSize(horizontal: false, vertical: true)
            .gabitCard()
    }

    private var macroCard: some View {
        VStack(alignment: .leading, spacing: Layout.Space.md) {
            ForEach(model.macros) { macro in
                MacroBar(macro)
            }
        }
        .gabitCard()
    }

    private var entriesCard: some View {
        VStack(alignment: .leading, spacing: Layout.Space.xs) {
            HStack {
                SectionLabel(model.entryCountLabel)
                Spacer()
                if model.canRepeatYesterday {
                    Button("Repeat yesterday") { model.repeatYesterday() }
                        .font(Typography.mono(11))
                        .foregroundStyle(Palette.fuel)
                        .gabitHitTarget()
                }
            }

            ForEach(model.entries) { entry in
                EntryRow(entry)
                if entry.id != model.entries.last?.id {
                    Divider().overlay(Palette.hairline)
                }
            }

            if model.entries.isEmpty {
                Text("Nothing logged yet. The first entry takes about five seconds.")
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkSoft)
                    .padding(.vertical, Layout.Space.xs)
            }
        }
        .gabitCard()
    }

    private var actionBar: some View {
        HStack(spacing: Layout.Space.sm) {
            PrimaryButton("Log food", action: onLogFood)
            Button(action: onLogBurn) {
                Text("↑")
                    .font(Typography.rowTitle)
                    .foregroundStyle(Palette.burn)
                    .frame(width: Layout.minimumHitTarget, height: Layout.minimumHitTarget)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.Radius.control)
                            .strokeBorder(Palette.hairline, lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: Layout.Radius.control)
                                    .fill(Palette.surface)
                            )
                    )
            }
            .accessibilityLabel("Log a workout")
        }
        .gabitGutter()
        .padding(.vertical, Layout.Space.sm)
        .background(Palette.canvas.opacity(0.96))
    }
}
