//
//  CartView.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import SwiftUI

struct CartView: View {
    @EnvironmentObject var cart: CartStore
    @Environment(\.dismiss) private var dismiss
    @State private var couponCode = ""
    @State private var invalidCouponMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if cart.items.isEmpty { emptyState } else { cartList }
            }
            .navigationTitle("Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() } } }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "cart").font(.system(size: 48)).foregroundColor(.secondary)
            Text("Your cart is empty").font(.headline)
            Text("Add items from a restaurant to get started")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var cartList: some View {
        List {
            Section(cart.restaurantName) {
                ForEach(cart.items) { item in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name).font(.headline)
                            if !item.selectedOptions.isEmpty {
                                Text(item.selectedOptions.map(\.name).joined(separator: ", "))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Text(item.lineTotal.inr).font(.subheadline)
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            Button { cart.updateQuantity(id: item.id, quantity: item.quantity - 1) }
                                label: { Image(systemName: "minus.circle") }
                            Text("\(item.quantity)").frame(minWidth: 24)
                            Button { cart.updateQuantity(id: item.id, quantity: item.quantity + 1) }
                                label: { Image(systemName: "plus.circle") }
                        }
                        .font(.title3)
                        .buttonStyle(.borderless)
                    }
                }
            }

            Section("Coupon") {
                if let applied = cart.coupon {
                    HStack {
                        Label("\(applied.code) applied", systemImage: "tag.fill").foregroundColor(.green)
                        Spacer()
                        Button("Remove", role: .destructive) { cart.removeCoupon(); invalidCouponMessage = nil }
                            .buttonStyle(.borderless)
                    }
                } else {
                    HStack {
                        TextField("Enter coupon code", text: $couponCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        Button("Apply", action: applyCoupon)
                            .buttonStyle(.borderless)
                            .disabled(couponCode.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                if let message = cart.couponError ?? invalidCouponMessage {
                    Text(message).font(.caption).foregroundColor(.red)
                }
                Text("Try: SAVE20 (min ₹200) or FLAT50 (min ₹300)")
                    .font(.caption2).foregroundColor(.secondary)
            }

            Section("Bill details") {
                let b = cart.breakdown
                row("Item total", b.itemTotal.inr)
                if b.discount > 0 { row("Discount", "-" + b.discount.inr, color: .green) }
                row("Taxes (5%)", b.tax.inr)
                row("Delivery fee", b.deliveryFee.inr)
                row("Grand total", b.grandTotal.inr, bold: true)
            }
        }
        .safeAreaInset(edge: .bottom) {
            NavigationLink {
                CheckoutView(onFinish: { dismiss() })
            } label: {
                Text("Proceed to Checkout • \(cart.breakdown.grandTotal.inr)")
                    .bold().frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .background(.bar)
        }
    }

    private func applyCoupon() {
        guard let coupon = Coupon.find(couponCode.trimmingCharacters(in: .whitespaces)) else {
            invalidCouponMessage = "Invalid coupon code"
            return
        }
        invalidCouponMessage = nil
        cart.apply(coupon)
        if cart.couponError == nil { couponCode = "" }
    }

    private func row(_ title: String, _ value: String, bold: Bool = false, color: Color = .primary) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
        }
        .font(bold ? .headline : .subheadline)
        .foregroundColor(color)
    }
}
