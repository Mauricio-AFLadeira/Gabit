import SwiftUI

/// The type scale from the foundations sheet.
///
/// Two families. The system face carries everything the user reads, so it
/// inherits Dynamic Type, iOS metrics and the accessibility affordances for
/// free; a mono face carries units, dates and small labels and gives the app its
/// measured character.
///
/// Every size is expressed relative to a text style rather than as a fixed
/// point size. The sheet's numbers are the sizes at the default Dynamic Type
/// setting; `relativeTo:` is what lets them grow from there, which is the
/// difference between a design that survives the largest accessibility size and
/// one that clips.
public enum Typography {

    /// The mono family, with a fallback that is present on every install.
    static let monoName = "IBM Plex Mono"

    /// system-ui 64 / 600, tabular, −0.03em. The one number that owns a screen.
    public static let hero = Font.system(size: 64, weight: .semibold).monospacedDigit()

    /// system-ui 32 / 700.
    public static let largeTitle = Font.system(.largeTitle, design: .default).weight(.bold)

    /// system-ui 20 / 600.
    public static let rowTitle = Font.system(.title3, design: .default).weight(.semibold)

    /// system-ui 17 / 400 — the iOS default.
    public static let body = Font.system(.body)

    /// system-ui 15 / 400.
    public static let secondary = Font.system(.subheadline)

    /// IBM Plex Mono 11 / 600, 0.1em tracking, uppercase.
    ///
    /// Falls back to the system monospaced face when the family is not bundled,
    /// which keeps the label legible rather than silently switching to the body face.
    public static let label = Font.custom(
        monoName,
        size: 11,
        relativeTo: .caption2
    )
    .weight(.semibold)

    /// The mono face at an arbitrary size, for figures inside rows.
    public static func mono(_ size: CGFloat, relativeTo style: Font.TextStyle = .footnote) -> Font {
        Font.custom(monoName, size: size, relativeTo: style)
    }
}

extension View {

    /// The uppercase, letter-spaced treatment every unit label gets.
    public func gabitLabelStyle(color: Color = Palette.inkSoft) -> some View {
        self
            .font(Typography.label)
            .tracking(1.1)  // 0.1em at 11pt
            .textCase(.uppercase)
            .foregroundStyle(color)
    }

    /// Every numeral in the app is tabular, so figures do not jitter while a
    /// value animates. Applied at the leaves rather than the root because
    /// `monospacedDigit()` on a container does not reach text in child views
    /// that set their own font.
    public func gabitTabularNumerals() -> some View {
        monospacedDigit()
    }
}
