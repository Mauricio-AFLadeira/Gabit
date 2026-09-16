import SwiftUI

/// The hamburger's destination: slides in from the right over a dimmed
/// scrim, ~80% of the screen width. Tapping the scrim or swiping the panel
/// away dismisses it — there's no close button, matching how the sheet-style
/// screens in this app already behave (LogFoodView's "Cancel" aside).
struct SideMenu: View {
    var userName: String
    var userEmail: String
    var onSelectProfile: () -> Void
    var onLogout: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let panelWidth = proxy.size.width * 0.8

            ZStack(alignment: .trailing) {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onDismiss)

                panel
                    .frame(width: panelWidth)
                    .frame(maxHeight: .infinity)
                    .background(Palette.surface)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(Palette.hairline).frame(width: 1)
                    }
                    .ignoresSafeArea(edges: .vertical)
                    .gesture(
                        DragGesture(minimumDistance: 12).onEnded { drag in
                            if drag.translation.width > 40 { onDismiss() }
                        }
                    )
            }
        }
    }

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(Typography.rowTitle)
                    .foregroundStyle(Palette.ink)
                Text(userEmail)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.textTertiary)
            }
            .padding(.horizontal, Metrics.screenGutter)
            .padding(.top, 70)
            .padding(.bottom, 22)

            Divider().background(Palette.hairlineSoft)

            SideMenuRow(icon: "person.circle", title: "Profile", action: onSelectProfile)
            Divider().background(Palette.hairlineSoft).padding(.leading, Metrics.screenGutter)
            SideMenuRow(
                icon: "rectangle.portrait.and.arrow.right", title: "Log out", tint: Palette.redText, action: onLogout)

            Spacer()
        }
    }
}

private struct SideMenuRow: View {
    let icon: String
    let title: String
    var tint: Color = Palette.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(tint)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(tint)
                Spacer()
            }
            .padding(.horizontal, Metrics.screenGutter)
            .frame(height: Metrics.minHitTarget + 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
