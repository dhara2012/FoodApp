import Foundation
import Combine

enum AppTab: Hashable { case home, orders, profile }

/// App-wide navigation: tab બદલવા અને order ખોલવા (Track order / notification tap)
@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home
    @Published var openOrderID: String?

    func openOrder(id: String) {
        openOrderID = id
        selectedTab = .orders
    }
}
