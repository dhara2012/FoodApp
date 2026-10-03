//
//  ProductDetailView.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import SwiftUI

struct ProductDetailView: View {
    @StateObject var viewModel: ProductDetailViewModel
    let restaurant: Restaurant

    @EnvironmentObject var cart: CartStore
    @Environment(\.dismiss) private var dismiss
    @State private var showConflict = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                            .frame(height: 160)
                            .overlay(Image(systemName: "fork.knife").font(.largeTitle).foregroundColor(.secondary))
                        HStack { VegBadge(isVeg: viewModel.item.isVeg); Text(viewModel.item.name).font(.title2.bold()) }
                        Text(viewModel.item.description).foregroundColor(.secondary)
                        Text(viewModel.item.price.inr).font(.headline)
                    }
                }

                if !viewModel.item.variants.isEmpty {
                    Section("Choose size") {
                        ForEach(viewModel.item.variants) { variant in
                            optionRow(variant, selected: viewModel.selectedVariant == variant,
                                      symbol: ("largecircle.fill.circle", "circle")) {
                                viewModel.selectedVariant = variant
                            }
                        }
                    }
                }

                if !viewModel.item.addOns.isEmpty {
                    Section("Add-ons") {
                        ForEach(viewModel.item.addOns) { addOn in
                            optionRow(addOn, selected: viewModel.selectedAddOnIDs.contains(addOn.id),
                                      symbol: ("checkmark.square.fill", "square")) {
                                viewModel.toggleAddOn(addOn)
                            }
                        }
                    }
                }

                Section("Quantity") {
                    HStack {
                        Button { viewModel.decrement() } label: { Image(systemName: "minus.circle") }
                        Text("\(viewModel.quantity)").frame(minWidth: 40).font(.headline)
                        Button { viewModel.increment() } label: { Image(systemName: "plus.circle") }
                        Spacer()
                    }
                    .font(.title2)
                    .buttonStyle(.borderless)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() } }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: addToCart) {
                    Text("Add item • \(viewModel.totalPrice.inr)").bold().frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .background(.bar)
            }
            .alert("Replace cart items?", isPresented: $showConflict) {
                Button("Replace", role: .destructive) {
                    cart.replaceCart(with: viewModel.makeCartItem())
                    applyRestaurantInfo()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your cart has items from another restaurant. Clear it and add this item from \(restaurant.name)?")
            }
        }
    }

    private func addToCart() {
        switch cart.add(viewModel.makeCartItem()) {
        case .added:
            applyRestaurantInfo()
            dismiss()
        case .restaurantConflict:
            showConflict = true
        }
    }

    private func applyRestaurantInfo() {
        cart.deliveryFee = restaurant.deliveryFee
        cart.restaurantName = restaurant.name
    }

    private func optionRow(_ option: OptionChoice, selected: Bool,
                           symbol: (on: String, off: String), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(option.name)
                Spacer()
                if option.extraPrice > 0 { Text("+\(option.extraPrice.inr)").foregroundColor(.secondary) }
                Image(systemName: selected ? symbol.on : symbol.off).foregroundColor(.accentColor)
            }
            .contentShape(Rectangle())
        }
        .foregroundColor(.primary)
    }
}
