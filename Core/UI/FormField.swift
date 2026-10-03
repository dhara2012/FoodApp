import SwiftUI

/// Auth screens માટે reusable input + error text
struct FormField: View {
    let title: String
    @Binding var text: String
    var error: String? = nil
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                if isSecure { SecureField(title, text: $text) }
                else { TextField(title, text: $text).keyboardType(keyboard) }
            }
            .textContentType(contentType)
            .textInputAutocapitalization(title == "Full name" ? .words : .never)
            .autocorrectionDisabled()
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(error == nil ? .clear : Color.red, lineWidth: 1))
            .accessibilityIdentifier(title)

            if let error { Text(error).font(.caption).foregroundColor(.red) }
        }
    }
}

struct PrimaryButton: View {
    let title: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading { ProgressView() } else { Text(title).bold() }
        }
        .frame(maxWidth: .infinity, minHeight: 46)
        .buttonStyle(.borderedProminent)
        .disabled(isLoading)
        .accessibilityIdentifier(title)
    }
}
