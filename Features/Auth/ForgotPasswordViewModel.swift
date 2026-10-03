import Foundation
import Combine

@MainActor
final class ForgotPasswordViewModel: ObservableObject {
    enum Step { case enterEmail, resetPassword }
    enum State: Equatable { case idle, loading, failure(String), done }

    @Published var email = ""
    @Published var otp = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published private(set) var step: Step = .enterEmail
    @Published private(set) var state: State = .idle
    @Published private(set) var errors: [String: String] = [:]

    private let repository: AuthRepositoryProtocol
    init(repository: AuthRepositoryProtocol) { self.repository = repository }

    var isLoading: Bool { state == .loading }
    private var cleanEmail: String { email.trimmingCharacters(in: .whitespaces).lowercased() }

    func sendOTP() async {
        guard !isLoading else { return }
        errors = ["email": Validator.email(email).message].compactMapValues { $0 }
        guard errors.isEmpty else { return }
        state = .loading
        do {
            try await repository.forgotPassword(email: cleanEmail)
            step = .resetPassword
            state = .idle
        } catch {
            state = .failure(error.authMessage)
        }
    }

    func resetPassword() async {
        guard !isLoading else { return }
        errors = [
            "otp": Validator.otp(otp).message,
            "password": Validator.password(newPassword).message,
            "confirm": Validator.confirmPassword(newPassword, confirmPassword).message
        ].compactMapValues { $0 }
        guard errors.isEmpty else { return }
        state = .loading
        do {
            try await repository.resetPassword(email: cleanEmail, otp: otp, newPassword: newPassword)
            state = .done
        } catch {
            state = .failure(error.authMessage)
        }
    }
}
