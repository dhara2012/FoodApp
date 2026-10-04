import Foundation

extension Notification.Name {
    /// Refresh token પણ expire થાય ત્યારે post થાય; SessionManager logout કરે
    static let sessionExpired = Notification.Name("sessionExpired")
}

protocol APIClientProtocol {
    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

final class APIClient: APIClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let tokenStore: TokenStoring
    private let decoder: JSONDecoder

    init(baseURL: URL, session: URLSession = .shared, tokenStore: TokenStoring) {
        self.baseURL = baseURL
        self.session = session
        self.tokenStore = tokenStore
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        do {
            return try await perform(endpoint)
        } catch NetworkError.unauthorized where endpoint.requiresAuth {
            // Access token expire → refresh token થી નવો લઈ એક જ વાર retry
            guard await refreshTokens() else { throw NetworkError.unauthorized }
            return try await perform(endpoint)
        }
    }

    private func perform<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try makeRequest(endpoint)
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw NetworkError.unknown }
            switch http.statusCode {
            case 200...299:
                do { return try decoder.decode(T.self, from: data) }
                catch { throw NetworkError.decoding }
            case 401 where endpoint.requiresAuth:
                throw NetworkError.unauthorized
            case 401 where endpoint.path == "/auth/login":
                throw NetworkError.unauthorized          // ખોટા credentials
            default:
                throw NetworkError.server(code: http.statusCode, message: serverMessage(from: data))
            }
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError where error.code == .notConnectedToInternet
                                          || error.code == .networkConnectionLost
                                          || error.code == .cannotConnectToHost {
            throw NetworkError.noInternet
        } catch let error as URLError where error.code == .cannotConnectToHost
                    || error.code == .cannotFindHost
                    || error.code == .timedOut {
            throw NetworkError.serverUnreachable
        } catch {
            throw NetworkError.unknown
        }
    }

    private func refreshTokens() async -> Bool {
        guard let refresh = tokenStore.refreshToken else { expireSession(); return false }
        do {
            let pair: TokenPair = try await perform(.refresh(refreshToken: refresh))
            tokenStore.save(access: pair.accessToken, refresh: pair.refreshToken)
            return true
        } catch {
            expireSession()
            return false
        }
    }

    private func expireSession() {
        tokenStore.clear()
        NotificationCenter.default.post(name: .sessionExpired, object: nil)
    }

    /// Server નો {"message": "..."} user ને બતાવવા
    private func serverMessage(from data: Data) -> String? {
        (try? JSONDecoder().decode(MessageResponse.self, from: data))?.message
    }

    private func makeRequest(_ endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path),
                                       resolvingAgainstBaseURL: false)
        components?.queryItems = endpoint.query.isEmpty ? nil : endpoint.query
        guard let url = components?.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if endpoint.requiresAuth, let token = tokenStore.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let key = endpoint.idempotencyKey {
            request.setValue(key, forHTTPHeaderField: "Idempotency-Key")
        }
        return request
    }
}
