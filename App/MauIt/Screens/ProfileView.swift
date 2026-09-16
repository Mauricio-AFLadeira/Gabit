import SwiftUI

/// What "Profile" in the side menu opens — a read-only look at the account
/// behind the session (name, email, phone), sourced straight from the
/// `AuthUser` the backend returned at login/register. No editing yet: there's
/// no `PATCH /auth/me` for it to call.
struct ProfileView: View {
    var user: AuthUser?
    var onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                navRow.padding(.bottom, 30)

                if let user {
                    VStack(spacing: 16) {
                        field(label: "Name", value: user.name)
                        field(label: "Email", value: user.email)
                        if let phone = user.phone, !phone.isEmpty {
                            field(label: "Phone", value: phone)
                        }
                    }
                } else {
                    Text("No profile loaded.")
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.textTertiary)
                }
            }
            .padding(.horizontal, Metrics.screenGutter)
            .padding(.top, 66)
            .padding(.bottom, 40)
        }
        .background(Palette.canvas)
    }

    private var navRow: some View {
        HStack {
            Text("Profile")
                .font(Typography.largeTitle)
                .foregroundStyle(Palette.ink)
            Spacer()
            Button("Done", action: onDone)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.ink)
        }
    }

    private func field(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).monoLabelStyle().foregroundStyle(Palette.inkSoft)
            Text(value)
                .font(Typography.body)
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: Metrics.minHitTarget)
                .padding(.horizontal, 14)
                .background(Palette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                        .stroke(Palette.hairline, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous))
        }
    }
}
