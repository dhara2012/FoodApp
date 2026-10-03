import XCTest
@testable import FoodApp

private final class MockAuthRepo: AuthRepositoryProtocol {
    var result: Result<User, Error> = .success(User(id: 1, name: "T", email: "t@t.com", mobile: nil))
    func login(email: String, password: String) async throws -> User { try result.get() }
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
        let repo = MockAuthRepo(); repo.result = .failure(NetworkError.unauthorized)
        let vm = LoginViewModel(repository: repo)
        vm.email = "t@t.com"; vm.password = "abcd1234"
        await vm.login()
        XCTAssertEqual(vm.state, .failure("Invalid email or password"))
    }

    func test_noInternet() async {
        let repo = MockAuthRepo(); repo.result = .failure(NetworkError.noInternet)
        let vm = LoginViewModel(repository: repo)
        vm.email = "t@t.com"; vm.password = "abcd1234"
        await vm.login()
        XCTAssertEqual(vm.state, .failure(NetworkError.noInternet.localizedDescription))
    }
}
