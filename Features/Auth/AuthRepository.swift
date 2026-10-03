import Foundation

protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> User
    func logout()
}

final class AuthRepository: AuthRepositoryProtocol {
    private let api: APIClientProtocol
    private let tokenStore: TokenStoring

    init(api: APIClientProtocol, tokenStore: TokenStoring) {
        self.api = api
        self.tokenStore = tokenStore
    }

    func login(email: String, password: String) async throws -> User {
        let response: AuthResponse = try await api.send(.login(email: email, password: password))
        tokenStore.save(access: response.accessToken, refresh: response.refreshToken)
        return response.user
    }

    func logout() { tokenStore.clear() }
}
