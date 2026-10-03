import Foundation
import Combine

@MainActor
final class OrderDetailViewModel: ObservableObject {
    @Published private(set) var order: Order
    @Published private(set) var refreshError: String?
    @Published private(set) var cancelError: String?
    @Published private(set) var isCancelling = false

    private let repository: OrderRepositoryProtocol
    private let pollInterval: UInt64

    init(order: Order, repository: OrderRepositoryProtocol, pollInterval: UInt64 = 5_000_000_000) {
        self.order = order
        self.repository = repository
        self.pollInterval = pollInterval
    }

    var canCancel: Bool { order.status.canCancel }

    func refresh() async {
        do {
            order = try await repository.detail(id: order.id)
            refreshError = nil
        } catch {
            refreshError = "Couldn't update the status. Retrying…"   // જૂનો status દેખાતો રહે
        }
    }

    /// Delivered/Cancelled ન થાય ત્યાં સુધી દર 5 સેકન્ડે status refresh.
    /// View જતાં `.task` આપોઆપ cancel થાય એટલે polling બંધ.
    func startTracking() async {
        while !Task.isCancelled && !order.status.isTerminal {
            try? await Task.sleep(nanoseconds: pollInterval)
            if Task.isCancelled { break }
            await refresh()
        }
    }

    func cancel() async {
        guard canCancel, !isCancelling else { return }
        isCancelling = true
        cancelError = nil
        defer { isCancelling = false }
        do {
            order = try await repository.cancel(id: order.id)
        } catch {
            cancelError = error.authMessage
            await refresh()     // કદાચ status આગળ વધી ગયો હોય
        }
    }
}
