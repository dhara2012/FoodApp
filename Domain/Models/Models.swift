import Foundation

struct User: Codable, Equatable {
    let id: Int
    var name: String
    var email: String
    var mobile: String?
}

struct AuthResponse: Decodable {
    let user: User
    let accessToken: String
    let refreshToken: String
}

struct Restaurant: Decodable, Identifiable, Equatable {
    let id: Int
    let name: String
    let imageUrl: String?
    let rating: Double
    let deliveryTimeMin: Int
    let deliveryFee: Decimal
    let distanceKm: Double
    let cuisine: String
    var emoji: String? = nil
    var offer: String? = nil
}

struct OptionChoice: Codable, Hashable, Identifiable {
    let id: Int
    let name: String
    let extraPrice: Decimal
}

struct MenuItem: Decodable, Identifiable {
    let id: Int
    let restaurantId: Int
    let name: String
    let description: String
    let price: Decimal
    let isVeg: Bool
    let imageUrl: String?
    let variants: [OptionChoice]   // એક જ પસંદ થાય (Size)
    let addOns: [OptionChoice]     // ઘણા પસંદ થાય
    var category: String? = nil
    var emoji: String? = nil
    var restaurantName: String? = nil
    var isPopular: Bool? = nil
}

struct CartItem: Identifiable, Equatable {
    let id = UUID()
    let menuItemId: Int
    let restaurantId: Int
    let name: String
    let basePrice: Decimal
    var selectedOptions: [OptionChoice]
    var quantity: Int

    var unitPrice: Decimal { basePrice + selectedOptions.reduce(0) { $0 + $1.extraPrice } }
    var lineTotal: Decimal { unitPrice * Decimal(quantity) }
}

struct Coupon: Equatable {
    enum Kind: Equatable { case percent(Decimal), flat(Decimal) }
    let code: String
    let kind: Kind
    let minOrder: Decimal
    let maxDiscount: Decimal?

    static let available: [Coupon] = [
        Coupon(code: "SAVE20", kind: .percent(20), minOrder: 200, maxDiscount: 100),
        Coupon(code: "FLAT50", kind: .flat(50), minOrder: 300, maxDiscount: nil)
    ]
    static func find(_ code: String) -> Coupon? {
        available.first { $0.code == code.uppercased() }
    }
}

enum RestaurantSort: String, CaseIterable, Identifiable {
    case none, rating, deliveryTime, distance
    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "Relevance"
        case .rating: return "Rating (High to Low)"
        case .deliveryTime: return "Delivery Time"
        case .distance: return "Distance"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .none: return []
        case .rating: return [.init(name: "_sort", value: "rating"), .init(name: "_order", value: "desc")]
        case .deliveryTime: return [.init(name: "_sort", value: "delivery_time_min"), .init(name: "_order", value: "asc")]
        case .distance: return [.init(name: "_sort", value: "distance_km"), .init(name: "_order", value: "asc")]
        }
    }
}
