import SwiftUI

/// Environment માંથી dependencies લઈ ViewModel બનાવે છે
struct CheckoutView: View {
    @EnvironmentObject var cart: CartStore
    @EnvironmentObject var book: AddressBook
    @EnvironmentObject var services: ServiceContainer
    let onFinish: () -> Void

    var body: some View {
        CheckoutContent(
            viewModel: CheckoutViewModel(cart: cart, addressBook: book,
                                         orders: services.orders, payments: services.payments),
            onFinish: onFinish)
    }
}

private struct CheckoutContent: View {
    @StateObject var viewModel: CheckoutViewModel
    let onFinish: () -> Void
    @EnvironmentObject var cart: CartStore
    @EnvironmentObject var book: AddressBook
    @EnvironmentObject var router: AppRouter
    @State private var showAddresses = false
    @State private var showConfirmation = false

    var body: some View {
        List {
            addressSection
            Section("Order from \(cart.restaurantName)") {
                ForEach(cart.items) { item in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(item.quantity) × \(item.name)").font(.subheadline)
                            if !item.selectedOptions.isEmpty {
                                Text(item.selectedOptions.map(\.name).joined(separator: ", "))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Text(item.lineTotal.inr).font(.subheadline)
                    }
                }
            }
            if let coupon = cart.coupon {
                Section("Coupon") { Label("\(coupon.code) applied", systemImage: "tag.fill").foregroundColor(.green) }
            }
            Section("Bill details") {
                let b = cart.breakdown
                billRow("Item total", b.itemTotal.inr)
                if b.discount > 0 { billRow("Discount", "-" + b.discount.inr, color: .green) }
                billRow("Taxes (5%)", b.tax.inr)
                billRow("Delivery fee", b.deliveryFee.inr)
                billRow("To pay", b.grandTotal.inr, bold: true)
            }
            Section("Payment method") {
                ForEach(PaymentMethod.allCases) { m in
                    Button { viewModel.method = m } label: {
                        HStack {
                            Text("\(m.icon)  \(m.title)")
                            Spacer()
                            Image(systemName: viewModel.method == m ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(.accentColor)
                        }
                        .contentShape(Rectangle())
                    }
                    .foregroundColor(.primary)
                }
            }
            paymentDetailsSection
            messageSection
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: viewModel.buttonTitle, isLoading: viewModel.isProcessing) {
                Task { await viewModel.placeOrder() }
            }
            .padding().background(.bar)
        }
        .sheet(isPresented: $showAddresses) {
            NavigationStack {
                AddressListView { address in book.select(address.id); showAddresses = false }
            }
        }
        .onReceive(viewModel.$state) { if case .placed = $0 { showConfirmation = true } }
        .fullScreenCover(isPresented: $showConfirmation) {
            if case .placed(let order) = viewModel.state {
                OrderConfirmationView(
                    order: order,
                    onDone: { showConfirmation = false; onFinish() },
                    onTrack: {
                        showConfirmation = false
                        onFinish()
                        // Cart sheet બંધ થવાની રાહ જોઈ પછી Orders ખોલો
                        Task {
                            try? await Task.sleep(nanoseconds: 700_000_000)
                            router.openOrder(id: order.id)
                        }
                    })
            }
        }
    }

    // MARK: Sections
    private var addressSection: some View {
        Section("Delivery address") {
            if let a = book.selectedAddress {
                VStack(alignment: .leading, spacing: 4) {
                    Text(a.name).font(.headline)
                    Text(a.oneLine).font(.subheadline).foregroundColor(.secondary)
                    Text("📞 \(a.mobile)").font(.caption).foregroundColor(.secondary)
                }
                Button("Change address") { showAddresses = true }
            } else {
                Button("＋ Add delivery address") { showAddresses = true }
            }
        }
    }

    @ViewBuilder
    private var paymentDetailsSection: some View {
        switch viewModel.method {
        case .card:
            Section("Card details") {
                FormField(title: "Card number", text: $viewModel.details.cardNumber, keyboard: .numberPad)
                HStack {
                    FormField(title: "MM/YY", text: $viewModel.details.expiry, keyboard: .numbersAndPunctuation)
                    FormField(title: "CVV", text: $viewModel.details.cvv, isSecure: true, keyboard: .numberPad)
                }
                Text("Test: 4111 1111 1111 1111 = success • card ending 0002 = declined")
                    .font(.caption2).foregroundColor(.secondary)
            }
        case .upi:
            Section("UPI") {
                FormField(title: "UPI ID", text: $viewModel.details.upiId, keyboard: .emailAddress)
                Text("Test: name@upi = success • fail@upi = failure").font(.caption2).foregroundColor(.secondary)
            }
        case .mockOnline:
            Section("Test mode") {
                Picker("Simulate", selection: $viewModel.details.simulated) {
                    ForEach(SimulatedOutcome.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        case .cod:
            EmptyView()
        }
    }

    @ViewBuilder
    private var messageSection: some View {
        if let error = viewModel.inputError {
            Section { Text(error).foregroundColor(.red).font(.footnote) }
        }
        switch viewModel.state {
        case .failed(let message): Section { Text(message).foregroundColor(.red).font(.footnote) }
        case .cancelled: Section { Text("Payment cancelled. No money was deducted.").foregroundColor(.orange).font(.footnote) }
        default: EmptyView()
        }
    }

    private func billRow(_ title: String, _ value: String, bold: Bool = false, color: Color = .primary) -> some View {
        HStack { Text(title); Spacer(); Text(value) }
            .font(bold ? .headline : .subheadline).foregroundColor(color)
    }
}

struct OrderConfirmationView: View {
    let order: Order
    let onDone: () -> Void
    let onTrack: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            Text("✅").font(.system(size: 72))
            Text("Order placed!").font(.largeTitle.bold())
            Text("Order ID").font(.caption).foregroundColor(.secondary)
            Text(order.id).font(.title3.monospaced().bold()).textSelection(.enabled)
            VStack(spacing: 4) {
                Text(order.restaurantName).font(.headline)
                Text("\(order.grandTotal.inr) • \(order.paymentStatus.capitalized)").foregroundColor(.secondary)
                Text("Status: \(order.status.title)").foregroundColor(.green)
            }
            .padding(.top, 6)
            Spacer()
            Button(action: onTrack) { Text("Track order").bold().frame(maxWidth: .infinity, minHeight: 46) }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("Track order")
            Button(action: onDone) { Text("Done").frame(maxWidth: .infinity, minHeight: 46) }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("Done")
        }
        .padding()
    }
}
