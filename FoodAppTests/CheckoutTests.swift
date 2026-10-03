import XCTest
@testable import FoodApp

private final class InMemoryAddresses: AddressStoring {
    var saved: [Address] = []
    func load() -> [Address] { saved }
    func save(_ a: [Address]) { saved = a }
}

private final class MockOrders: OrderRepositoryProtocol {
    var failures = 0                       // પહેલા N calls fail થાય
    private(set) var keys: [String] = []
    func create(_ r: OrderRequest, idempotencyKey: String) async throws -> Order {
        keys.append(idempotencyKey)
        if failures > 0 { failures -= 1; throw NetworkError.noInternet }
        return Order(id: "ORD1", restaurantId: r.restaurantId, restaurantName: r.restaurantName, items: [],
                     address: OrderAddress(name: "A", mobile: "9", addressLine: "x"),
                     paymentMethod: r.paymentMethod, paymentStatus: "paid",
                     itemTotal: r.itemTotal, discount: r.discount, tax: r.tax, deliveryFee: r.deliveryFee,
                     grandTotal: r.grandTotal, status: .placed, createdAt: Date())
    }
    func list() async throws -> [Order] { [] }
    func detail(id: String) async throws -> Order { throw NetworkError.unknown }
    func cancel(id: String) async throws -> Order { throw NetworkError.unknown }
}

private final class MockPayments: PaymentServicing {
    var result: PaymentResult = .success(reference: "PAY1")
    private(set) var calls = 0
    func pay(method: PaymentMethod, amount: Decimal, details: PaymentDetails) async -> PaymentResult {
        calls += 1; return result
    }
}

@MainActor
final class CheckoutTests: XCTestCase {
    private var cart: CartStore!
    private var book: AddressBook!
    private var orders: MockOrders!
    private var payments: MockPayments!

    override func setUp() async throws {
        cart = CartStore(); book = AddressBook(store: InMemoryAddresses())
        orders = MockOrders(); payments = MockPayments()
        _ = cart.add(CartItem(menuItemId: 1, restaurantId: 1, name: "Pizza", basePrice: 200,
                              selectedOptions: [], quantity: 2))
        cart.restaurantName = "Pizza Palace"
        book.add(Address(name: "A", mobile: "9876543210", house: "1", area: "B", city: "C",
                         state: "D", pincode: "380001"))
    }

    private func makeVM() -> CheckoutViewModel {
        CheckoutViewModel(cart: cart, addressBook: book, orders: orders, payments: payments)
    }

    func test_cod_createsOrder_withoutPayment_andClearsCart() async {
        let vm = makeVM()
        await vm.placeOrder()
        guard case .placed = vm.state else { return XCTFail("expected placed") }
        XCTAssertEqual(payments.calls, 0)
        XCTAssertTrue(cart.items.isEmpty)
    }

    func test_noAddress_fails_andNoOrder() async {
        book.delete(id: book.addresses[0].id)
        let vm = makeVM()
        await vm.placeOrder()
        XCTAssertEqual(vm.state, .failed("Please select a delivery address."))
        XCTAssertTrue(orders.keys.isEmpty)
    }

    func test_card_invalidInput_doesNotPay() async {
        let vm = makeVM(); vm.method = .card
        vm.details.cardNumber = "1234"
        await vm.placeOrder()
        XCTAssertNotNil(vm.inputError)
        XCTAssertEqual(payments.calls, 0)
    }

    func test_paymentFailure_createsNoOrder_andKeepsCart() async {
        let vm = makeVM(); vm.method = .upi; vm.details.upiId = "a@upi"
        payments.result = .failure("declined")
        await vm.placeOrder()
        XCTAssertEqual(vm.state, .failed("declined"))
        XCTAssertTrue(orders.keys.isEmpty)
        XCTAssertFalse(cart.items.isEmpty)
    }

    func test_paymentCancelled_createsNoOrder() async {
        let vm = makeVM(); vm.method = .mockOnline
        payments.result = .cancelled
        await vm.placeOrder()
        XCTAssertEqual(vm.state, .cancelled)
        XCTAssertTrue(orders.keys.isEmpty)
    }

    func test_networkFailureAfterPayment_retryDoesNotChargeAgain_andReusesKey() async {
        let vm = makeVM(); vm.method = .mockOnline
        orders.failures = 1
        await vm.placeOrder()
        guard case .failed = vm.state else { return XCTFail("expected failure") }
        await vm.placeOrder()   // retry
        guard case .placed = vm.state else { return XCTFail("expected placed") }
        XCTAssertEqual(payments.calls, 1)                 // ફક્ત એક જ વાર charge
        XCTAssertEqual(orders.keys.count, 2)
        XCTAssertEqual(orders.keys[0], orders.keys[1])    // એ જ idempotency key
    }

    func test_validators_cardUpiExpiry() {
        XCTAssertTrue(Validator.cardNumber("4111 1111 1111 1111").isValid)
        XCTAssertFalse(Validator.cardNumber("4111 1111 1111 1112").isValid)
        XCTAssertTrue(Validator.upi("dhara@okhdfc").isValid)
        XCTAssertFalse(Validator.upi("dhara").isValid)
        XCTAssertFalse(Validator.expiry("13/30").isValid)
        XCTAssertFalse(Validator.expiry("01/20").isValid)
        XCTAssertTrue(Validator.expiry("12/99").isValid)
        XCTAssertTrue(Validator.cvv("123").isValid)
    }
}
