import CoreGraphics

/// The doc's rules, verbatim: "Corner radius: 14 for cards, 12 for controls,
/// 999 for pills. No other values. Spacing is a 4-point scale; screen gutter
/// is a fixed 20. Minimum hit target 44×44."
enum Metrics {
    static let cardRadius: CGFloat = 14
    static let controlRadius: CGFloat = 12
    static let pillRadius: CGFloat = 999

    static let screenGutter: CGFloat = 20
    static let minHitTarget: CGFloat = 44

    /// The 4-point spacing scale.
    static let space1: CGFloat = 4
    static let space2: CGFloat = 8
    static let space3: CGFloat = 12
    static let space4: CGFloat = 16
    static let space5: CGFloat = 20
    static let space6: CGFloat = 24
}
