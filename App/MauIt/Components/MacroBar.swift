import SwiftUI

/// One macro's progress — hue is the only thing distinguishing protein,
/// carbs and fat, and the label is always alongside it, never hue alone.
struct MacroBar: View {
    let title: String
    let current: Int
    let target: Int
    let color: Color

    private var fraction: Double {
        guard target > 0 else { return 0 }
        return min(1, max(0, Double(current) / Double(target)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .monoLabelStyle(tracking: 1)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Palette.inkSoft)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.hairlineSoft)
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * fraction)
                }
            }
            .frame(height: 5)

            Text("\(current) / \(target) g")
                .font(.system(size: 13))
                .foregroundStyle(Palette.textSecondary)
                .tabularNumbers()
        }
    }
}
