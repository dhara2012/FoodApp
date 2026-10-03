import SwiftUI

struct LoginView: View {
    @StateObject var viewModel: LoginViewModel
    @EnvironmentObject var session: SessionManager

    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome back").font(.largeTitle.bold())

            TextField("Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
            if let e = viewModel.emailError { Text(e).font(.caption).foregroundColor(.red) }

            SecureField("Password", text: $viewModel.password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)
            if let e = viewModel.passwordError { Text(e).font(.caption).foregroundColor(.red) }

            if case .failure(let msg) = viewModel.state {
                Text(msg).font(.footnote).foregroundColor(.red)
            }

            Button {
                Task { await viewModel.login() }
            } label: {
                if viewModel.isLoading { ProgressView() } else { Text("Login").bold() }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading)
        }
        .padding()
        .onReceive(viewModel.$state) { state in
            if state == .success { session.didLogin() }
        }
    }
}
