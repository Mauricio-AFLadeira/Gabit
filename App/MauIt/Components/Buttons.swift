import SwiftUI

/// The doc's dark, full-width call to action — "Continue", "Log food".
struct PrimaryButton: View {
    let title: String
    var height: CGFloat = 52
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.bodyEmphasized)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: height)
        }
        .background(Palette.ink)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
    }
}

/// A white card with a hairline (or, for the strong variant, an ink) border
/// — "Add weight check-in", "Log a workout", "Review entries".
struct OutlineButton: View {
    let title: String
    var height: CGFloat = 52
    var cornerRadius: CGFloat = Metrics.cardRadius
    var strong = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(strong ? Typography.bodyEmphasized : .system(size: 15, weight: .semibold))
                .foregroundStyle(strong ? Palette.ink : Palette.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: height)
        }
        .background(Palette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(strong ? Palette.ink : Palette.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// The square icon button next to the primary CTA on the Today screen — a
/// manual burn entry.
struct IconSquareButton: View {
    let systemGlyph: String
    var tint: Color = Palette.amberText
    var size: CGFloat = 52
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(systemGlyph)
                .font(.system(size: 20))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
        }
        .background(Palette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous)
                .stroke(Palette.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cardRadius, style: .continuous))
    }
}

/// A pill that's either the dark selected state or a hairline-bordered
/// unselected one — meal-type chips, the progress time-range tabs.
struct SegmentedPill: View {
    let title: String
    let isSelected: Bool
    var height: CGFloat = 38
    var font: Font = .system(size: 14)
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(isSelected ? font.weight(.semibold) : font)
                .foregroundStyle(isSelected ? .white : Palette.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: height)
        }
        .background(isSelected ? Palette.ink : Palette.surface)
        .overlay(
            Capsule().stroke(isSelected ? Color.clear : Palette.hairline, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}
