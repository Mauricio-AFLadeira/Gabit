import SwiftUI
import UIKit

/// A bordered input with a mono label above it, in the same voice as the
/// "What" / "Energy" fields on the quick-add card — just editable, and
/// standing alone rather than grouped inside one card.
struct LabeledTextField: View {
    let label: String
    var placeholder: String = ""
    @Binding var text: String
    var isSecure = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).monoLabelStyle().foregroundStyle(Palette.inkSoft)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(Typography.body)
            .foregroundStyle(Palette.ink)
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .textInputAutocapitalization(autocapitalization)
            .autocorrectionDisabled()
            .frame(height: Metrics.minHitTarget)
            .padding(.horizontal, 14)
            .background(Palette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous)
                    .stroke(Palette.controlBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Metrics.controlRadius, style: .continuous))
        }
    }
}
