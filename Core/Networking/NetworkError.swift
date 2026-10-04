import Foundation

enum NetworkError: LocalizedError, Equatable {
    case noInternet
    case serverUnreachable
    case unauthorized
    case server(code: Int, message: String?)
    case decoding
    case invalidURL
    case unknown

    var errorDescription: String? {
        switch self {
        case .noInternet: return "No internet connection. Please try again."
        case .serverUnreachable: return "Can't reach the server. Please make sure it is running and try again."
        case .unauthorized: return "Session expired. Please login again."
        case .server(_, let msg): return msg ?? "Something went wrong. Please try later."
        case .decoding: return "Unexpected response from server."
        case .invalidURL: return "Invalid request."
        case .unknown: return "Something went wrong."
        }
    }
}
