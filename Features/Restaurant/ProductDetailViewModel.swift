//
//  ProductDetailViewModel.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import Foundation
import Combine

@MainActor
final class ProductDetailViewModel: ObservableObject {
    let item: MenuItem
    @Published var selectedVariant: OptionChoice?
    @Published private(set) var selectedAddOnIDs: Set<Int> = []
    @Published private(set) var quantity = 1

    static let maxQuantity = 20

    init(item: MenuItem) {
        self.item = item
        self.selectedVariant = item.variants.first      // default: પહેલી size
    }

    var selectedOptions: [OptionChoice] {
        var result: [OptionChoice] = []
        if let v = selectedVariant { result.append(v) }
        result += item.addOns.filter { selectedAddOnIDs.contains($0.id) }
        return result
    }

    var unitPrice: Decimal { item.price + selectedOptions.reduce(0) { $0 + $1.extraPrice } }
    var totalPrice: Decimal { unitPrice * Decimal(quantity) }

    func toggleAddOn(_ addOn: OptionChoice) {
        if selectedAddOnIDs.contains(addOn.id) { selectedAddOnIDs.remove(addOn.id) }
        else { selectedAddOnIDs.insert(addOn.id) }
    }

    func increment() { if quantity < Self.maxQuantity { quantity += 1 } }
    func decrement() { if quantity > 1 { quantity -= 1 } }

    func makeCartItem() -> CartItem {
        CartItem(menuItemId: item.id, restaurantId: item.restaurantId, name: item.name,
                 basePrice: item.price, selectedOptions: selectedOptions, quantity: quantity)
    }
}
