import SwiftUI

/// The small pieces every screen is assembled from.
///
/// They exist so that the radius, the hairline and the label treatment are
/// decided once. A screen that needs a card reaches for `gabitCard()`; it does
/// not draw a rounded rectangle of its own.

/// The mono, uppercase, letter-spaced section label.
public struct SectionLabel: View {

    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .gabitLabelStyle()
            .accessibilityAddTraits(.isHeader)
    }
}

/// The one number that owns a screen, with its unit beneath.
public struct HeroFigure: View {

    private let value: String
    private let caption: String
    private let tint: Color
    private let accessibilityLabel: String
    private let identifier: String

    public init(
        value: String,
        caption: String,
        tint: Color,
        accessibilityLabel: String,
        identifier: String
    ) {
        self.value = value
        self.caption = caption
        self.tint = tint
        self.accessibilityLabel = accessibilityLabel
        self.identifier = identifier
    }

    public var body: some View {
        VStack(spacing: Layout.Space.xxs) {
            Text(value)
                .font(Typography.hero)
                .tracking(-1.9)  // −0.03em at 64pt
                .foregroundStyle(tint)
                .gabitTabularNumerals()
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(caption)
                .gabitLabelStyle()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        // Merging the figure and its caption into one element makes it an
        // "other" element rather than a static text, so a UI test cannot find
        // it by label alone. The identifier is how it is addressed, and it does
        // not change when the copy does.
        .accessibilityIdentifier(identifier)
    }
}

/// One macro's label, figure and bar.
///
/// The bar is never the only carrier of meaning — the name and the numbers sit
/// beside it, which is what the foundations sheet means by "hue-only
/// distinction, never labels alone".
public struct MacroBar: View {

    private let state: MacroRowState

    public init(_ state: MacroRowState) {
        self.state = state
    }

    private var tint: Color {
        switch state.kind {
        case .protein: Palette.Macro.protein
        case .carbs: Palette.Macro.carbs
        case .fat: Palette.Macro.fat
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Layout.Space.xs) {
            HStack {
                Text(state.name)
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: Layout.Space.xs)
                Text(state.value)
                    .font(Typography.mono(12))
                    .foregroundStyle(Palette.inkSoft)
                    .gabitTabularNumerals()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Palette.hairline)
                    Capsule()
                        .fill(tint)
                        .frame(width: geometry.size.width * state.fraction)
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state.accessibilityLabel)
    }
}

/// A row in the day's entry list.
public struct EntryRow: View {

    private let state: EntryRowState

    public init(_ state: EntryRowState) {
        self.state = state
    }

    private var badgeTint: Color {
        state.kind == .burn ? Palette.burn : Palette.fuel
    }

    public var body: some View {
        HStack(spacing: Layout.Space.sm) {
            Text(state.badge)
                .font(Typography.mono(11))
                .foregroundStyle(badgeTint)
                .frame(width: 26, height: 26)
                .background(Palette.fuelTint.opacity(state.kind == .burn ? 0 : 1), in: Circle())
                .overlay(Circle().strokeBorder(badgeTint.opacity(0.35), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(state.title)
                    .font(Typography.body)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(2)
                Text(state.detail)
                    .font(Typography.mono(11))
                    .foregroundStyle(Palette.inkSoft)
                    .gabitTabularNumerals()
            }

            Spacer(minLength: Layout.Space.xs)

            Text(state.value)
                .font(Typography.rowTitle)
                .foregroundStyle(state.kind == .burn ? Palette.burn : Palette.ink)
                .gabitTabularNumerals()
        }
        .padding(.vertical, Layout.Space.xs)
        .frame(minHeight: Layout.minimumHitTarget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state.accessibilityLabel)
    }
}

/// The filled action at the bottom of a screen.
public struct PrimaryButton: View {

    private let title: String
    private let tint: Color
    private let action: () -> Void

    public init(_ title: String, tint: Color = Palette.fuel, action: @escaping () -> Void) {
        self.title = title
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Palette.surface)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Layout.minimumHitTarget)
                .background(tint, in: RoundedRectangle(cornerRadius: Layout.Radius.control))
        }
    }
}

/// The outlined action beside it.
public struct SecondaryButton: View {

    private let title: String
    private let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.body)
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .frame(minHeight: Layout.minimumHitTarget)
                .background(
                    RoundedRectangle(cornerRadius: Layout.Radius.control)
                        .strokeBorder(Palette.hairline, lineWidth: 1)
                )
        }
    }
}

/// A row of mutually exclusive pills — meal slots, chart ranges.
///
/// Every pill clears the 44-point minimum whatever its label's length.
public struct PillPicker<Value: Hashable>: View {

    private let options: [Value]
    private let title: (Value) -> String
    @Binding private var selection: Value

    public init(
        options: [Value],
        selection: Binding<Value>,
        title: @escaping (Value) -> String
    ) {
        self.options = options
        self._selection = selection
        self.title = title
    }

    public var body: some View {
        HStack(spacing: Layout.Space.xs) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    selection = option
                } label: {
                    Text(title(option))
                        .font(Typography.secondary)
                        .foregroundStyle(isSelected ? Palette.surface : Palette.ink)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: Layout.minimumHitTarget)
                        .background(
                            isSelected ? Palette.fuel : Palette.surface,
                            in: RoundedRectangle(cornerRadius: Layout.Radius.pill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.Radius.pill)
                                .strokeBorder(
                                    isSelected ? Color.clear : Palette.hairline,
                                    lineWidth: 1
                                )
                        )
                }
                .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
            }
        }
    }
}
