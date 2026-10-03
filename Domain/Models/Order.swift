import Foundation

enum PaymentMethod: String, CaseIterable, Identifiable {
    case cod, card, upi, mockOnline
    var id: String { rawValue }
    var title: String {
        switch self {
        case .cod: return "Cash on Delivery"
        case .card: return "Credit / Debit Card"
        case .upi: return "UPI"
        case .mockOnline: return "Mock Online Payment"
        }
    }
    var icon: String {
        switch self { case .cod: return "💵"; case .card: return "💳"; case .upi: return "📲"; case .mockOnline: return "🧪" }
    }
    var apiValue: String { self == .mockOnline ? "mock_online" : rawValue }
}

enum OrderStatus: String, Codable {
    case placed, confirmed, preparing
    case outForDelivery = "out_for_delivery"
    case delivered, cancelled

    var title: String {
        switch self {
        case .placed: return "Placed"
        case .confirmed: return "Confirmed"
        case .preparing: return "Preparing"
        case .outForDelivery: return "Out for Delivery"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        }
    }
}

struct OrderItem: Codable, Equatable {
    let name: String
    let quantity: Int
    let unitPrice: Decimal
    let options: [String]
}

struct OrderAddress: Codable, Equatable {
    let name: String
    let mobile: String
    let addressLine: String
}

struct Order: Decodable, Identifiable, Equatable {
    let id: String
    let restaurantId: Int
    let restaurantName: String
    let items: [OrderItem]
    let address: OrderAddress
    let paymentMethod: String
    let paymentStatus: String
    let itemTotal: Decimal
    let discount: Decimal
    let tax: Decimal
    let deliveryFee: Decimal
    let grandTotal: Decimal
    let status: OrderStatus
    let createdAt: Date
    var couponCode: String? = nil
}

/// Server ને મોકલવાની request (snake_case માં encode થાય છે)
struct OrderRequest: Encodable {
    struct Line: Encodable {
        let menuItemId: Int
        let name: String
        let quantity: Int
        let unitPrice: Decimal
        let options: [String]
    }
    struct Addr: Encodable {
        let name: String
        let mobile: String
        let addressLine: String
        let latitude: Double?
        let longitude: Double?
    }
    let restaurantId: Int
    let restaurantName: String
    let items: [Line]
    let address: Addr
    let paymentMethod: String
    let paymentReference: String?
    let couponCode: String?
    let itemTotal: Decimal
    let discount: Decimal
    let tax: Decimal
    let deliveryFee: Decimal
    let grandTotal: Decimal
}
