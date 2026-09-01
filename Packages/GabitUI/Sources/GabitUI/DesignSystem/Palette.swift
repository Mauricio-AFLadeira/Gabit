import SwiftUI

/// The palette from the foundations sheet.
///
/// The sheet specifies colours in OKLCH, which SwiftUI cannot express, so each
/// one is converted to sRGB once and recorded here with the OKLCH it came from.
/// Keeping the source values in the comments is what makes the palette
/// re-derivable — the three semantic colours are deliberately at one lightness
/// and one chroma so they carry identical weight on screen, and that property is
/// invisible once you only have hex.
///
/// Light only, per the sheet's `iPhone · light only · v0.1`.
public enum Palette {

    // MARK: - Neutrals (warm, low chroma)

    /// Behind everything. #F6F5F0
    public static let canvas = Color(red: 0.9647, green: 0.9608, blue: 0.9412)

    /// Cards and sheets. #FFFFFF
    public static let surface = Color.white

    /// Separators and card borders. #E3E1D8
    public static let hairline = Color(red: 0.8902, green: 0.8824, blue: 0.8471)

    /// Secondary text, units, captions. #8A8A7E
    public static let inkSoft = Color(red: 0.5412, green: 0.5412, blue: 0.4941)

    /// Primary text. #1A1A16
    public static let ink = Color(red: 0.1020, green: 0.1020, blue: 0.0863)

    // MARK: - Semantic

    /// On track. oklch(0.55 0.11 155)
    public static let fuel = Color(red: 0.1908, green: 0.5180, blue: 0.3310)

    /// Activity credited back to the budget. oklch(0.62 0.11 65)
    public static let burn = Color(red: 0.7030, green: 0.4669, blue: 0.2135)

    /// Reserved. The one colour that appears only when the day's budget is
    /// genuinely exceeded — never for a warning, a validation message or an
    /// aggressive rate. oklch(0.55 0.13 25)
    public static let overBudget = Color(red: 0.6934, green: 0.3066, blue: 0.2882)

    /// A wash of `fuel` for filled pills and selected rows. oklch(0.94 0.03 155)
    public static let fuelTint = Color(red: 0.8639, green: 0.9472, blue: 0.8884)

    // MARK: - Macros

    /// Hue-only distinction, at matched lightness. These are never the sole
    /// carrier of meaning — every macro bar is labelled, per the sheet.
    public enum Macro {

        /// oklch(0.55 0.11 155) — shares the `fuel` hue by design.
        public static let protein = Color(red: 0.1908, green: 0.5180, blue: 0.3310)

        /// oklch(0.65 0.10 80)
        public static let carbs = Color(red: 0.6867, green: 0.5334, blue: 0.2589)

        /// oklch(0.58 0.11 25)
        public static let fat = Color(red: 0.6990, green: 0.3694, blue: 0.3475)
    }
}
