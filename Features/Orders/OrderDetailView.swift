import SwiftUI

struct OrderDetailView: View {
    @EnvironmentObject var services: ServiceContainer
    let order: Order

    var body: some View {
        OrderDetailContent(viewModel: OrderDetailViewModel(order: order, repository: services.orders))
    }
}

private struct OrderDetailContent: View {
    @StateObject var viewModel: OrderDetailViewModel
    @State private var confirmCancel = false

    var body: some View {
        let order = viewModel.order
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.restaurantName).font(.headline)
                    Text("Order \(order.id)").font(.caption.monospaced()).foregroundColor(.secondary)
                    Text(order.dateText).font(.caption).foregroundColor(.secondary)
                }
            }

            Section("Order status") {
                StatusTimeline(status: order.status)
                    .padding(.vertical, 4)
                if order.status == .cancelled && order.paymentStatus == "refunded" {
                    Text("Your payment will be refunded.").font(.caption).foregroundColor(.secondary)
                }
                if let error = viewModel.refreshError {
                    Text(error).font(.caption).foregroundColor(.orange)
                }
            }

            Section("Items") {
                ForEach(Array(order.items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(item.quantity) × \(item.name)").font(.subheadline)
                            if !item.options.isEmpty {
                                Text(item.options.joined(separator: ", ")).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Text((item.unitPrice * Decimal(item.quantity)).inr).font(.subheadline)
                    }
                }
            }

            Section("Delivery address") {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.address.name).font(.headline)
                    Text(order.address.addressLine).font(.subheadline).foregroundColor(.secondary)
                    Text("📞 \(order.address.mobile)").font(.caption).foregroundColor(.secondary)
                }
            }

            Section("Payment") {
                row("Method", order.paymentMethodTitle)
                row("Payment status", order.paymentStatus.capitalized)
            }

            Section("Bill details") {
                row("Item total", order.itemTotal.inr)
                if order.discount > 0 {
                    row("Discount" + (order.couponCode.map { " (\($0))" } ?? ""), "-" + order.discount.inr, color: .green)
                }
                row("Taxes", order.tax.inr)
                row("Delivery fee", order.deliveryFee.inr)
                row("Grand total", order.grandTotal.inr, bold: true)
            }

            if viewModel.canCancel {
                Section {
                    Button(role: .destructive) { confirmCancel = true } label: {
                        HStack {
                            if viewModel.isCancelling { ProgressView() }
                            Text("Cancel order").frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(viewModel.isCancelling)
                } footer: {
                    Text("You can cancel only before the restaurant starts preparing your food.")
                }
            }
            if let error = viewModel.cancelError {
                Section { Text(error).font(.footnote).foregroundColor(.red) }
            }
        }
        .navigationTitle("Order details")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.startTracking() }
        .confirmationDialog("Cancel this order?", isPresented: $confirmCancel, titleVisibility: .visible) {
            Button("Yes, cancel order", role: .destructive) { Task { await viewModel.cancel() } }
            Button("No, keep it", role: .cancel) {}
        }
    }

    private func row(_ title: String, _ value: String, bold: Bool = false, color: Color = .primary) -> some View {
        HStack { Text(title); Spacer(); Text(value) }
            .font(bold ? .headline : .subheadline).foregroundColor(color)
    }
}
