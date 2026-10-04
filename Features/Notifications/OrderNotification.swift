import Foundation

/// દરેક order status માટે notification નું લખાણ. Placed/Cancelled માટે notification નથી.
enum OrderNotification {
    static func content(for order: Order) -> (title: String, body: String)? {
        switch order.status {
        case .confirmed: return ("Order confirmed ✅", "\(order.restaurantName) has accepted your order.")
        case .preparing: return ("Preparing your food 👨‍🍳", "\(order.restaurantName) is preparing your order.")
        case .outForDelivery: return ("Out for delivery 🛵", "Your order is on the way!")
        case .delivered: return ("Delivered 🎉", "Enjoy your meal from \(order.restaurantName)!")
        case .placed, .cancelled: return nil
        }
    }
}
