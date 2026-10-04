import Foundation
import Combine

@MainActor
final class ChangePasswordViewModel: ObservableObject {
    enum State: Equatable { case idle, saving, success, failure(String) }

    @Published var current = ""
    @Published var newPassword = ""
    @Published var confirm = ""
    @Published private(set) var errors: [String: String] = [:]
    @Published private(set) var state: State = .idle

    private let repository: ProfileRepositoryProtocol
    init(repository: ProfileRepositoryProtocol) { self.repository = repository }

    var isSaving: Bool { state == .saving }

    func submit() async {
        guard !isSaving else { return }
        var result: [String: String?] = [
            "current": current.isEmpty ? "Enter your current password" : nil,
            "new": Validator.password(newPassword).message,
            "confirm": Validator.confirmPassword(newPassword, confirm).message
        ]
        if result["new"] == .some(nil) && newPassword == current && !current.isEmpty {
            result["new"] = "New password must be different"
        }
        errors = result.compactMapValues { $0 }
        guard errors.isEmpty else { return }
        state = .saving
        do {
            try await repository.changePassword(current: current, new: newPassword)
            state = .success
        } catch {
            state = .failure(error.authMessage)
        }
    }
}
