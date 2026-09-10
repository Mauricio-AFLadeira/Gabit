import MauItKit
import SwiftUI

/// Screen 04 — trend over readings. The projection states its own
/// uncertainty and would disappear entirely once the trend stops
/// supporting one (this prototype's single trend always supports one).
struct ProgressScreenView: View {
    private enum TimeRange: String, CaseIterable, Identifiable {
        case fourWeeks = "4 w"
        case twelveWeeks = "12 w"
        case oneYear = "1 y"
        var id: Self { self }
    }

    var onAddCheckIn: () -> Void

    @State private var range: TimeRange = .twelveWeeks

    private var summary: ProgressSummary { MockData.progressSummary }

    private var visibleReadings: [WeightReading] {
        switch range {
        case .fourWeeks: return Array(summary.readings.suffix(4))
        case .twelveWeeks, .oneYear: return summary.readings
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Progress")
                    .font(Typography.largeTitle)
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, Metrics.screenGutter)
                    .padding(.bottom, 20)

                rangeTabs
                    .padding(.horizontal, Metrics.screenGutter)
                    .padding(.bottom, 10)

                weightCard
                    .padding(.horizontal, Metrics.screenGutter)
                    .padding(.bottom, 14)

                projectionCallout
                    .padding(.horizontal, Metrics.screenGutter)
                    .padding(.bottom, 8)

                adherenceSection
                    .padding(.horizontal, Metrics.screenGutter)
                    .padding(.bottom, 18)

                OutlineButton(title: "Add weight check-in", strong: true, action: onAddCheckIn)
                    .padding(.horizontal, Metrics.screenGutter)
            }
            .padding(.top, 66)
            .padding(.bottom, 40)
        }
        .background(Palette.canvas)
    }

    private var rangeTabs: some View {
        HStack(spacing: 6) {
            ForEach(TimeRange.allCases) { option in
                SegmentedPill(
                    title: option.rawValue,
                    isSelected: option == range,
                    height: 34,
                    font: .system(size: 13.5)
                ) {
                    range = option
                }
            }
        }
    }

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(String(format: "%.1f", summary.currentWeightKg))
                    .font(.system(size: 40, weight: .semibold))
                    .tracking(-1.2)
                    .tabularNumbers()
                    .foregroundStyle(Palette.ink)
                Text("kg")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Palette.textTertiary)
                Spacer()
                Text(summary.deltaLabel)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Palette.greenText)
            }
            .padding(.bottom, 4)

            Text("7-day average")
                .font(.system(size: 10.5, design: .monospaced))
                .tracking(0.7)
                .textCase(.uppercase)
                .foregroundStyle(Palette.inkSoft)
                .padding(.bottom, 16)

            MiniLineChart(values: visibleReadings.map(\.kg))
                .frame(height: 130)
                .padding(.bottom, 6)

            HStack {
                Text(shortDate(visibleReadings.first?.date))
                Spacer()
                Text(shortDate(visibleReadings[safe: visibleReadings.count / 2]?.date))
                Spacer()
                Text(shortDate(visibleReadings.last?.date))
            }
            .font(.system(size: 10, design: .monospaced))
            .foregroundStyle(Palette.inkSoft)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .background(Palette.surface)
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.hairline, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var projectionCallout: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Projection")
                .monoLabelStyle(tracking: 1)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.greenIcon)

            (Text(summary.projection.prefix)
                + Text(summary.projection.emphasis).fontWeight(.bold)
                + Text(summary.projection.suffix))
                .font(.system(size: 16))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(summary.projectionFootnote)
                .font(.system(size: 13))
                .foregroundStyle(Palette.inkSoft)
                .padding(.top, 1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Palette.surface)
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 4, bottomLeadingRadius: 4, bottomTrailingRadius: 14, topTrailingRadius: 14
            )
            .stroke(Palette.hairline, lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            Rectangle().fill(Palette.green).frame(width: 3)
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 4, bottomLeadingRadius: 4, bottomTrailingRadius: 14, topTrailingRadius: 14
            )
        )
    }

    private var adherenceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Adherence").monoLabelStyle().foregroundStyle(Palette.inkSoft)
            HStack {
                statColumn("\(summary.daysLogged)", "days logged")
                Spacer()
                statColumn("\(summary.percentWithinTarget)%", "within target")
                Spacer()
                statColumn(SignedFormatting.integer(summary.averageDailyBalance), "avg. balance")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(Palette.surface)
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func statColumn(_ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 24, weight: .semibold))
                .tabularNumbers()
                .foregroundStyle(Palette.ink)
            Text(caption)
                .font(.system(size: 12.5))
                .foregroundStyle(Palette.inkSoft)
        }
    }

    private func shortDate(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}

extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
