import GabitDomain
import SwiftUI

/// Onboarding. Two steps, of which the second is the one that matters.
public struct OnboardingView: View {

    @Bindable private var model: OnboardingViewModel
    private let onFinish: () -> Void

    public init(model: OnboardingViewModel, onFinish: @escaping () -> Void) {
        self.model = model
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Layout.Space.lg) {
                    switch model.step {
                    case .measurements: measurements
                    case .goal: goal
                    }
                }
                .gabitGutter()
                .padding(.vertical, Layout.Space.xl)
            }
        }
    }

    // MARK: - Step one

    private var measurements: some View {
        VStack(alignment: .leading, spacing: Layout.Space.lg) {
            Text("A few numbers,\nthen we do the maths.")
                .font(Typography.largeTitle)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("These feed the formula behind your daily target. Nothing leaves the phone.")
                .font(Typography.secondary)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: Layout.Space.md) {
                // Two cases, because the equation has two coefficients. The copy
                // says so rather than leaving the user to wonder what is being
                // asserted about them.
                labelled("Sex", note: "The energy equation has one coefficient for each.") {
                    PillPicker(
                        options: Sex.allCases,
                        selection: $model.sex,
                        title: { $0 == .female ? "Female" : "Male" }
                    )
                }

                labelled("Date of birth") {
                    DatePicker(
                        "Date of birth",
                        selection: $model.birthDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .frame(minHeight: Layout.minimumHitTarget)
                }

                labelled("Height") {
                    stepperRow(
                        value: $model.heightCm,
                        range: 120...220,
                        step: 1,
                        unit: "cm",
                        format: { String(format: "%.0f", $0) }
                    )
                }

                labelled("Weight") {
                    stepperRow(
                        value: $model.weightKg,
                        range: 35...250,
                        step: 0.5,
                        unit: "kg",
                        format: { String(format: "%.1f", $0) }
                    )
                }

                labelled("Activity") {
                    PillPicker(
                        options: Activity.allCases,
                        selection: $model.activity,
                        title: \.shortTitle
                    )
                }
            }
            .gabitCard(padding: Layout.Space.lg)

            PrimaryButton("Continue") { model.advance() }
        }
    }

    private func labelled<Content: View>(
        _ title: String,
        note: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.Space.xs) {
            SectionLabel(title)
            content()
            if let note {
                Text(note)
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func stepperRow(
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        unit: String,
        format: @escaping (Double) -> String
    ) -> some View {
        HStack {
            Text(format(value.wrappedValue))
                .font(Typography.rowTitle)
                .foregroundStyle(Palette.ink)
                .gabitTabularNumerals()
            Text(unit)
                .gabitLabelStyle()
            Spacer()
            Stepper(unit, value: value, in: range, step: step)
                .labelsHidden()
        }
        .frame(minHeight: Layout.minimumHitTarget)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(format(value.wrappedValue)) \(unit)")
    }

    // MARK: - Step two

    private var goal: some View {
        VStack(alignment: .leading, spacing: Layout.Space.lg) {
            Text("What are you\nworking toward?")
                .font(Typography.largeTitle)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("You can change this any time — the daily target recalculates itself.")
                .font(Typography.secondary)
                .foregroundStyle(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: Layout.Space.xs) {
                ForEach(GoalChoice.allCases) { choice in
                    choiceRow(choice)
                }
            }

            if model.choice.offersRateChoice {
                rateCard
            }

            targetCard

            ForEach(model.warnings, id: \.self) { warning in
                Text(warning)
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .gabitCard()
            }

            HStack(spacing: Layout.Space.sm) {
                SecondaryButton("Back") { model.back() }
                PrimaryButton("Continue") {
                    if model.finish() { onFinish() }
                }
            }
        }
    }

    private func choiceRow(_ choice: GoalChoice) -> some View {
        let isSelected = model.choice == choice
        return Button {
            model.choice = choice
        } label: {
            HStack(alignment: .top, spacing: Layout.Space.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(choice.title)
                        .font(Typography.rowTitle)
                        .foregroundStyle(Palette.ink)
                    Text(choice.subtitle)
                        .font(Typography.secondary)
                        .foregroundStyle(Palette.inkSoft)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: Layout.Space.xs)
                Circle()
                    .strokeBorder(isSelected ? Palette.fuel : Palette.hairline, lineWidth: 2)
                    .background(Circle().fill(isSelected ? Palette.fuel : Color.clear))
                    .frame(width: 20, height: 20)
                    .padding(.top, 2)
            }
            .padding(Layout.Space.md)
            .frame(maxWidth: .infinity, minHeight: Layout.minimumHitTarget, alignment: .leading)
            .background(
                isSelected ? Palette.fuelTint : Palette.surface,
                in: RoundedRectangle(cornerRadius: Layout.Radius.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.Radius.card)
                    .strokeBorder(isSelected ? Palette.fuel : Palette.hairline, lineWidth: 1)
            )
        }
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityLabel("\(choice.title). \(choice.subtitle)")
    }

    private var rateCard: some View {
        VStack(alignment: .leading, spacing: Layout.Space.xs) {
            SectionLabel("Rate")

            HStack(alignment: .firstTextBaseline, spacing: Layout.Space.xs) {
                Text(model.rateDisplay)
                    .font(Typography.rowTitle)
                    .foregroundStyle(Palette.ink)
                    .gabitTabularNumerals()
                Text("kg / week")
                    .gabitLabelStyle()
            }

            Slider(
                value: $model.rateKgPerWeek,
                in: model.rateRange,
                step: 0.05
            )
            .tint(Palette.fuel)
            .accessibilityLabel("Rate in kilograms per week")
            .accessibilityValue(model.rateDisplay)

            HStack {
                Text("gentle").gabitLabelStyle()
                Spacer()
                Text("aggressive").gabitLabelStyle()
            }
        }
        .gabitCard()
    }

    private var targetCard: some View {
        VStack(spacing: Layout.Space.xxs) {
            SectionLabel("Your daily target")
            HStack(alignment: .firstTextBaseline, spacing: Layout.Space.xs) {
                Text(model.targetDisplay)
                    .font(Typography.hero)
                    .foregroundStyle(Palette.ink)
                    .gabitTabularNumerals()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("kcal")
                    .gabitLabelStyle()
            }
            Text(model.maintenanceDisplay)
                .font(Typography.mono(11))
                .foregroundStyle(Palette.inkSoft)
                .gabitTabularNumerals()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Layout.Space.lg)
        .gabitCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.targetAccessibilityLabel)
    }
}

extension Activity {

    /// Short enough to fit five pills across an iPhone.
    var shortTitle: String {
        switch self {
        case .sedentary: "Still"
        case .light: "Light"
        case .moderate: "Some"
        case .high: "High"
        case .athlete: "Athlete"
        }
    }
}
