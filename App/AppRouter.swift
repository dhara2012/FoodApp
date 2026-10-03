import Foundation
import Combine

/// App-wide navigation: order ખોલવા માટે (Confirmation "Track order" અને પછી notification tap)
@MainActor
final class AppRouter: ObservableObject {
    @Published var showOrders = false
    @Published var openOrderID: String?

    func openOrder(id: String) {
        openOrderID = id
        showOrders = true
    }
}
