import SwiftUI

/// Sign-in — email and password against `POST /auth/login`.
struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    var onSwitchToRegister: () -> Void

    @State private var email = ""
    @State private var password = ""

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !viewModel.isLoading
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Welcome back")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(-0.6)
                    .foregroundStyle(Palette.ink)
                    .padding(.bottom, 8)

                Text("Log in to pick up where you left off.")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textTertiary)
                    .padding(.bottom, 30)

                VStack(spacing: 16) {
                    LabeledTextField(
                        label: "Email",
                        placeholder: "you@example.com",
                        text: $email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        autocapitalization: .never
                    )
                    LabeledTextField(
                        label: "Password",
                        placeholder: "Your password",
                        text: $password,
                        isSecure: true,
                        textContentType: .password,
                        autocapitalization: .never
                    )
                }
                .padding(.bottom, 20)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.redText)
                        .padding(.bottom, 16)
                }

                PrimaryButton(title: viewModel.isLoading ? "Logging in\u{2026}" : "Log in") {
                    Task { await viewModel.login(email: email, password: password) }
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.5)
                .padding(.bottom, 16)

                Button(action: onSwitchToRegister) {
                    Text("Don\u{2019}t have an account? ")
                        .foregroundStyle(Palette.textTertiary)
                        + Text("Sign up").foregroundStyle(Palette.ink).fontWeight(.semibold)
                }
                .font(.system(size: 14))
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, Metrics.screenGutter)
            .padding(.top, 90)
            .padding(.bottom, 40)
        }
        .background(Palette.canvas)
        .scrollDismissesKeyboard(.interactively)
    }
}
