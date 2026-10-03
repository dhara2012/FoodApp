import Foundation

protocol AuthRepositoryProtocol {
    func login(email: String, password: String) async throws -> User
    func signup(_ request: SignupRequest) async throws
    func verifyOTP(email: String, otp: String) async throws -> User
    func resendOTP(email: String) async throws
    func forgotPassword(email: String) async throws
    func resetPassword(email: String, otp: String, newPassword: String) async throws
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
        try await authenticate(.login(email: email, password: password))
    }

    func signup(_ request: SignupRequest) async throws {
        let _: MessageResponse = try await api.send(
            .signup(name: request.name, email: request.email, mobile: request.mobile, password: request.password))
    }

    func verifyOTP(email: String, otp: String) async throws -> User {
        try await authenticate(.verifyOTP(email: email, otp: otp))
    }

    func resendOTP(email: String) async throws {
        let _: MessageResponse = try await api.send(.resendOTP(email: email))
    }

    func forgotPassword(email: String) async throws {
        let _: MessageResponse = try await api.send(.forgotPassword(email: email))
    }

    func resetPassword(email: String, otp: String, newPassword: String) async throws {
        let _: MessageResponse = try await api.send(
            .resetPassword(email: email, otp: otp, newPassword: newPassword))
    }

    func logout() { tokenStore.clear() }

    private func authenticate(_ endpoint: Endpoint) async throws -> User {
        let response: AuthResponse = try await api.send(endpoint)
        tokenStore.save(access: response.accessToken, refresh: response.refreshToken)
        return response.user
    }
}
