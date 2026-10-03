import SwiftUI

struct ForgotPasswordView: View {
    @StateObject var viewModel: ForgotPasswordViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDone = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Forgot password?").font(.title.bold())

                switch viewModel.step {
                case .enterEmail:
                    Text("Enter your registered email. We'll send you an OTP.")
                        .multilineTextAlignment(.center).foregroundColor(.secondary)
                    FormField(title: "Email", text: $viewModel.email, error: viewModel.errors["email"],
                              keyboard: .emailAddress, contentType: .emailAddress)
                    errorText
                    PrimaryButton(title: "Send OTP", isLoading: viewModel.isLoading) {
                        Task { await viewModel.sendOTP() }
                    }

                case .resetPassword:
                    Text("Enter the OTP sent to \(viewModel.email) and choose a new password.")
                        .multilineTextAlignment(.center).foregroundColor(.secondary)
                    FormField(title: "OTP", text: $viewModel.otp, error: viewModel.errors["otp"],
                              keyboard: .numberPad, contentType: .oneTimeCode)
                    FormField(title: "New password", text: $viewModel.newPassword,
                              error: viewModel.errors["password"], isSecure: true, contentType: .newPassword)
                    FormField(title: "Confirm new password", text: $viewModel.confirmPassword,
                              error: viewModel.errors["confirm"], isSecure: true)
                    errorText
                    PrimaryButton(title: "Reset password", isLoading: viewModel.isLoading) {
                        Task { await viewModel.resetPassword() }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Reset password")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(viewModel.$state) { if $0 == .done { showDone = true } }
        .alert("Password changed", isPresented: $showDone) {
            Button("Login") { dismiss() }
        } message: {
            Text("You can now login with your new password.")
        }
    }

    @ViewBuilder
    private var errorText: some View {
        if case .failure(let message) = viewModel.state {
            Text(message).font(.footnote).foregroundColor(.red).multilineTextAlignment(.center)
        }
    }
}
