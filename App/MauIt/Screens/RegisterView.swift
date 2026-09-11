import SwiftUI

/// Sign-up — name, email, password and an optional phone number, against
/// `POST /auth/register`.
struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel
    var onSwitchToLogin: () -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""

    private var canSubmit: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 8 && !viewModel.isLoading
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Create your account")
                    .font(.system(size: 32, weight: .bold))
                    .tracking(-0.6)
                    .lineSpacing(4)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 8)

                Text("Just enough to keep your log yours.")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.textTertiary)
                    .padding(.bottom, 30)

                VStack(spacing: 16) {
                    LabeledTextField(
                        label: "Name",
                        placeholder: "Your name",
                        text: $name,
                        textContentType: .name
                    )
                    LabeledTextField(
                        label: "Email",
                        placeholder: "you@example.com",
                        text: $email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        autocapitalization: .never
                    )
                    LabeledTextField(
                        label: "Phone (optional)",
                        placeholder: "+1 555 000 0000",
                        text: $phone,
                        keyboardType: .phonePad,
                        textContentType: .telephoneNumber
                    )
                    LabeledTextField(
                        label: "Password",
                        placeholder: "At least 8 characters",
                        text: $password,
                        isSecure: true,
                        textContentType: .newPassword,
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

                PrimaryButton(title: viewModel.isLoading ? "Creating account\u{2026}" : "Create account") {
                    let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
                    Task {
                        await viewModel.register(
                            name: name,
                            email: email,
                            password: password,
                            phone: trimmedPhone.isEmpty ? nil : trimmedPhone
                        )
                    }
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.5)
                .padding(.bottom, 16)

                Button(action: onSwitchToLogin) {
                    Text("Already have an account? ")
                        .foregroundStyle(Palette.textTertiary)
                        + Text("Log in").foregroundStyle(Palette.ink).fontWeight(.semibold)
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
