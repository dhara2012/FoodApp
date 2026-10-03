import Foundation
import Combine

@MainActor
final class OTPViewModel: ObservableObject {
    enum State: Equatable { case idle, loading, success, failure(String) }

    let email: String
    @Published var otp = ""
    @Published private(set) var otpError: String?
    @Published private(set) var state: State = .idle
    @Published private(set) var secondsLeft = 0
    @Published private(set) var infoMessage: String?

    private let repository: AuthRepositoryProtocol
    private let resendDelay: Int

    init(email: String, repository: AuthRepositoryProtocol, resendDelay: Int = 30) {
        self.email = email
        self.repository = repository
        self.resendDelay = resendDelay
        startCountdown()
    }

    var isLoading: Bool { state == .loading }
    var canResend: Bool { secondsLeft == 0 && !isLoading }

    func verify() async {
        guard !isLoading else { return }
        otpError = Validator.otp(otp).message
        guard otpError == nil else { return }
        state = .loading
        do {
            _ = try await repository.verifyOTP(email: email, otp: otp)
            state = .success
        } catch {
            state = .failure(error.authMessage)
        }
    }

    func resend() async {
        guard canResend else { return }
        do {
            try await repository.resendOTP(email: email)
            infoMessage = "A new OTP has been sent."
            state = .idle
            startCountdown()
        } catch {
            state = .failure(error.authMessage)
        }
    }

    private func startCountdown() {
        secondsLeft = resendDelay
        Task { [weak self] in
            while let self, self.secondsLeft > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self.secondsLeft = max(self.secondsLeft - 1, 0)
            }
        }
    }
}
