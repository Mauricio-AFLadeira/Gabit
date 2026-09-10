import SwiftUI

/// The doc's two-family system: the system face for anything a user reads
/// (Dynamic Type and every iOS accessibility affordance for free), and a
/// monospaced face for units, dates and small labels. The doc specifies IBM
/// Plex Mono; this ships on the system monospaced design so the app has zero
/// font-loading setup, with the same tabular, data-honest character.
enum Typography {

    /// system-ui 64 / 600, tabular, -0.03em — the hero figure.
    static func heroFigure(_ size: CGFloat = 64) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    /// system-ui 32 / 700 — large title.
    static let largeTitle = Font.system(size: 32, weight: .bold)

    /// system-ui 20 / 600 — row title.
    static let rowTitle = Font.system(size: 20, weight: .semibold)

    /// system-ui 17 / 400 — body, the iOS default.
    static let body = Font.system(size: 17)

    /// system-ui 17 / 600 — body, emphasized (buttons, selected pills).
    static let bodyEmphasized = Font.system(size: 17, weight: .semibold)

    /// system-ui 15 / 400 — secondary copy and captions.
    static let secondary = Font.system(size: 15)

    /// Mono, 11 / 600, 0.1em uppercase — label / unit.
    static let label = Font.system(size: 11, weight: .semibold, design: .monospaced)

    /// Mono, smaller variant for timestamps and inline units.
    static let mono = Font.system(size: 11, weight: .medium, design: .monospaced)
}

/// Uppercase + wide tracking, the treatment every mono label in the doc
/// shares. `0.1em` at typical label sizes lands close to 1pt of tracking.
struct MonoLabelStyle: ViewModifier {
    var tracking: CGFloat = 1.1

    func body(content: Content) -> some View {
        content
            .font(Typography.label)
            .textCase(.uppercase)
            .tracking(tracking)
    }
}

extension View {
    func monoLabelStyle(tracking: CGFloat = 1.1) -> some View {
        modifier(MonoLabelStyle(tracking: tracking))
    }

    /// Every numeral in the app is tabular — figures must not jitter while a
    /// value animates.
    func tabularNumbers() -> some View {
        monospacedDigit()
    }
}
