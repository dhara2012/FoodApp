import SwiftUI

struct OTPView: View {
    @StateObject var viewModel: OTPViewModel
    @EnvironmentObject var session: SessionManager

    var body: some View {
        VStack(spacing: 16) {
            Text("Verify your email").font(.title.bold())
            Text("Enter the 6-digit code sent to\n\(viewModel.email)")
                .multilineTextAlignment(.center).foregroundColor(.secondary)

            FormField(title: "OTP", text: $viewModel.otp, error: viewModel.otpError,
                      keyboard: .numberPad, contentType: .oneTimeCode)

            if case .failure(let message) = viewModel.state {
                Text(message).font(.footnote).foregroundColor(.red)
            }
            if let info = viewModel.infoMessage {
                Text(info).font(.footnote).foregroundColor(.green)
            }

            PrimaryButton(title: "Verify", isLoading: viewModel.isLoading) {
                Task { await viewModel.verify() }
            }

            Button(viewModel.secondsLeft > 0 ? "Resend OTP in \(viewModel.secondsLeft)s" : "Resend OTP") {
                Task { await viewModel.resend() }
            }
            .disabled(!viewModel.canResend)
            .font(.subheadline)

            Spacer()
        }
        .padding()
        .navigationTitle("OTP Verification")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(viewModel.$state) { if $0 == .success { session.didLogin() } }
    }
}
