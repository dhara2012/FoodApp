import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var services: ServiceContainer

    var body: some View {
        ChangePasswordContent(viewModel: ChangePasswordViewModel(repository: services.profile))
    }
}

private struct ChangePasswordContent: View {
    @StateObject var viewModel: ChangePasswordViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDone = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                FormField(title: "Current password", text: $viewModel.current,
                          error: viewModel.errors["current"], isSecure: true, contentType: .password)
                FormField(title: "New password", text: $viewModel.newPassword,
                          error: viewModel.errors["new"], isSecure: true, contentType: .newPassword)
                FormField(title: "Confirm new password", text: $viewModel.confirm,
                          error: viewModel.errors["confirm"], isSecure: true)
                Text("Minimum 8 characters with letters and numbers").font(.caption).foregroundColor(.secondary)

                if case .failure(let message) = viewModel.state {
                    Text(message).font(.footnote).foregroundColor(.red)
                }
                PrimaryButton(title: "Update password", isLoading: viewModel.isSaving) {
                    Task { await viewModel.submit() }
                }
            }
            .padding()
        }
        .navigationTitle("Change password")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(viewModel.$state) { if $0 == .success { showDone = true } }
        .alert("Password updated", isPresented: $showDone) {
            Button("OK") { dismiss() }
        }
    }
}
