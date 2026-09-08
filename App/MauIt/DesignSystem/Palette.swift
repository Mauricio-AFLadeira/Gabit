import SwiftUI

/// Every color the five screens use, named the way the foundations doc
/// names them. Neutrals are literal hex (the doc specifies them that way);
/// everything else is OKLCH, computed by `Color(oklchL:c:h:)`.
enum Palette {

    // MARK: Neutrals — warm, low chroma

    static let canvas = Color(hex: 0xF6_F5F0)
    static let surface = Color(hex: 0xFF_FFFF)
    static let hairline = Color(hex: 0xE3_E1D8)
    static let hairlineSoft = Color(hex: 0xED_ECE5)
    static let inkSoft = Color(hex: 0x8A_8A7E)
    static let ink = Color(hex: 0x1A_1A16)

    // Text tones seen across the screens that sit between `ink` and `inkSoft`.
    static let textSecondary = Color(hex: 0x55_554D)
    static let textTertiary = Color(hex: 0x6E_6E62)
    static let controlBorder = Color(hex: 0xD3_D1C6)
    static let disabled = Color(hex: 0xD3_D1C6)

    // Numeric keypad tray — a slightly darker neutral shelf than the canvas.
    static let keypadTray = Color(hex: 0xE6_E4DB)
    static let keypadTrayBorder = Color(hex: 0xD9_D7CD)
    static let keypadKeyBorder = Color(hex: 0xDD_DBD1)
    static let keypadFunctionKey = Color(hex: 0xDE_DCD2)

    // MARK: Semantic — one lightness, one chroma, hue does the talking

    /// Fuel / on track. Also the color for protein and the weight trend line.
    static let green = Color(oklchL: 0.55, c: 0.11, h: 155)
    static let greenText = Color(oklchL: 0.48, c: 0.10, h: 155)
    static let greenTextHover = Color(oklchL: 0.40, c: 0.11, h: 155)
    static let greenIcon = Color(oklchL: 0.44, c: 0.09, h: 155)
    static let greenTint = Color(oklchL: 0.94, c: 0.03, h: 155)

    /// Burn / credited.
    static let amber = Color(oklchL: 0.62, c: 0.11, h: 65)
    static let amberText = Color(oklchL: 0.52, c: 0.11, h: 65)
    static let amberIcon = Color(oklchL: 0.48, c: 0.10, h: 65)
    static let amberTint = Color(oklchL: 0.95, c: 0.03, h: 65)

    /// Over budget — the only screen allowed to use it.
    static let red = Color(oklchL: 0.55, c: 0.13, h: 25)
    static let redText = Color(oklchL: 0.48, c: 0.13, h: 25)
    static let redIcon = Color(oklchL: 0.46, c: 0.11, h: 25)
    static let redTint = Color(oklchL: 0.95, c: 0.03, h: 25)

    // MARK: Macros — hue-only distinction, never labels alone

    static let macroProtein = green
    static let macroCarbs = Color(oklchL: 0.65, c: 0.10, h: 80)
    static let macroFat = Color(oklchL: 0.58, c: 0.11, h: 25)
}

extension Color {
    /// Convenience for the doc's literal hex neutrals — `0xRRGGBB`.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
