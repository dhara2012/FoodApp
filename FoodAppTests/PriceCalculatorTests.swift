import XCTest
@testable import FoodApp

final class PriceCalculatorTests: XCTestCase {
    private let calc = PriceCalculator()
    private func pizza(qty: Int) -> CartItem {
        CartItem(menuItemId: 1, restaurantId: 1, name: "Pizza", basePrice: 200,
                 selectedOptions: [OptionChoice(id: 1, name: "Large", extraPrice: 50),
                                   OptionChoice(id: 2, name: "Cheese", extraPrice: 30)],
                 quantity: qty)
    }

    func test_lineTotal_includesOptionsAndQuantity() {
        XCTAssertEqual(pizza(qty: 2).lineTotal, 560)
    }

    func test_breakdown_noCoupon() {
        let b = calc.breakdown(items: [pizza(qty: 2)], deliveryFee: 40)
        XCTAssertEqual(b.itemTotal, 560)
        XCTAssertEqual(b.tax, 28)
        XCTAssertEqual(b.grandTotal, 628)
    }

    func test_percentCoupon_isCapped() throws {
        let c = Coupon(code: "SAVE20", kind: .percent(20), minOrder: 100, maxDiscount: 50)
        XCTAssertEqual(try calc.discount(for: c, itemTotal: 560), 50)
    }

    func test_coupon_minOrderNotMet() {
        let c = Coupon(code: "BIG", kind: .flat(100), minOrder: 1000, maxDiscount: nil)
        XCTAssertThrowsError(try calc.discount(for: c, itemTotal: 560))
    }

    func test_emptyCart_hasNoDeliveryFee() {
        XCTAssertEqual(calc.breakdown(items: [], deliveryFee: 40).grandTotal, 0)
    }
}
