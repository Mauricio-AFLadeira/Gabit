import SwiftUI

import GabitDomain

/// Quick add. The recent strip is the point of the screen — everything below it
/// is for food that is not a repeat.
public struct QuickAddView: View {

    @Bindable private var model: QuickAddViewModel
    private let onDismiss: () -> Void

    @FocusState private var nameFocused: Bool

    public init(model: QuickAddViewModel, onDismiss: @escaping () -> Void) {
        self.model = model
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Palette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Layout.Space.md) {
                    nameField
                    energyField
                    slotPicker
                    macroFields
                    suggestionStrip
                    Color.clear.frame(height: Layout.actionBarClearance)
                }
                .gabitGutter()
            }

            keypad
        }
        .safeAreaInset(edge: .top) { toolbar }
        .onAppear {
            model.refresh()
            nameFocused = true
        }
    }

    // MARK: - Pieces

    private var toolbar: some View {
        HStack {
            Button("Cancel") { onDismiss() }
                .font(Typography.body)
                .foregroundStyle(Palette.inkSoft)
                .gabitHitTarget()

            Spacer()
            Text("Log food")
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Palette.ink)
            Spacer()

            Button("Save") {
                if model.save() { onDismiss() }
            }
            .font(Typography.body.weight(.semibold))
            .foregroundStyle(model.canSave ? Palette.fuel : Palette.inkSoft)
            .disabled(!model.canSave)
            .gabitHitTarget()
        }
        .gabitGutter()
        .padding(.vertical, Layout.Space.xs)
        .background(Palette.canvas)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: Layout.Space.xs) {
            SectionLabel("What")
            TextField("Greek yoghurt, 200 g", text: $model.name)
                .font(Typography.body)
                .foregroundStyle(Palette.ink)
                .focused($nameFocused)
                .frame(minHeight: Layout.minimumHitTarget)
        }
        .gabitCard()
    }

    private var energyField: some View {
        VStack(alignment: .leading, spacing: Layout.Space.xs) {
            SectionLabel("Energy")
            HStack(alignment: .firstTextBaseline, spacing: Layout.Space.xs) {
                Text(model.energyDisplay.isEmpty ? "0" : model.energyDisplay)
                    .font(Typography.hero)
                    .foregroundStyle(model.energyDisplay.isEmpty ? Palette.inkSoft : Palette.ink)
                    .gabitTabularNumerals()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("kcal")
                    .gabitLabelStyle()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Energy, \(model.energyDisplay.isEmpty ? "none" : model.energyDisplay) kilocalories")
        }
        .gabitCard()
    }

    private var slotPicker: some View {
        PillPicker(
            options: MealSlot.allCases,
            selection: $model.slot,
            title: \.displayName
        )
    }

    private var macroFields: some View {
        HStack(spacing: Layout.Space.xs) {
            macroField("P", text: $model.proteinDigits, tint: Palette.Macro.protein)
            macroField("C", text: $model.carbsDigits, tint: Palette.Macro.carbs)
            macroField("F", text: $model.fatDigits, tint: Palette.Macro.fat)
        }
    }

    private func macroField(_ letter: String, text: Binding<String>, tint: Color) -> some View {
        HStack(spacing: Layout.Space.xxs) {
            Text(letter)
                .font(Typography.mono(11))
                .foregroundStyle(tint)
            TextField("0", text: text)
                .font(Typography.mono(13))
                .foregroundStyle(Palette.ink)
                .gabitTabularNumerals()
        }
        .padding(.horizontal, Layout.Space.sm)
        .frame(maxWidth: .infinity, minHeight: Layout.minimumHitTarget)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Layout.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.Radius.control)
                .strokeBorder(Palette.hairline, lineWidth: 1)
        )
        .accessibilityLabel("\(letter) grams")
    }

    private var suggestionStrip: some View {
        VStack(alignment: .leading, spacing: Layout.Space.xs) {
            SectionLabel("Recent — tap to log as is")

            ForEach(model.suggestions) { suggestion in
                Button {
                    model.logSuggestion(id: suggestion.id)
                    onDismiss()
                } label: {
                    HStack {
                        Text(suggestion.name)
                            .font(Typography.body)
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                        Spacer(minLength: Layout.Space.xs)
                        Text(suggestion.kcal)
                            .font(Typography.mono(12))
                            .foregroundStyle(Palette.inkSoft)
                            .gabitTabularNumerals()
                    }
                    .frame(minHeight: Layout.minimumHitTarget)
                }
                .accessibilityLabel(suggestion.accessibilityLabel)

                if suggestion.id != model.suggestions.last?.id {
                    Divider().overlay(Palette.hairline)
                }
            }

            if model.suggestions.isEmpty {
                Text("Foods you log will show up here for one-tap repeats.")
                    .font(Typography.secondary)
                    .foregroundStyle(Palette.inkSoft)
            }
        }
        .gabitCard()
    }

    @ViewBuilder
    private var keypad: some View {
        #if canImport(UIKit)
            KeypadInputView { key in
                switch key {
                case .digit(let value): model.appendDigit(value)
                case .double: model.doubleEnergy()
                case .delete: model.deleteDigit()
                }
            }
            .frame(height: Layout.minimumHitTarget * 4 + Layout.Space.xs * 5)
        #else
            EmptyView()
        #endif
    }
}
