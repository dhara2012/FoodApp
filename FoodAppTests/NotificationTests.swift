import XCTest
@testable import FoodApp

private final class StubOrders: OrderRepositoryProtocol {
    var result: Result<[Order], Error> = .success([])
    func create(_ r: OrderRequest, idempotencyKey: String) async throws -> Order { throw NetworkError.unknown }
    func list() async throws -> [Order] { try result.get() }
    func detail(id: String) async throws -> Order { throw NetworkError.unknown }
    func cancel(id: String) async throws -> Order { throw NetworkError.unknown }
}

private final class SpyNotifier: OrderNotifying {
    private(set) var sent: [(id: String, status: OrderStatus)] = []
    func notify(order: Order) async { sent.append((order.id, order.status)) }
}

private func makeOrder(_ status: OrderStatus, id: String = "ORD1") -> Order {
    Order(id: id, restaurantId: 1, restaurantName: "Pizza Palace", items: [],
          address: OrderAddress(name: "A", mobile: "9", addressLine: "x"),
          paymentMethod: "upi", paymentStatus: "paid", itemTotal: 100, discount: 0, tax: 5,
          deliveryFee: 10, grandTotal: 115, status: status, createdAt: Date())
}

@MainActor
final class NotificationTests: XCTestCase {
    private var orders: StubOrders!
    private var notifier: SpyNotifier!
    private var enabled = true

    override func setUp() async throws {
        orders = StubOrders(); notifier = SpyNotifier(); enabled = true
    }

    private func makeMonitor() -> OrderStatusMonitor {
        OrderStatusMonitor(orders: orders, notifier: notifier, isEnabled: { [unowned self] in self.enabled },
                           interval: 1_000_000,
                           defaults: UserDefaults(suiteName: "test.monitor.\(UUID().uuidString)")!)
    }

    func test_content_forEachStatus() {
        XCTAssertNotNil(OrderNotification.content(for: makeOrder(.confirmed)))
        XCTAssertNotNil(OrderNotification.content(for: makeOrder(.preparing)))
        XCTAssertNotNil(OrderNotification.content(for: makeOrder(.outForDelivery)))
        XCTAssertNotNil(OrderNotification.content(for: makeOrder(.delivered)))
        XCTAssertNil(OrderNotification.content(for: makeOrder(.placed)))
        XCTAssertNil(OrderNotification.content(for: makeOrder(.cancelled)))
        XCTAssertTrue(OrderNotification.content(for: makeOrder(.confirmed))!.body.contains("Pizza Palace"))
    }

    func test_firstPoll_doesNotNotify() async {
        orders.result = .success([makeOrder(.delivered)])
        let monitor = makeMonitor()
        await monitor.poll()
        XCTAssertTrue(notifier.sent.isEmpty)
    }

    func test_statusChange_notifiesOnce() async {
        let monitor = makeMonitor()
        orders.result = .success([makeOrder(.placed)])
        await monitor.poll()
        orders.result = .success([makeOrder(.confirmed)])
        await monitor.poll()
        await monitor.poll()                      // same status again
        XCTAssertEqual(notifier.sent.count, 1)
        XCTAssertEqual(notifier.sent.first?.status, .confirmed)
    }

    func test_fullFlow_notifiesEachStep() async {
        let monitor = makeMonitor()
        for status in [OrderStatus.placed, .confirmed, .preparing, .outForDelivery, .delivered] {
            orders.result = .success([makeOrder(status)])
            await monitor.poll()
        }
        XCTAssertEqual(notifier.sent.map(\.status), [.confirmed, .preparing, .outForDelivery, .delivered])
    }

    func test_preferenceOff_doesNotNotify() async {
        let monitor = makeMonitor()
        orders.result = .success([makeOrder(.placed)])
        await monitor.poll()
        enabled = false
        orders.result = .success([makeOrder(.confirmed)])
        await monitor.poll()
        XCTAssertTrue(notifier.sent.isEmpty)
    }

    func test_networkFailure_isIgnored() async {
        let monitor = makeMonitor()
        orders.result = .failure(NetworkError.noInternet)
        await monitor.poll()
        XCTAssertTrue(notifier.sent.isEmpty)
    }
}
