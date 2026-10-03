import SwiftUI

struct LoginView: View {
    @StateObject var viewModel: LoginViewModel
    let repository: AuthRepositoryProtocol
    @EnvironmentObject var session: SessionManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("🍽️").font(.system(size: 56))
                Text("Welcome back").font(.largeTitle.bold())
                Text("Login to order your favourite food").foregroundColor(.secondary)

                FormField(title: "Email", text: $viewModel.email, error: viewModel.emailError,
                          keyboard: .emailAddress, contentType: .emailAddress)
                FormField(title: "Password", text: $viewModel.password, error: viewModel.passwordError,
                          isSecure: true, contentType: .password)

                HStack {
                    Spacer()
                    NavigationLink("Forgot password?") {
                        ForgotPasswordView(viewModel: ForgotPasswordViewModel(repository: repository))
                    }
                    .font(.footnote)
                }

                if case .failure(let message) = viewModel.state {
                    Text(message).font(.footnote).foregroundColor(.red).multilineTextAlignment(.center)
                }

                PrimaryButton(title: "Login", isLoading: viewModel.isLoading) {
                    Task { await viewModel.login() }
                }

                HStack {
                    Text("New here?").foregroundColor(.secondary)
                    NavigationLink("Create account") {
                        SignupView(viewModel: SignupViewModel(repository: repository), repository: repository)
                    }
                }
                .font(.subheadline)
            }
            .padding()
        }
        .onReceive(viewModel.$state) { state in
            if state == .success { session.didLogin() }
        }
    }
}
