import Foundation
import Combine

@MainActor
final class CheckoutViewModel: ObservableObject {
    enum State: Equatable { case idle, processing, placed(Order), failed(String), cancelled }

    @Published var method: PaymentMethod = .cod
    @Published var details = PaymentDetails()
    @Published private(set) var state: State = .idle
    @Published private(set) var inputError: String?

    private let cart: CartStore
    private let addressBook: AddressBook
    private let orders: OrderRepositoryProtocol
    private let payments: PaymentServicing

    // Duplicate order અને double charge અટકાવવા
    private(set) var idempotencyKey: String?
    private var paymentReference: String?

    init(cart: CartStore, addressBook: AddressBook, orders: OrderRepositoryProtocol, payments: PaymentServicing) {
        self.cart = cart
        self.addressBook = addressBook
        self.orders = orders
        self.payments = payments
    }

    var isProcessing: Bool { state == .processing }

    var buttonTitle: String {
        let total = cart.breakdown.grandTotal.inr
        return method == .cod ? "Place order • \(total)" : "Pay \(total)"
    }

    func placeOrder() async {
        guard !isProcessing else { return }                       // double tap = બીજો order નહીં
        guard let address = addressBook.selectedAddress else {
            state = .failed("Please select a delivery address."); return
        }
        guard !cart.items.isEmpty, let restaurantId = cart.restaurantId else {
            state = .failed("Your cart is empty."); return
        }
        inputError = validatePaymentInput()
        guard inputError == nil else { return }

        state = .processing
        let breakdown = cart.breakdown

        // 1) Payment (COD માં નહીં; અને એક વાર paid થઈ ગયા પછી retry માં ફરી charge નહીં)
        if method != .cod && paymentReference == nil {
            switch await payments.pay(method: method, amount: breakdown.grandTotal, details: details) {
            case .success(let reference): paymentReference = reference
            case .failure(let message): state = .failed(message); return
            case .cancelled: state = .cancelled; return
            }
        }

        // 2) Payment સફળ પછી જ order બને. એ જ idempotency key થી retry કરો તો server જૂનો જ order આપે.
        let key = idempotencyKey ?? UUID().uuidString
        idempotencyKey = key
        let request = makeRequest(restaurantId: restaurantId, address: address, breakdown: breakdown)
        do {
            let order = try await orders.create(request, idempotencyKey: key)
            cart.clear()
            idempotencyKey = nil
            paymentReference = nil
            state = .placed(order)
        } catch {
            state = .failed(paymentReference != nil
                ? "Payment received, but we couldn't place your order. Tap retry — you won't be charged again."
                : error.authMessage)
        }
    }

    func validatePaymentInput() -> String? {
        switch method {
        case .card:
            return Validator.cardNumber(details.cardNumber).message
                ?? Validator.expiry(details.expiry).message
                ?? Validator.cvv(details.cvv).message
        case .upi:
            return Validator.upi(details.upiId).message
        case .cod, .mockOnline:
            return nil
        }
    }

    private func makeRequest(restaurantId: Int, address: Address, breakdown: PriceBreakdown) -> OrderRequest {
        OrderRequest(
            restaurantId: restaurantId,
            restaurantName: cart.restaurantName,
            items: cart.items.map {
                .init(menuItemId: $0.menuItemId, name: $0.name, quantity: $0.quantity,
                      unitPrice: $0.unitPrice, options: $0.selectedOptions.map(\.name))
            },
            address: .init(name: address.name, mobile: address.mobile, addressLine: address.oneLine,
                           latitude: address.latitude, longitude: address.longitude),
            paymentMethod: method.apiValue,
            paymentReference: paymentReference,
            couponCode: cart.coupon?.code,
            itemTotal: breakdown.itemTotal, discount: breakdown.discount, tax: breakdown.tax,
            deliveryFee: breakdown.deliveryFee, grandTotal: breakdown.grandTotal)
    }
}
