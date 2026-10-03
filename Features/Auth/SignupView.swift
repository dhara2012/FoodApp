import SwiftUI

struct SignupView: View {
    @StateObject var viewModel: SignupViewModel
    let repository: AuthRepositoryProtocol
    @State private var showOTP = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Create account").font(.largeTitle.bold())

                FormField(title: "Full name", text: $viewModel.name, error: viewModel.errors[.name],
                          contentType: .name)
                FormField(title: "Email", text: $viewModel.email, error: viewModel.errors[.email],
                          keyboard: .emailAddress, contentType: .emailAddress)
                FormField(title: "Mobile number", text: $viewModel.mobile, error: viewModel.errors[.mobile],
                          keyboard: .numberPad, contentType: .telephoneNumber)
                FormField(title: "Password", text: $viewModel.password, error: viewModel.errors[.password],
                          isSecure: true, contentType: .newPassword)
                FormField(title: "Confirm password", text: $viewModel.confirmPassword,
                          error: viewModel.errors[.confirm], isSecure: true)

                if case .failure(let message) = viewModel.state {
                    Text(message).font(.footnote).foregroundColor(.red).multilineTextAlignment(.center)
                }

                PrimaryButton(title: "Sign up", isLoading: viewModel.isLoading) {
                    Task { await viewModel.signup() }
                }
            }
            .padding()
        }
        .navigationTitle("Sign up")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(viewModel.$state) { if $0 == .otpSent { showOTP = true } }
        .navigationDestination(isPresented: $showOTP) {
            OTPView(viewModel: OTPViewModel(
                email: viewModel.email.trimmingCharacters(in: .whitespaces).lowercased(),
                repository: repository))
        }
    }
}
