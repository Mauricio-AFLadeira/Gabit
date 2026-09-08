import SwiftUI

/// The weight-trend sparkline: three faint gridlines, a rounded polyline
/// normalized to the data's own min/max, and a dot marking the latest point.
struct MiniLineChart: View {
    let values: [Double]
    var color: Color = Palette.green

    private var normalized: [Double] {
        guard let lo = values.min(), let hi = values.max(), hi > lo else {
            return values.map { _ in 0.5 }
        }
        // Higher value draws higher on screen, so invert for SwiftUI's
        // top-left origin.
        return values.map { 1 - (($0 - lo) / (hi - lo)) }
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let points = normalized

            ZStack {
                ForEach([0.1, 0.45, 0.8], id: \.self) { y in
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: height * y))
                        path.addLine(to: CGPoint(x: width, y: height * y))
                    }
                    .stroke(Palette.hairlineSoft, lineWidth: 1)
                }

                if points.count > 1 {
                    Path { path in
                        for (index, value) in points.enumerated() {
                            let point = CGPoint(
                                x: width * CGFloat(index) / CGFloat(points.count - 1),
                                y: height * CGFloat(value)
                            )
                            if index == 0 {
                                path.move(to: point)
                            } else {
                                path.addLine(to: point)
                            }
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    if let last = points.last {
                        Circle()
                            .fill(color)
                            .frame(width: 9, height: 9)
                            .position(x: width, y: height * CGFloat(last))
                    }
                }
            }
        }
    }
}
