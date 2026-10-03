import Foundation

struct PriceBreakdown: Equatable {
    var itemTotal: Decimal
    var discount: Decimal
    var tax: Decimal
    var deliveryFee: Decimal
    var grandTotal: Decimal
}

enum CouponError: LocalizedError, Equatable {
    case minOrderNotMet(Decimal)
    var errorDescription: String? {
        switch self {
        case .minOrderNotMet(let min): return "Add items worth ₹\(min) to use this coupon."
        }
    }
}

/// Pure logic, no UI. Easy to unit test.
struct PriceCalculator {
    var taxRate: Decimal = 0.05

    func discount(for coupon: Coupon, itemTotal: Decimal) throws -> Decimal {
        guard itemTotal >= coupon.minOrder else { throw CouponError.minOrderNotMet(coupon.minOrder) }
        var value: Decimal
        switch coupon.kind {
        case .percent(let p): value = itemTotal * p / 100
        case .flat(let f): value = f
        }
        if let cap = coupon.maxDiscount { value = min(value, cap) }
        return min(value, itemTotal)
    }

    func breakdown(items: [CartItem], deliveryFee: Decimal, discount: Decimal = 0) -> PriceBreakdown {
        let itemTotal = items.reduce(0) { $0 + $1.lineTotal }
        let taxable = max(itemTotal - discount, 0)
        let tax = (taxable * taxRate).rounded(2)
        let fee = items.isEmpty ? 0 : deliveryFee
        return PriceBreakdown(itemTotal: itemTotal, discount: discount, tax: tax,
                              deliveryFee: fee, grandTotal: taxable + tax + fee)
    }
}

extension Decimal {
    func rounded(_ scale: Int) -> Decimal {
        var value = self, result = Decimal()
        NSDecimalRound(&result, &value, scale, .plain)
        return result
    }
}
