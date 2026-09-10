import MauItKit
import SwiftUI

/// One row in the entries list: a tinted glyph avatar, title, a mono detail
/// line, and a trailing calorie figure — colored and signed for a burn
/// credit, plain for a meal.
struct FoodEntryRow: View {
    let entry: FoodEntry

    private var glyph: String {
        switch entry.kind {
        case .meal(let meal): return meal.glyph
        case .exercise: return "\u{2191}"
        }
    }

    private var avatarTint: (background: Color, foreground: Color) {
        switch entry.kind {
        case .meal(.breakfast), .meal(.lunch), .meal(.snack):
            return (Palette.greenTint, Palette.greenIcon)
        case .meal(.dinner):
            return (Palette.redTint, Palette.redIcon)
        case .exercise:
            return (Palette.amberTint, Palette.amberIcon)
        }
    }

    private var detail: String {
        if let macros = entry.macros {
            return "\(entry.time) \u{00B7} P\(macros.proteinGrams) C\(macros.carbsGrams) F\(macros.fatGrams)"
        }
        return "\(entry.time) \u{00B7} manual estimate"
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(glyph)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(avatarTint.foreground)
                .frame(width: 34, height: 34)
                .background(avatarTint.background)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                Text(detail)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Palette.inkSoft)
            }

            Spacer(minLength: 8)

            Text(entry.kind == .exercise ? SignedFormatting.integer(entry.calories) : "\(entry.calories)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(entry.kind == .exercise ? Palette.amberText : Palette.ink)
                .tabularNumbers()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
