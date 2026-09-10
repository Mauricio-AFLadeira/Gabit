import Foundation

/// The app never uses a bare ASCII hyphen for a negative number — every
/// signed figure (burn credit, over-budget delta, weight change, average
/// balance) gets an explicit `+` or a typographic minus.
public enum SignedFormatting {

    public static func integer(_ value: Int) -> String {
        value < 0 ? "\u{2212}\(abs(value))" : "+\(value)"
    }

    public static func decimal(_ value: Double, fractionDigits: Int = 1) -> String {
        let magnitude = String(format: "%.\(fractionDigits)f", abs(value))
        return value < 0 ? "\u{2212}\(magnitude)" : "+\(magnitude)"
    }
}
