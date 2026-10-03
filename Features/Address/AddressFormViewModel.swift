import Foundation
import Combine
import CoreLocation

@MainActor
final class AddressFormViewModel: ObservableObject {
    enum Field { case name, mobile, house, area, city, state, pincode }

    @Published var name = ""
    @Published var mobile = ""
    @Published var house = ""
    @Published var area = ""
    @Published var city = ""
    @Published var state = ""
    @Published var pincode = ""
    @Published var isDefault = false
    @Published private(set) var latitude: Double?
    @Published private(set) var longitude: Double?
    @Published private(set) var errors: [Field: String] = [:]
    @Published private(set) var isLocating = false
    @Published private(set) var locationError: String?

    let isEditing: Bool
    private let id: UUID
    private let locationFetcher = LocationFetcher()

    init(address: Address? = nil) {
        isEditing = address != nil
        id = address?.id ?? UUID()
        guard let a = address else { return }
        name = a.name; mobile = a.mobile; house = a.house; area = a.area
        city = a.city; state = a.state; pincode = a.pincode
        isDefault = a.isDefault; latitude = a.latitude; longitude = a.longitude
    }

    @discardableResult
    func validate() -> Bool {
        errors = [
            .name: Validator.name(name).message,
            .mobile: Validator.mobile(mobile).message,
            .house: Validator.required(house, "House / Flat no.").message,
            .area: Validator.required(area, "Area").message,
            .city: Validator.required(city, "City").message,
            .state: Validator.required(state, "State").message,
            .pincode: Validator.pincode(pincode).message
        ].compactMapValues { $0 }
        return errors.isEmpty
    }

    /// Valid હોય તો Address બનાવે, નહીંતર nil (errors ભરાય)
    func build() -> Address? {
        guard validate() else { return nil }
        func clean(_ s: String) -> String { s.trimmingCharacters(in: .whitespaces) }
        return Address(id: id, name: clean(name), mobile: mobile, house: clean(house), area: clean(area),
                       city: clean(city), state: clean(state), pincode: pincode,
                       latitude: latitude, longitude: longitude, isDefault: isDefault)
    }

    func useCurrentLocation() async {
        guard !isLocating else { return }
        isLocating = true
        locationError = nil
        defer { isLocating = false }
        do {
            let location = try await locationFetcher.current()
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            if let p = try? await CLGeocoder().reverseGeocodeLocation(location).first {
                if let v = p.subLocality ?? p.thoroughfare { area = v }
                if let v = p.locality { city = v }
                if let v = p.administrativeArea { state = v }
                if let v = p.postalCode { pincode = v }
            }
        } catch {
            locationError = error.localizedDescription
        }
    }
}
