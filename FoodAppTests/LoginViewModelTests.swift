import XCTest
@testable import FoodApp

/// બધા auth tests માટે shared mock
final class MockAuthRepo: AuthRepositoryProtocol {
    var error: Error?
    private(set) var signupCalls = 0
    private(set) var verifyCalls = 0
    private let user = User(id: 1, name: "T", email: "t@t.com", mobile: nil)

    func login(email: String, password: String) async throws -> User { if let error { throw error }; return user }
    func signup(_ request: SignupRequest) async throws { signupCalls += 1; if let error { throw error } }
    func verifyOTP(email: String, otp: String) async throws -> User { verifyCalls += 1; if let error { throw error }; return user }
    func resendOTP(email: String) async throws { if let error { throw error } }
    func forgotPassword(email: String) async throws { if let error { throw error } }
    func resetPassword(email: String, otp: String, newPassword: String) async throws { if let error { throw error } }
    func logout() {}
}

@MainActor
final class LoginViewModelTests: XCTestCase {
    func test_invalidInput_doesNotCallApi() async {
        let vm = LoginViewModel(repository: MockAuthRepo())
        vm.email = "bad"; vm.password = "1"
        await vm.login()
        XCTAssertNotNil(vm.emailError)
        XCTAssertEqual(vm.state, .idle)
    }

    func test_success() async {
        let vm = LoginViewModel(repository: MockAuthRepo())
        vm.email = "t@t.com"; vm.password = "abcd1234"
        await vm.login()
        XCTAssertEqual(vm.state, .success)
    }

    func test_invalidCredentials() async {
        let repo = MockAuthRepo(); repo.error = NetworkError.unauthorized
        let vm = LoginViewModel(repository: repo)
        vm.email = "t@t.com"; vm.password = "abcd1234"
        await vm.login()
        XCTAssertEqual(vm.state, .failure("Invalid email or password"))
    }

    func test_noInternet() async {
        let repo = MockAuthRepo(); repo.error = NetworkError.noInternet
        let vm = LoginViewModel(repository: repo)
        vm.email = "t@t.com"; vm.password = "abcd1234"
        await vm.login()
        XCTAssertEqual(vm.state, .failure(NetworkError.noInternet.localizedDescription))
    }
}
