import Foundation
import Combine

@MainActor
final class EditProfileViewModel: ObservableObject {
    enum State: Equatable { case idle, saving, saved(User), failure(String) }

    @Published var name: String
    @Published var mobile: String
    @Published private(set) var errors: [String: String] = [:]
    @Published private(set) var state: State = .idle
    let email: String

    private let original: User?
    private let repository: ProfileRepositoryProtocol

    init(user: User?, repository: ProfileRepositoryProtocol) {
        original = user
        name = user?.name ?? ""
        mobile = user?.mobile ?? ""
        email = user?.email ?? ""
        self.repository = repository
    }

    var isSaving: Bool { state == .saving }
    var hasChanges: Bool {
        name.trimmingCharacters(in: .whitespaces) != original?.name || mobile != (original?.mobile ?? "")
    }

    func save() async {
        guard !isSaving else { return }
        errors = ["name": Validator.name(name).message,
                  "mobile": Validator.mobile(mobile).message].compactMapValues { $0 }
        guard errors.isEmpty else { return }
        state = .saving
        do {
            let user = try await repository.update(name: name.trimmingCharacters(in: .whitespaces), mobile: mobile)
            state = .saved(user)
        } catch {
            state = .failure(error.authMessage)
        }
    }
}
