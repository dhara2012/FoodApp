import SwiftUI

struct OrderHistoryView: View {
    @EnvironmentObject var services: ServiceContainer

    var body: some View {
        OrderHistoryContent(viewModel: OrdersViewModel(repository: services.orders))
    }
}

private struct OrderHistoryContent: View {
    @StateObject var viewModel: OrdersViewModel
    @EnvironmentObject var router: AppRouter
    @State private var deepLinkOrder: Order?
    @State private var showDeepLink = false

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failure(let message):
                VStack(spacing: 12) {
                    Text(message).multilineTextAlignment(.center)
                    Button("Retry") { Task { await viewModel.load() } }.buttonStyle(.borderedProminent)
                }
                .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .empty:
                VStack(spacing: 8) {
                    Text("🧾").font(.system(size: 48))
                    Text("No orders yet").font(.headline)
                    Text("Your placed orders will show up here").font(.subheadline).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .content:
                List(viewModel.orders) { order in
                    NavigationLink { OrderDetailView(order: order) } label: { row(order) }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("My orders")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.load(showSpinner: false) }
        .task { await viewModel.load(); consumeDeepLink() }
        .onReceive(router.$openOrderID) { _ in consumeDeepLink() }
        .navigationDestination(isPresented: $showDeepLink) {
            if let order = deepLinkOrder { OrderDetailView(order: order) }
        }
    }

    /// "Track order" / notification tap થી સીધો Order Details
    private func consumeDeepLink() {
        guard let id = router.openOrderID,
              let order = viewModel.orders.first(where: { $0.id == id }) else { return }
        deepLinkOrder = order
        showDeepLink = true
        router.openOrderID = nil
    }

    private func row(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(order.restaurantName).font(.headline)
                Spacer()
                StatusBadge(status: order.status)
            }
            Text(order.itemsSummary).font(.subheadline).foregroundColor(.secondary).lineLimit(2)
            HStack {
                Text(order.dateText)
                Spacer()
                Text(order.grandTotal.inr).bold()
            }
            .font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
