import XCTest
@testable import FoodApp

private final class InMemoryAddressStore: AddressStoring {
    var saved: [Address] = []
    func load() -> [Address] { saved }
    func save(_ addresses: [Address]) { saved = addresses }
}

@MainActor
final class AddressTests: XCTestCase {
    private func makeAddress(_ name: String, isDefault: Bool = false) -> Address {
        Address(name: name, mobile: "9876543210", house: "12", area: "Navrangpura", city: "Ahmedabad",
                state: "Gujarat", pincode: "380009", isDefault: isDefault)
    }

    func test_firstAddress_becomesDefaultAndSelected() {
        let book = AddressBook(store: InMemoryAddressStore())
        let a = makeAddress("A")
        book.add(a)
        XCTAssertEqual(book.defaultAddress?.id, a.id)
        XCTAssertEqual(book.selectedAddress?.id, a.id)
    }

    func test_addingNewDefault_clearsOldDefault() {
        let book = AddressBook(store: InMemoryAddressStore())
        book.add(makeAddress("A"))
        book.add(makeAddress("B", isDefault: true))
        XCTAssertEqual(book.addresses.filter(\.isDefault).count, 1)
        XCTAssertEqual(book.defaultAddress?.name, "B")
    }

    func test_deleteDefault_promotesAnother() {
        let book = AddressBook(store: InMemoryAddressStore())
        let a = makeAddress("A"), b = makeAddress("B")
        book.add(a); book.add(b)
        book.delete(id: a.id)
        XCTAssertEqual(book.addresses.count, 1)
        XCTAssertEqual(book.defaultAddress?.name, "B")
    }

    func test_setDefault_switchesDefault() {
        let book = AddressBook(store: InMemoryAddressStore())
        let a = makeAddress("A"), b = makeAddress("B")
        book.add(a); book.add(b)
        book.setDefault(id: b.id)
        XCTAssertEqual(book.defaultAddress?.name, "B")
        XCTAssertEqual(book.addresses.filter(\.isDefault).count, 1)
    }

    func test_update_changesFields() {
        let book = AddressBook(store: InMemoryAddressStore())
        var a = makeAddress("A"); book.add(a)
        a.city = "Surat"
        book.update(a)
        XCTAssertEqual(book.addresses.first?.city, "Surat")
    }

    func test_addresses_persistAcrossLaunches() {
        let store = InMemoryAddressStore()
        AddressBook(store: store).add(makeAddress("A"))
        XCTAssertEqual(AddressBook(store: store).addresses.count, 1)
    }

    func test_form_emptyShowsErrors_andDoesNotBuild() {
        let vm = AddressFormViewModel()
        XCTAssertNil(vm.build())
        XCTAssertEqual(vm.errors.count, 7)
    }

    func test_form_invalidPincode() {
        let vm = AddressFormViewModel(address: makeAddress("A"))
        vm.pincode = "12"
        XCTAssertNil(vm.build())
        XCTAssertNotNil(vm.errors[.pincode])
    }

    func test_form_validBuildsAddress() {
        let vm = AddressFormViewModel(address: makeAddress("A"))
        XCTAssertEqual(vm.build()?.city, "Ahmedabad")
    }
}
