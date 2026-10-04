import Foundation

protocol ProfileRepositoryProtocol {
    func fetch() async throws -> User
    func update(name: String, mobile: String) async throws -> User
    func changePassword(current: String, new: String) async throws
}

final class ProfileRepository: ProfileRepositoryProtocol {
    private let api: APIClientProtocol
    init(api: APIClientProtocol) { self.api = api }

    func fetch() async throws -> User { try await api.send(.profile()) }

    func update(name: String, mobile: String) async throws -> User {
        try await api.send(.updateProfile(name: name, mobile: mobile))
    }

    func changePassword(current: String, new: String) async throws {
        let _: MessageResponse = try await api.send(.changePassword(current: current, new: new))
    }
}
