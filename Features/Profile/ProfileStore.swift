import SwiftUI
import Combine

/// Login થયેલા user ની માહિતી, profile photo (device પર) અને notification preferences
@MainActor
final class ProfileStore: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var photo: UIImage?
    @Published var orderUpdatesEnabled: Bool { didSet { defaults.set(orderUpdatesEnabled, forKey: Keys.orderUpdates) } }
    @Published var offersEnabled: Bool { didSet { defaults.set(offersEnabled, forKey: Keys.offers) } }

    private enum Keys {
        static let user = "cachedUser", orderUpdates = "pref.orderUpdates", offers = "pref.offers"
    }
    private let repository: ProfileRepositoryProtocol
    private let defaults: UserDefaults
    private let photoURL: URL
    private var cancellables = Set<AnyCancellable>()

    init(repository: ProfileRepositoryProtocol, defaults: UserDefaults = .standard) {
        self.repository = repository
        self.defaults = defaults
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        photoURL = dir.appendingPathComponent("profile_photo.jpg")
        orderUpdatesEnabled = defaults.object(forKey: Keys.orderUpdates) as? Bool ?? true
        offersEnabled = defaults.object(forKey: Keys.offers) as? Bool ?? true
        user = defaults.data(forKey: Keys.user).flatMap { try? JSONDecoder().decode(User.self, from: $0) }
        photo = UIImage(contentsOfFile: photoURL.path)

        // Session expire થાય ત્યારે જૂના user ની માહિતી સાફ
        NotificationCenter.default.publisher(for: .sessionExpired)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reset() }
            .store(in: &cancellables)
    }

    var firstName: String { user?.name.split(separator: " ").first.map(String.init) ?? "there" }
    var initials: String {
        let letters = (user?.name ?? "F").split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    func load() async {
        guard let fresh = try? await repository.fetch() else { return }   // fail થાય તો cache રહે
        apply(fresh)
    }

    func apply(_ user: User) {
        self.user = user
        if let data = try? JSONEncoder().encode(user) { defaults.set(data, forKey: Keys.user) }
    }

    func setPhoto(_ data: Data) {
        guard let image = UIImage(data: data) else { return }
        let small = Self.resized(image)
        photo = small
        try? small.jpegData(compressionQuality: 0.8)?.write(to: photoURL, options: .atomic)
    }

    func removePhoto() {
        photo = nil
        try? FileManager.default.removeItem(at: photoURL)
    }

    func reset() {
        user = nil
        defaults.removeObject(forKey: Keys.user)
        removePhoto()
    }

    private static func resized(_ image: UIImage, maxSide: CGFloat = 512) -> UIImage {
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        guard scale < 1 else { return image }
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
}
