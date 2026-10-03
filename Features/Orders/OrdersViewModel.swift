import Foundation
import Combine

@MainActor
final class OrdersViewModel: ObservableObject {
    enum State: Equatable { case loading, content, empty, failure(String) }

    @Published private(set) var orders: [Order] = []
    @Published private(set) var state: State = .loading
    private let repository: OrderRepositoryProtocol

    init(repository: OrderRepositoryProtocol) { self.repository = repository }

    func load(showSpinner: Bool = true) async {
        if showSpinner && orders.isEmpty { state = .loading }
        do {
            orders = try await repository.list()
            state = orders.isEmpty ? .empty : .content
        } catch {
            // Pull-to-refresh fail થાય તો જૂની list રહેવા દો
            if orders.isEmpty { state = .failure(error.authMessage) }
        }
    }
}
