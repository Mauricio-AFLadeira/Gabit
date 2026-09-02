import SwiftUI

/// The weight trend, drawn from points the view model already normalised.
///
/// No axis maths, no date handling, no min/max scan — the view model did all of
/// it. The chart's whole job is to turn 0...1 pairs into a path, which is what
/// keeps it snapshot-testable without a store behind it.
public struct TrendChart: View {

    private let points: [TrendPoint]
    private let axisLabels: [String]

    public init(points: [TrendPoint], axisLabels: [String]) {
        self.points = points
        self.axisLabels = axisLabels
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Layout.Space.xs) {
            GeometryReader { geometry in
                let size = geometry.size

                ZStack {
                    if points.count >= 2 {
                        line(in: size)
                            .stroke(
                                Palette.fuel,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                            )

                        fill(in: size)
                            .fill(
                                LinearGradient(
                                    colors: [Palette.fuel.opacity(0.16), Palette.fuel.opacity(0)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        Text("Two readings and the trend appears.")
                            .font(Typography.secondary)
                            .foregroundStyle(Palette.inkSoft)
                    }
                }
            }
            .frame(height: 140)

            if !axisLabels.isEmpty {
                HStack {
                    ForEach(Array(axisLabels.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .gabitLabelStyle()
                        if index != axisLabels.count - 1 { Spacer() }
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weight trend chart, \(points.count) readings")
    }

    /// Y is inverted because a higher weight should sit higher on screen, and
    /// SwiftUI's origin is top-left.
    private func position(_ point: TrendPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: (1 - point.y) * size.height)
    }

    private func line(in size: CGSize) -> Path {
        Path { path in
            for (index, point) in points.enumerated() {
                let location = position(point, in: size)
                if index == 0 {
                    path.move(to: location)
                } else {
                    path.addLine(to: location)
                }
            }
        }
    }

    private func fill(in size: CGSize) -> Path {
        Path { path in
            guard let first = points.first, let last = points.last else { return }
            path.move(to: CGPoint(x: position(first, in: size).x, y: size.height))
            for point in points {
                path.addLine(to: position(point, in: size))
            }
            path.addLine(to: CGPoint(x: position(last, in: size).x, y: size.height))
            path.closeSubpath()
        }
    }
}
