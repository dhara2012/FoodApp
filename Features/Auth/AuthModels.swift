import Foundation

struct MessageResponse: Decodable { let message: String }

struct TokenPair: Decodable {
    let accessToken: String
    let refreshToken: String
}

struct SignupRequest: Equatable {
    let name: String
    let email: String
    let mobile: String
    let password: String
}

extension Error {
    /// User ને બતાવવાનો સરળ message
    var authMessage: String { (self as? NetworkError)?.localizedDescription ?? "Something went wrong." }
}
