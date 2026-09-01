import SwiftUI

/// Spacing, radii and hit targets, exactly as the foundations sheet states them.
///
/// Named constants rather than literals scattered through the views: the sheet
/// says "no other values", and that rule is only enforceable if there is one
/// place to look.
public enum Layout {

    /// The 4-point spacing scale. Nothing in the app uses a value that is not
    /// one of these.
    public enum Space {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 20
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
        public static let huge: CGFloat = 40
    }

    /// Corner radii. Three values, per the sheet.
    public enum Radius {
        /// Cards.
        public static let card: CGFloat = 14
        /// Controls: buttons, fields, keypad keys.
        public static let control: CGFloat = 12
        /// Pills and fully rounded chips.
        public static let pill: CGFloat = 999
    }

    /// Fixed screen gutter.
    public static let gutter: CGFloat = Space.lg

    /// The minimum tappable square, including keypad keys and segment controls.
    public static let minimumHitTarget: CGFloat = 44
}

extension View {

    /// The standard card: white surface, hairline border, card radius.
    public func gabitCard(padding: CGFloat = Layout.Space.md) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Layout.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.Radius.card)
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            )
    }

    /// Guarantees the 44×44 minimum without changing how the content draws.
    public func gabitHitTarget() -> some View {
        frame(minWidth: Layout.minimumHitTarget, minHeight: Layout.minimumHitTarget)
            .contentShape(Rectangle())
    }

    /// The fixed screen gutter.
    public func gabitGutter() -> some View {
        padding(.horizontal, Layout.gutter)
    }
}
