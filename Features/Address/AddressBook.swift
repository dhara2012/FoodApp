import Foundation
import Combine

/// બધા saved addresses + પસંદ કરેલું address (app માં બધે શેર થાય).
/// નિયમ: સરનામું હોય તો હંમેશા બરાબર એક default હોય.
@MainActor
final class AddressBook: ObservableObject {
    @Published private(set) var addresses: [Address]
    @Published private(set) var selectedID: UUID?
    private let store: AddressStoring

    init(store: AddressStoring = FileAddressStore()) {
        self.store = store
        let loaded = store.load()
        addresses = loaded
        selectedID = loaded.first(where: \.isDefault)?.id
    }

    var defaultAddress: Address? { addresses.first(where: \.isDefault) }
    var selectedAddress: Address? { addresses.first { $0.id == selectedID } ?? defaultAddress }

    func add(_ address: Address) {
        var new = address
        if addresses.isEmpty { new.isDefault = true }
        if new.isDefault { clearDefault() }
        addresses.append(new)
        if new.isDefault || selectedID == nil { selectedID = new.id }
        persist()
    }

    func update(_ address: Address) {
        guard let index = addresses.firstIndex(where: { $0.id == address.id }) else { return }
        if address.isDefault { clearDefault() }
        addresses[index] = address
        ensureDefault()
        if address.isDefault { selectedID = address.id }
        persist()
    }

    func delete(id: UUID) {
        addresses.removeAll { $0.id == id }
        ensureDefault()
        if selectedID == id { selectedID = defaultAddress?.id }
        persist()
    }

    func setDefault(id: UUID) {
        guard addresses.contains(where: { $0.id == id }) else { return }
        for i in addresses.indices { addresses[i].isDefault = (addresses[i].id == id) }
        selectedID = id
        persist()
    }

    func select(_ id: UUID) { if addresses.contains(where: { $0.id == id }) { selectedID = id } }

    private func clearDefault() { for i in addresses.indices { addresses[i].isDefault = false } }

    private func ensureDefault() {
        if !addresses.isEmpty && !addresses.contains(where: \.isDefault) { addresses[0].isDefault = true }
    }

    private func persist() { store.save(addresses) }
}
