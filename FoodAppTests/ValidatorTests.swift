import XCTest
@testable import FoodApp

final class ValidatorTests: XCTestCase {
    func test_email() {
        XCTAssertTrue(Validator.email("a@b.com").isValid)
        XCTAssertFalse(Validator.email("abc").isValid)
        XCTAssertFalse(Validator.email("").isValid)
    }
    func test_password() {
        XCTAssertTrue(Validator.password("abcd1234").isValid)
        XCTAssertFalse(Validator.password("abc").isValid)
        XCTAssertFalse(Validator.password("abcdefgh").isValid)
    }
    func test_mobile() {
        XCTAssertTrue(Validator.mobile("9876543210").isValid)
        XCTAssertFalse(Validator.mobile("1234567890").isValid)
    }
    func test_pincode() {
        XCTAssertTrue(Validator.pincode("380001").isValid)
        XCTAssertFalse(Validator.pincode("0123").isValid)
    }
}
