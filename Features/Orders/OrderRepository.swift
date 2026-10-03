import Foundation

protocol OrderRepositoryProtocol {
    func create(_ request: OrderRequest, idempotencyKey: String) async throws -> Order
    func list() async throws -> [Order]
    func detail(id: String) async throws -> Order
    func cancel(id: String) async throws -> Order
}

final class OrderRepository: OrderRepositoryProtocol {
    private let api: APIClientProtocol
    init(api: APIClientProtocol) { self.api = api }

    func create(_ request: OrderRequest, idempotencyKey: String) async throws -> Order {
        try await api.send(.createOrder(request, idempotencyKey: idempotencyKey))
    }
    func list() async throws -> [Order] { try await api.send(.orders()) }
    func detail(id: String) async throws -> Order { try await api.send(.order(id: id)) }
    func cancel(id: String) async throws -> Order { try await api.send(.cancelOrder(id: id)) }
}
