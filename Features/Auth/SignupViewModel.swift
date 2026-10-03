import Foundation
import Combine

@MainActor
final class SignupViewModel: ObservableObject {
    enum State: Equatable { case idle, loading, otpSent, failure(String) }
    enum Field { case name, email, mobile, password, confirm }

    @Published var name = ""
    @Published var email = ""
    @Published var mobile = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published private(set) var errors: [Field: String] = [:]
    @Published private(set) var state: State = .idle

    private let repository: AuthRepositoryProtocol
    init(repository: AuthRepositoryProtocol) { self.repository = repository }

    var isLoading: Bool { state == .loading }

    @discardableResult
    func validate() -> Bool {
        errors = [
            .name: Validator.name(name).message,
            .email: Validator.email(email).message,
            .mobile: Validator.mobile(mobile).message,
            .password: Validator.password(password).message,
            .confirm: Validator.confirmPassword(password, confirmPassword).message
        ].compactMapValues { $0 }
        return errors.isEmpty
    }

    func signup() async {
        guard !isLoading, validate() else { return }     // double tap અને ખોટો input અટકાવે
        state = .loading
        do {
            try await repository.signup(SignupRequest(
                name: name.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                mobile: mobile, password: password))
            state = .otpSent
        } catch {
            state = .failure(error.authMessage)
        }
    }
}
