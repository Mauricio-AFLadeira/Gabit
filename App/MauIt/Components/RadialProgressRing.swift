import SwiftUI

/// The Today screen's donut: a thick outer arc for calories consumed (net of
/// burn), a thin inner arc crediting burn back separately — it is never
/// folded into the intake figure — and a hero number in the center.
struct RadialProgressRing: View {
    let consumedFraction: Double
    let burnFraction: Double
    let isOverBudget: Bool
    let centerValue: String
    let centerLabel: String

    private let diameter: CGFloat = 236
    private let outerStrokeWidth: CGFloat = 14
    private let innerStrokeWidth: CGFloat = 5
    private let innerInset: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.hairline, lineWidth: outerStrokeWidth)

            Circle()
                .trim(from: 0, to: isOverBudget ? 1 : consumedFraction)
                .stroke(
                    isOverBudget ? Palette.red : Palette.green,
                    style: StrokeStyle(lineWidth: outerStrokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            if !isOverBudget && burnFraction > 0 {
                Circle()
                    .trim(from: 0, to: burnFraction)
                    .stroke(Palette.amber, style: StrokeStyle(lineWidth: innerStrokeWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(innerInset)
            }

            VStack(spacing: 2) {
                Text(centerValue)
                    .font(Typography.heroFigure())
                    .tracking(-1.9)
                    .tabularNumbers()
                    .foregroundStyle(isOverBudget ? Palette.redText : Palette.ink)
                Text(centerLabel)
                    .monoLabelStyle()
                    .foregroundStyle(Palette.inkSoft)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}
