import Foundation
import Combine

/// Repositories / services એક જગ્યાએ (Dependency Injection). Views ને API ની ખબર નથી.
final class ServiceContainer: ObservableObject {
    let orders: OrderRepositoryProtocol
    let payments: PaymentServicing

    init(api: APIClientProtocol, payments: PaymentServicing = MockPaymentService()) {
        self.orders = OrderRepository(api: api)
        self.payments = payments
    }
}
