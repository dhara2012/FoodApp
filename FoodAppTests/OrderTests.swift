import XCTest
@testable import FoodApp

private final class StubOrders: OrderRepositoryProtocol {
    var listResult: Result<[Order], Error> = .success([])
    var detailQueue: [Order] = []
    var cancelResult: Result<Order, Error> = .failure(NetworkError.unknown)
    private(set) var detailCalls = 0
    private(set) var cancelCalls = 0

    func create(_ r: OrderRequest, idempotencyKey: String) async throws -> Order { throw NetworkError.unknown }
    func list() async throws -> [Order] { try listResult.get() }
    func detail(id: String) async throws -> Order {
        detailCalls += 1
        return detailQueue.count > 1 ? detailQueue.removeFirst() : detailQueue[0]
    }
    func cancel(id: String) async throws -> Order { cancelCalls += 1; return try cancelResult.get() }
}

private func makeOrder(_ status: OrderStatus, id: String = "ORD1") -> Order {
    Order(id: id, restaurantId: 1, restaurantName: "Pizza Palace",
          items: [OrderItem(name: "Pizza", quantity: 2, unitPrice: 200, options: ["Large"])],
          address: OrderAddress(name: "A", mobile: "9876543210", addressLine: "x"),
          paymentMethod: "upi", paymentStatus: "paid",
          itemTotal: 400, discount: 0, tax: 20, deliveryFee: 40, grandTotal: 460,
          status: status, createdAt: Date())
}

@MainActor
final class OrderTests: XCTestCase {

    func test_statusRules() {
        XCTAssertTrue(OrderStatus.placed.canCancel)
        XCTAssertTrue(OrderStatus.confirmed.canCancel)
        XCTAssertFalse(OrderStatus.preparing.canCancel)
        XCTAssertFalse(OrderStatus.outForDelivery.canCancel)
        XCTAssertTrue(OrderStatus.delivered.isTerminal)
        XCTAssertTrue(OrderStatus.cancelled.isTerminal)
        XCTAssertFalse(OrderStatus.preparing.isTerminal)
        XCTAssertEqual(OrderStatus.outForDelivery.stepIndex, 3)
    }

    func test_history_loadsOrders() async {
        let repo = StubOrders(); repo.listResult = .success([makeOrder(.placed)])
        let vm = OrdersViewModel(repository: repo)
        await vm.load()
        XCTAssertEqual(vm.state, .content)
        XCTAssertEqual(vm.orders.count, 1)
    }

    func test_history_emptyState() async {
        let vm = OrdersViewModel(repository: StubOrders())
        await vm.load()
        XCTAssertEqual(vm.state, .empty)
    }

    func test_history_failureState() async {
        let repo = StubOrders(); repo.listResult = .failure(NetworkError.noInternet)
        let vm = OrdersViewModel(repository: repo)
        await vm.load()
        XCTAssertEqual(vm.state, .failure(NetworkError.noInternet.localizedDescription))
    }

    func test_cancel_success_updatesStatus() async {
        let repo = StubOrders(); repo.cancelResult = .success(makeOrder(.cancelled))
        let vm = OrderDetailViewModel(order: makeOrder(.placed), repository: repo)
        await vm.cancel()
        XCTAssertEqual(vm.order.status, .cancelled)
        XCTAssertNil(vm.cancelError)
    }

    func test_cancel_failure_showsServerMessage_andRefreshes() async {
        let repo = StubOrders()
        repo.cancelResult = .failure(NetworkError.server(code: 400, message: "This order can no longer be cancelled"))
        repo.detailQueue = [makeOrder(.preparing)]
        let vm = OrderDetailViewModel(order: makeOrder(.placed), repository: repo)
        await vm.cancel()
        XCTAssertEqual(vm.cancelError, "This order can no longer be cancelled")
        XCTAssertEqual(vm.order.status, .preparing)          // refresh થી સાચો status
    }

    func test_cancel_notAllowedWhenPreparing_doesNotCallApi() async {
        let repo = StubOrders()
        let vm = OrderDetailViewModel(order: makeOrder(.preparing), repository: repo)
        await vm.cancel()
        XCTAssertEqual(repo.cancelCalls, 0)
    }

    func test_tracking_pollsUntilDelivered_thenStops() async {
        let repo = StubOrders()
        repo.detailQueue = [makeOrder(.confirmed), makeOrder(.preparing), makeOrder(.delivered)]
        let vm = OrderDetailViewModel(order: makeOrder(.placed), repository: repo, pollInterval: 1_000_000)
        await vm.startTracking()
        XCTAssertEqual(vm.order.status, .delivered)
        XCTAssertEqual(repo.detailCalls, 3)
    }

    func test_refreshFailure_keepsLastStatus_andShowsMessage() async {
        let vm = OrderDetailViewModel(order: makeOrder(.confirmed), repository: FailingDetail())
        await vm.refresh()
        XCTAssertEqual(vm.order.status, .confirmed)
        XCTAssertNotNil(vm.refreshError)
    }
}

private final class FailingDetail: OrderRepositoryProtocol {
    func create(_ r: OrderRequest, idempotencyKey: String) async throws -> Order { throw NetworkError.unknown }
    func list() async throws -> [Order] { [] }
    func detail(id: String) async throws -> Order { throw NetworkError.noInternet }
    func cancel(id: String) async throws -> Order { throw NetworkError.unknown }
}
