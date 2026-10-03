import Foundation
import Combine

@MainActor
final class CartStore: ObservableObject {
    @Published private(set) var items: [CartItem] = []
    @Published private(set) var coupon: Coupon?
    @Published private(set) var couponError: String?
    @Published var restaurantName = ""
    var deliveryFee: Decimal = 40

    private let calculator = PriceCalculator()
    var restaurantId: Int? { items.first?.restaurantId }
    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }

    enum AddResult: Equatable { case added, restaurantConflict }

    /// .restaurantConflict મળે તો UI "cart clear કરીને add કરીએ?" પૂછે
    func add(_ item: CartItem) -> AddResult {
        if let current = restaurantId, current != item.restaurantId { return .restaurantConflict }
        if let i = items.firstIndex(where: { $0.menuItemId == item.menuItemId
                                          && $0.selectedOptions == item.selectedOptions }) {
            items[i].quantity += item.quantity
        } else { items.append(item) }
        return .added
    }

    func replaceCart(with item: CartItem) { clear(); items = [item] }

    func updateQuantity(id: UUID, quantity: Int) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        if quantity <= 0 { items.remove(at: i) } else { items[i].quantity = quantity }
        if items.isEmpty { coupon = nil; restaurantName = "" }
    }

    func apply(_ coupon: Coupon) {
        do {
            _ = try calculator.discount(for: coupon, itemTotal: breakdown.itemTotal)
            self.coupon = coupon; couponError = nil
        } catch { couponError = error.localizedDescription }
    }

    func removeCoupon() { coupon = nil; couponError = nil }
    func clear() { items = []; coupon = nil; couponError = nil; restaurantName = "" }

    var breakdown: PriceBreakdown {
        let itemTotal = items.reduce(0) { $0 + $1.lineTotal }
        let disc = coupon.flatMap { try? calculator.discount(for: $0, itemTotal: itemTotal) } ?? 0
        return calculator.breakdown(items: items, deliveryFee: deliveryFee, discount: disc)
    }
}
