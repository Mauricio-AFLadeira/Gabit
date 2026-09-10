import MauItKit
import SwiftUI

/// Screen 01 — the one onboarding screen where the domain shows itself:
/// pick a direction, pick a rate, and the target is derived, never typed.
struct OnboardingGoalView: View {
    var onContinue: () -> Void

    @State private var direction: GoalDirection = MockData.defaultDirection
    @State private var ratePerWeek: Double = MockData.defaultRatePerWeek

    private var dailyTarget: Int {
        EnergyMath.dailyTarget(
            maintenance: MockData.maintenanceCalories,
            direction: direction,
            ratePerWeek: ratePerWeek
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                stepIndicator
                    .padding(.bottom, 26)

                Text("What are you\nworking toward?")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(-0.6)
                    .lineSpacing(4)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 8)

                Text("You can change this any time — the daily target recalculates itself.")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textTertiary)
                    .padding(.bottom, 28)

                VStack(spacing: 10) {
                    ForEach(GoalDirection.allCases) { option in
                        GoalOptionRow(direction: option, isSelected: option == direction) {
                            direction = option
                        }
                    }
                }
                .padding(.bottom, 30)

                rateSection
                    .padding(.bottom, 24)

                targetCard
                    .padding(.bottom, 16)

                PrimaryButton(title: "Continue", action: onContinue)
            }
            .padding(.horizontal, Metrics.screenGutter)
            .padding(.top, 70)
            .padding(.bottom, 40)
        }
        .background(Palette.canvas)
    }

    private var stepIndicator: some View {
        HStack(spacing: 5) {
            ForEach(0..<4) { index in
                Capsule()
                    .fill(index < 3 ? Palette.green : Palette.hairline)
                    .frame(height: 3)
            }
        }
    }

    private var rateSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Rate")
                .monoLabelStyle()
                .foregroundStyle(Palette.inkSoft)
                .padding(.bottom, 12)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(String(format: "%.2f", ratePerWeek))
                    .font(.system(size: 34, weight: .semibold))
                    .tracking(-0.5)
                    .tabularNumbers()
                    .foregroundStyle(Palette.ink)
                Text("kg / week")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Palette.textTertiary)
            }
            .padding(.bottom, 14)

            RateSlider(value: $ratePerWeek, range: MockData.minRatePerWeek...MockData.maxRatePerWeek)
                .padding(.bottom, 8)

            HStack {
                Text("gentle")
                Spacer()
                Text("aggressive")
            }
            .font(.system(size: 10.5, design: .monospaced))
            .foregroundStyle(Palette.inkSoft)
        }
    }

    private var targetCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your daily target")
                .monoLabelStyle(tracking: 1)
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.inkSoft)

            HStack(alignment: .lastTextBaseline, spacing: 7) {
                Text("\(dailyTarget)")
                    .font(.system(size: 28, weight: .semibold))
                    .tracking(-0.5)
                    .tabularNumbers()
                    .foregroundStyle(Palette.ink)
                Text("kcal")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Palette.textTertiary)
                Spacer()
                Text("maintenance \(MockData.maintenanceCalories)")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.inkSoft)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Palette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// A custom track + thumb rather than the system `Slider`, to match the
/// doc's pill track and floating disc thumb exactly.
private struct RateSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    private var fraction: Double {
        (value - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.hairline).frame(height: 5)
                Capsule().fill(Palette.green).frame(width: width * fraction, height: 5)
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(Palette.controlBorder, lineWidth: 1))
                    .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
                    .frame(width: 28, height: 28)
                    .offset(x: width * fraction - 14)
            }
            .frame(height: 44)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { drag in
                    let newFraction = min(1, max(0, drag.location.x / width))
                    value = range.lowerBound + newFraction * (range.upperBound - range.lowerBound)
                }
            )
        }
        .frame(height: 44)
    }
}
