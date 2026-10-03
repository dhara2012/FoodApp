import XCTest
@testable import FoodApp

@MainActor
final class AuthFlowTests: XCTestCase {

    // MARK: Signup
    private func filledSignup(_ repo: MockAuthRepo) -> SignupViewModel {
        let vm = SignupViewModel(repository: repo)
        vm.name = "Dhara"; vm.email = "d@d.com"; vm.mobile = "9876543210"
        vm.password = "abcd1234"; vm.confirmPassword = "abcd1234"
        return vm
    }

    func test_signup_emptyForm_showsAllErrors_andNoApiCall() async {
        let repo = MockAuthRepo()
        let vm = SignupViewModel(repository: repo)
        await vm.signup()
        XCTAssertEqual(vm.errors.count, 5)
        XCTAssertEqual(repo.signupCalls, 0)
    }

    func test_signup_passwordMismatch() async {
        let vm = filledSignup(MockAuthRepo())
        vm.confirmPassword = "different1"
        await vm.signup()
        XCTAssertEqual(vm.errors[.confirm], "Passwords do not match")
    }

    func test_signup_success_movesToOtp() async {
        let repo = MockAuthRepo()
        let vm = filledSignup(repo)
        await vm.signup()
        XCTAssertEqual(vm.state, .otpSent)
        XCTAssertEqual(repo.signupCalls, 1)
    }

    func test_signup_emailAlreadyRegistered_showsServerMessage() async {
        let repo = MockAuthRepo(); repo.error = NetworkError.server(code: 409, message: "Email already registered")
        let vm = filledSignup(repo)
        await vm.signup()
        XCTAssertEqual(vm.state, .failure("Email already registered"))
    }

    // MARK: OTP
    func test_otp_invalidFormat_doesNotCallApi() async {
        let repo = MockAuthRepo()
        let vm = OTPViewModel(email: "d@d.com", repository: repo, resendDelay: 0)
        vm.otp = "12"
        await vm.verify()
        XCTAssertNotNil(vm.otpError)
        XCTAssertEqual(repo.verifyCalls, 0)
    }

    func test_otp_success() async {
        let vm = OTPViewModel(email: "d@d.com", repository: MockAuthRepo(), resendDelay: 0)
        vm.otp = "123456"
        await vm.verify()
        XCTAssertEqual(vm.state, .success)
    }

    func test_otp_wrongCode_showsError() async {
        let repo = MockAuthRepo(); repo.error = NetworkError.server(code: 400, message: "Invalid OTP. Please try again.")
        let vm = OTPViewModel(email: "d@d.com", repository: repo, resendDelay: 0)
        vm.otp = "000000"
        await vm.verify()
        XCTAssertEqual(vm.state, .failure("Invalid OTP. Please try again."))
    }

    func test_otp_resendDisabledDuringCountdown() {
        let vm = OTPViewModel(email: "d@d.com", repository: MockAuthRepo(), resendDelay: 30)
        XCTAssertFalse(vm.canResend)
    }

    // MARK: Forgot password
    func test_forgot_invalidEmail_staysOnFirstStep() async {
        let vm = ForgotPasswordViewModel(repository: MockAuthRepo())
        vm.email = "nope"
        await vm.sendOTP()
        XCTAssertEqual(vm.step, .enterEmail)
        XCTAssertNotNil(vm.errors["email"])
    }

    func test_forgot_fullFlow() async {
        let vm = ForgotPasswordViewModel(repository: MockAuthRepo())
        vm.email = "d@d.com"
        await vm.sendOTP()
        XCTAssertEqual(vm.step, .resetPassword)

        vm.otp = "123456"; vm.newPassword = "newpass123"; vm.confirmPassword = "newpass123"
        await vm.resetPassword()
        XCTAssertEqual(vm.state, .done)
    }

    func test_forgot_reset_validatesPasswordRules() async {
        let vm = ForgotPasswordViewModel(repository: MockAuthRepo())
        vm.email = "d@d.com"; await vm.sendOTP()
        vm.otp = "123456"; vm.newPassword = "short"; vm.confirmPassword = "short"
        await vm.resetPassword()
        XCTAssertNotNil(vm.errors["password"])
        XCTAssertNotEqual(vm.state, .done)
    }

    // MARK: Validators
    func test_validatorExtras() {
        XCTAssertFalse(Validator.name("A").isValid)
        XCTAssertTrue(Validator.name("Dhara").isValid)
        XCTAssertTrue(Validator.confirmPassword("a", "a").isValid)
        XCTAssertFalse(Validator.confirmPassword("a", "b").isValid)
    }
}
