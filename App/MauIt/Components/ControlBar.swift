import SwiftUI

/// The top bar every authenticated screen (Today, Progress) sits under —
/// wordmark on the left, the hamburger that opens `SideMenu` on the right.
struct ControlBar: View {
    var title: String = "MauIt"
    var onMenuTap: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .tracking(-0.2)
                .foregroundStyle(Palette.ink)

            Spacer()

            Button(action: onMenuTap) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .frame(width: Metrics.minHitTarget, height: Metrics.minHitTarget)
            }
        }
        .padding(.horizontal, Metrics.screenGutter)
        .frame(height: 52)
        .background(Palette.canvas)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.hairlineSoft).frame(height: 1)
        }
    }
}
