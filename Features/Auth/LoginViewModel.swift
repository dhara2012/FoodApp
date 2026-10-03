import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    enum State: Equatable { case idle, loading, success, failure(String) }

    @Published var email = ""
    @Published var password = ""
    @Published private(set) var state: State = .idle
    @Published private(set) var emailError: String?
    @Published private(set) var passwordError: String?

    private let repository: AuthRepositoryProtocol
    init(repository: AuthRepositoryProtocol) { self.repository = repository }

    var isLoading: Bool { state == .loading }

    func login() async {
        guard !isLoading else { return }          // block double taps
        emailError = Validator.email(email).message
        passwordError = Validator.password(password).message
        guard emailError == nil, passwordError == nil else { return }

        state = .loading
        do {
            _ = try await repository.login(email: email.trimmingCharacters(in: .whitespaces),
                                           password: password)
            state = .success
        } catch let error as NetworkError {
            state = .failure(error == .unauthorized ? "Invalid email or password" : error.localizedDescription)
        } catch {
            state = .failure("Something went wrong.")
        }
    }
}
