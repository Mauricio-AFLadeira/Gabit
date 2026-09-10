import MauItKit
import SwiftUI

/// One radio row on the onboarding goal screen. Selected state gets a
/// filled dot, a green border and the doc's soft focus ring.
struct GoalOptionRow: View {
    let direction: GoalDirection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.clear : Palette.controlBorder, lineWidth: 1.5)
                        .background(Circle().fill(isSelected ? Palette.green : Color.clear))
                    if isSelected {
                        Circle().fill(Color.white).frame(width: 8, height: 8)
                    }
                }
                .frame(width: 22, height: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(direction.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Text(direction.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.inkSoft)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .background(Palette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Palette.green : Palette.hairline, lineWidth: 1.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Palette.green.opacity(isSelected ? 0.12 : 0), lineWidth: 3)
                .padding(-1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .buttonStyle(.plain)
    }
}
