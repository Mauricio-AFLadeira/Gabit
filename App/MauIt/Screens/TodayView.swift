import MauItKit
import SwiftUI

/// Screens 02 and 05 — the same Today screen in its two states. One number
/// owns the screen; burn is credited as a separate arc, never folded into
/// intake; red appears only once the budget is genuinely exceeded.
struct TodayView: View {
    @State private var day: DayLog = MockData.onTrackDay
    var onLogFood: () -> Void
    var onLogBurn: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, Metrics.screenGutter)
                    .padding(.bottom, 4)

                RadialProgressRing(
                    consumedFraction: day.consumedFraction,
                    burnFraction: day.burnFraction,
                    isOverBudget: day.isOverBudget,
                    centerValue: centerValue,
                    centerLabel: day.isOverBudget ? "kcal over target" : "kcal remaining"
                )
                .padding(.vertical, 22)

                statRow
                    .padding(.bottom, day.isOverBudget ? 22 : 14)

                if day.isOverBudget {
                    insightCard.padding(.horizontal, Metrics.screenGutter).padding(.bottom, 22)
                } else {
                    macroCard.padding(.horizontal, Metrics.screenGutter).padding(.bottom, 22)
                }

                entriesSection
                    .padding(.horizontal, Metrics.screenGutter)
                    .padding(.bottom, 18)

                actionRow
                    .padding(.horizontal, Metrics.screenGutter)
            }
            .padding(.top, 66)
            .padding(.bottom, 40)
        }
        .background(Palette.canvas)
    }

    private var centerValue: String {
        day.isOverBudget
            ? SignedFormatting.integer(-day.remainingCalories)
            : "\(day.remainingCalories)"
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("Today")
                .font(Typography.largeTitle)
                .foregroundStyle(Palette.ink)
            Spacer()
            Button {
                day = day.isOverBudget ? MockData.onTrackDay : MockData.overBudgetDay
            } label: {
                Text(day.weekdayLabel)
                    .font(.system(size: 11.5, design: .monospaced))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.inkSoft)
            }
        }
    }

    private var statRow: some View {
        HStack(spacing: 22) {
            statLabel("eaten", "\(day.eatenCalories)", Palette.ink)
            Text("\u{00B7}").foregroundStyle(Palette.hairline)
            statLabel("burn", SignedFormatting.integer(day.burnCalories), day.burnCalories > 0 ? Palette.amberText : Palette.inkSoft)
            Text("\u{00B7}").foregroundStyle(Palette.hairline)
            statLabel("target", "\(day.targetCalories)", Palette.ink)
        }
        .font(.system(size: 11, design: .monospaced))
        .foregroundStyle(Palette.textTertiary)
    }

    private func statLabel(_ label: String, _ value: String, _ valueColor: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
            Text(value).fontWeight(.semibold).foregroundStyle(valueColor).tabularNumbers()
        }
    }

    private var macroCard: some View {
        HStack(spacing: 18) {
            MacroBar(title: "Protein", current: day.proteinGrams, target: day.proteinTarget, color: Palette.macroProtein)
            MacroBar(title: "Carbs", current: day.carbsGrams, target: day.carbsTarget, color: Palette.macroCarbs)
            MacroBar(title: "Fat", current: day.fatGrams, target: day.fatTarget, color: Palette.macroFat)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Palette.surface)
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let note = day.insightNote {
                Text(note)
                    .font(.system(size: 16))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider().background(Palette.hairlineSoft)
            HStack(spacing: 10) {
                OutlineButton(title: "Log a workout", height: 44, cornerRadius: 12, action: onLogBurn)
                OutlineButton(title: "Review entries", height: 44, cornerRadius: 12, action: {})
            }
        }
        .padding(18)
        .background(Palette.surface)
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline) {
                Text(day.isOverBudget ? "Largest entries" : "\(day.entries.count) entries")
                    .monoLabelStyle()
                    .foregroundStyle(Palette.inkSoft)
                Spacer()
                if !day.isOverBudget {
                    Button("Repeat yesterday") {}
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.greenText)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(day.entries.enumerated()), id: \.element.id) { index, entry in
                    FoodEntryRow(entry: entry)
                    if index < day.entries.count - 1 {
                        Divider().background(Palette.hairlineSoft).padding(.leading, 16)
                    }
                }
            }
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.hairline, lineWidth: 1))
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            PrimaryButton(title: "Log food", action: onLogFood)
            IconSquareButton(systemGlyph: "\u{2191}", action: onLogBurn)
        }
    }
}
