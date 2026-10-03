import Foundation

struct Address: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var mobile: String
    var house: String
    var area: String
    var city: String
    var state: String
    var pincode: String
    var latitude: Double?
    var longitude: Double?
    var isDefault = false

    var oneLine: String { "\(house), \(area), \(city), \(state) - \(pincode)" }
}
