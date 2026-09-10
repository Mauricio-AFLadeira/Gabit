import MauItKit
import SwiftUI

/// Screen 03 — the UIKit interop screen. A custom numeric keypad, wrapped in
/// `UIViewRepresentable`, is what makes logging a two-tap job.
struct LogFoodView: View {
    var onCancel: () -> Void
    var onSave: () -> Void

    @State private var selectedMeal: MealType = .breakfast
    @State private var energyDigits = "148"
    @State private var multiplierActive = false

    private var energyValue: Int {
        let typed = Int(energyDigits) ?? 0
        return multiplierActive ? typed * 2 : typed
    }

    var body: some View {
        VStack(spacing: 0) {
            navRow
                .padding(.horizontal, Metrics.screenGutter)
                .padding(.bottom, 22)

            foodCard
                .padding(.horizontal, Metrics.screenGutter)
                .padding(.bottom, 20)

            mealTypeRow
                .padding(.horizontal, Metrics.screenGutter)
                .padding(.bottom, 12)

            recentSection
                .padding(.horizontal, Metrics.screenGutter)
                .padding(.bottom, 14)

            Spacer(minLength: 0)

            NumericKeypad(digits: $energyDigits, multiplierActive: $multiplierActive)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 66)
        .background(Palette.canvas)
    }

    private var navRow: some View {
        HStack {
            Button("Cancel", action: onCancel)
                .font(.system(size: 17))
                .foregroundStyle(Palette.inkSoft)
            Spacer()
            Text("Log food")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.ink)
            Spacer()
            Button("Save", action: onSave)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(energyDigits.isEmpty ? Palette.disabled : Palette.ink)
                .disabled(energyDigits.isEmpty)
        }
    }

    private var foodCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("What").monoLabelStyle().foregroundStyle(Palette.inkSoft)
                Text("Greek yoghurt, 200 g").font(.system(size: 17)).foregroundStyle(Palette.ink)
            }
            Divider().background(Palette.hairlineSoft)
            VStack(alignment: .leading, spacing: 4) {
                Text("Energy").monoLabelStyle().foregroundStyle(Palette.inkSoft)
                HStack(alignment: .lastTextBaseline, spacing: 7) {
                    Text("\(energyValue)")
                        .font(.system(size: 40, weight: .semibold))
                        .tracking(-1.2)
                        .tabularNumbers()
                        .foregroundStyle(Palette.ink)
                    Rectangle().fill(Palette.green).frame(width: 2, height: 34)
                    Text("kcal")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Palette.textTertiary)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Palette.surface)
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var mealTypeRow: some View {
        HStack(spacing: 8) {
            ForEach(MealType.allCases) { meal in
                SegmentedPill(title: meal.label, isSelected: meal == selectedMeal, height: 38) {
                    selectedMeal = meal
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Recent \u{2014} tap to log as is").monoLabelStyle().foregroundStyle(Palette.inkSoft)
            FlowLayout(spacing: 8) {
                ForEach(MockData.recentQuickAdds) { item in
                    Button {
                        energyDigits = "\(item.calories)"
                        onSave()
                    } label: {
                        HStack(spacing: 8) {
                            Text(item.title).font(.system(size: 14)).foregroundStyle(Palette.ink)
                            Text("\(item.calories)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Palette.inkSoft)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                    }
                    .background(Palette.surface)
                    .overlay(Capsule().stroke(Palette.hairline, lineWidth: 1))
                    .clipShape(Capsule())
                }
            }
        }
    }
}

/// A simple wrapping row, since the recent-item chips don't fit one line.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var rowHeight: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
