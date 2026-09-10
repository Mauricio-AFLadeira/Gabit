import SwiftUI

/// The foundations doc specifies every color as OKLCH — "one lightness, one
/// chroma, hue does the talking" — which SwiftUI has no native initializer
/// for. This reproduces the browser's `oklch()` conversion exactly (via the
/// OKLab intermediate space) instead of eyeballing hex approximations, so
/// the app's palette matches the design source to the bit.
extension Color {

    /// - Parameters:
    ///   - l: Lightness, 0...1.
    ///   - c: Chroma, typically 0...~0.4.
    ///   - h: Hue, in degrees.
    init(oklchL l: Double, c: Double, h: Double) {
        let hueRadians = h * .pi / 180
        let a = c * cos(hueRadians)
        let b = c * sin(hueRadians)

        let l_ = l + 0.3963377774 * a + 0.2158037573 * b
        let m_ = l - 0.1055613458 * a - 0.0638541728 * b
        let s_ = l - 0.0894841775 * a - 1.2914855480 * b

        let l3 = l_ * l_ * l_
        let m3 = m_ * m_ * m_
        let s3 = s_ * s_ * s_

        let rLinear = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3
        let gLinear = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3
        let bLinear = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3

        func gammaEncode(_ x: Double) -> Double {
            let clamped = min(max(x, 0), 1)
            return clamped <= 0.0031308
                ? 12.92 * clamped
                : 1.055 * pow(clamped, 1 / 2.4) - 0.055
        }

        self.init(
            .sRGB,
            red: gammaEncode(rLinear),
            green: gammaEncode(gLinear),
            blue: gammaEncode(bLinear),
            opacity: 1
        )
    }
}
