import XCTest
@testable import FoodApp

private final class StubProfileRepo: ProfileRepositoryProtocol {
    var error: Error?
    private(set) var updateCalls = 0
    private(set) var passwordCalls = 0
    func fetch() async throws -> User { User(id: 1, name: "A", email: "a@a.com", mobile: "9876543210") }
    func update(name: String, mobile: String) async throws -> User {
        updateCalls += 1
        if let error { throw error }
        return User(id: 1, name: name, email: "a@a.com", mobile: mobile)
    }
    func changePassword(current: String, new: String) async throws {
        passwordCalls += 1
        if let error { throw error }
    }
}

@MainActor
final class ProfileTests: XCTestCase {
    private let user = User(id: 1, name: "Dhara Sarvaiya", email: "d@d.com", mobile: "9876543210")

    func test_edit_invalidInput_doesNotCallApi() async {
        let repo = StubProfileRepo()
        let vm = EditProfileViewModel(user: user, repository: repo)
        vm.name = "A"; vm.mobile = "123"
        await vm.save()
        XCTAssertEqual(vm.errors.count, 2)
        XCTAssertEqual(repo.updateCalls, 0)
    }

    func test_edit_success_returnsUpdatedUser() async {
        let vm = EditProfileViewModel(user: user, repository: StubProfileRepo())
        vm.name = "Dhara S"
        await vm.save()
        XCTAssertEqual(vm.state, .saved(User(id: 1, name: "Dhara S", email: "a@a.com", mobile: "9876543210")))
    }

    func test_edit_noChanges_flag() {
        let vm = EditProfileViewModel(user: user, repository: StubProfileRepo())
        XCTAssertFalse(vm.hasChanges)
        vm.mobile = "9000000000"
        XCTAssertTrue(vm.hasChanges)
    }

    func test_edit_networkFailure() async {
        let repo = StubProfileRepo(); repo.error = NetworkError.noInternet
        let vm = EditProfileViewModel(user: user, repository: repo)
        vm.name = "New Name"
        await vm.save()
        XCTAssertEqual(vm.state, .failure(NetworkError.noInternet.localizedDescription))
    }

    func test_password_validation() async {
        let repo = StubProfileRepo()
        let vm = ChangePasswordViewModel(repository: repo)
        await vm.submit()
        XCTAssertEqual(vm.errors.count, 3)
        vm.current = "abcd1234"; vm.newPassword = "abcd1234"; vm.confirm = "abcd1234"
        await vm.submit()
        XCTAssertEqual(vm.errors["new"], "New password must be different")
        vm.newPassword = "newpass123"; vm.confirm = "other"
        await vm.submit()
        XCTAssertEqual(vm.errors["confirm"], "Passwords do not match")
        XCTAssertEqual(repo.passwordCalls, 0)
    }

    func test_password_success() async {
        let vm = ChangePasswordViewModel(repository: StubProfileRepo())
        vm.current = "abcd1234"; vm.newPassword = "newpass123"; vm.confirm = "newpass123"
        await vm.submit()
        XCTAssertEqual(vm.state, .success)
    }

    func test_password_wrongCurrent_showsServerMessage() async {
        let repo = StubProfileRepo()
        repo.error = NetworkError.server(code: 400, message: "Current password is incorrect")
        let vm = ChangePasswordViewModel(repository: repo)
        vm.current = "wrong1234"; vm.newPassword = "newpass123"; vm.confirm = "newpass123"
        await vm.submit()
        XCTAssertEqual(vm.state, .failure("Current password is incorrect"))
    }

    func test_store_initialsAndFirstName() {
        let store = ProfileStore(repository: StubProfileRepo(), defaults: UserDefaults(suiteName: "test.profile")!)
        store.apply(user)
        XCTAssertEqual(store.firstName, "Dhara")
        XCTAssertEqual(store.initials, "DS")
        store.reset()
        XCTAssertEqual(store.firstName, "there")
    }
}
