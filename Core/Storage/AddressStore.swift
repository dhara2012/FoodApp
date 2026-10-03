import Foundation

/// Local storage (JSON file). Protocol હોવાથી tests માં in-memory store વાપરી શકાય,
/// અને પછી SwiftData/Core Data થી બદલવું સરળ.
protocol AddressStoring {
    func load() -> [Address]
    func save(_ addresses: [Address])
}

final class FileAddressStore: AddressStoring {
    private let url: URL

    init(filename: String = "addresses.json") {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent(filename)
    }

    func load() -> [Address] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([Address].self, from: data)) ?? []
    }

    func save(_ addresses: [Address]) {
        guard let data = try? JSONEncoder().encode(addresses) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
