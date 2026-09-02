import SwiftUI

/// Progress.
///
/// Named `ProgressScreen` rather than `ProgressView` because SwiftUI already
/// exports a `ProgressView`, and a file importing both could not write the name
/// unqualified.
public struct ProgressScreen: View {

    @Bindable private var model: ProgressViewModel

    @State private var isAddingCheckIn = false
    @State private var draftWeight = ""

    public init(model: ProgressViewModel) {
        self.model = model
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Palette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Layout.Space.md) {
                    header
                    weightCard
                    if let headline = model.projectionHeadline {
                        projectionCard(headline)
                    }
                    statsCard
                    Color.clear.frame(height: Layout.actionBarClearance)
                }
                .gabitGutter()
                .padding(.top, Layout.Space.xs)
            }

            PrimaryButton("Add weight check-in") { isAddingCheckIn = true }
                .gabitGutter()
                .padding(.vertical, Layout.Space.sm)
                .background(Palette.canvas.opacity(0.96))
        }
        .onAppear { model.refresh() }
        .sheet(isPresented: $isAddingCheckIn) { checkInSheet }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: Layout.Space.sm) {
            Text("Progress")
                .font(Typography.largeTitle)
                .foregroundStyle(Palette.ink)

            PillPicker(
                options: TrendRange.allCases,
                selection: $model.range,
                title: \.title
            )
        }
        .padding(.top, Layout.Space.sm)
    }

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: Layout.Space.md) {
            HStack(alignment: .firstTextBaseline, spacing: Layout.Space.xs) {
                Text(model.currentWeight)
                    .font(Typography.hero)
                    .foregroundStyle(Palette.ink)
                    .gabitTabularNumerals()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("kg")
                    .gabitLabelStyle()
                Spacer()
                Text(model.changeSummary)
                    .font(Typography.mono(12))
                    .foregroundStyle(Palette.inkSoft)
                    .gabitTabularNumerals()
            }

            Text("7-day average")
                .gabitLabelStyle()

            TrendChart(points: model.points, axisLabels: model.axisLabels)
        }
        .gabitCard()
    }

    private func projectionCard(_ headline: String) -> some View {
        VStack(alignment: .leading, spacing: Layout.Space.xs) {
            SectionLabel("Projection")
            Text(headline)
                .font(Typography.body)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let footnote = model.projectionFootnote {
                Text(footnote)
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .gabitCard()
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: Layout.Space.md) {
            SectionLabel("Adherence")
            HStack(alignment: .top) {
                ForEach(model.stats) { stat in
                    VStack(spacing: Layout.Space.xxs) {
                        Text(stat.value)
                            .font(Typography.rowTitle)
                            .foregroundStyle(Palette.ink)
                            .gabitTabularNumerals()
                        Text(stat.caption)
                            .gabitLabelStyle()
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(stat.accessibilityLabel)
                }
            }
        }
        .gabitCard()
    }

    private var checkInSheet: some View {
        VStack(alignment: .leading, spacing: Layout.Space.lg) {
            Text("Today's weight")
                .font(Typography.largeTitle)
                .foregroundStyle(Palette.ink)

            TextField("78.4", text: $draftWeight)
                .font(Typography.hero)
                .foregroundStyle(Palette.ink)
                .gabitTabularNumerals()
                .frame(minHeight: Layout.minimumHitTarget)
                .gabitCard()
                .accessibilityLabel("Weight in kilograms")

            PrimaryButton("Save") {
                // A comma is what most of the world types; accept it rather than
                // silently discarding the reading.
                let normalised = draftWeight.replacingOccurrences(of: ",", with: ".")
                if let value = Double(normalised), value > 0 {
                    model.addCheckIn(weightKg: value)
                }
                draftWeight = ""
                isAddingCheckIn = false
            }

            Spacer()
        }
        .gabitGutter()
        .padding(.top, Layout.Space.xl)
        .background(Palette.canvas)
    }
}
