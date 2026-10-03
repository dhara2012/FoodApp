import Foundation

enum SimulatedOutcome: String, CaseIterable, Identifiable {
    case success, failure, cancel
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct PaymentDetails {
    var cardNumber = ""
    var expiry = ""
    var cvv = ""
    var upiId = ""
    var simulated: SimulatedOutcome = .success   // ફક્ત Mock Online માટે
}

enum PaymentResult: Equatable {
    case success(reference: String)
    case failure(String)
    case cancelled
}

protocol PaymentServicing {
    func pay(method: PaymentMethod, amount: Decimal, details: PaymentDetails) async -> PaymentResult
}

/// Demo payment gateway. Test cards: કોઈ પણ valid card ચાલે, "...0002" પર ખતમ થતો card decline થાય.
/// UPI ID "fail" થી શરૂ થાય તો fail થાય.
struct MockPaymentService: PaymentServicing {
    var delayNanoseconds: UInt64 = 1_200_000_000

    func pay(method: PaymentMethod, amount: Decimal, details: PaymentDetails) async -> PaymentResult {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
        let reference = "PAY\(Int.random(in: 100_000...999_999))"
        switch method {
        case .cod:
            return .success(reference: "COD")
        case .card:
            return details.cardNumber.filter(\.isNumber).hasSuffix("0002")
                ? .failure("Your card was declined. Please try another card.")
                : .success(reference: reference)
        case .upi:
            return details.upiId.lowercased().hasPrefix("fail")
                ? .failure("UPI payment failed. Please try again.")
                : .success(reference: reference)
        case .mockOnline:
            switch details.simulated {
            case .success: return .success(reference: reference)
            case .failure: return .failure("Payment failed. Please try again.")
            case .cancel: return .cancelled
            }
        }
    }
}
