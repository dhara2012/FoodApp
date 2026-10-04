import Foundation

enum HTTPMethod: String { case get = "GET", post = "POST", put = "PUT", delete = "DELETE" }

struct Endpoint {
    let path: String
    var method: HTTPMethod = .get
    var query: [URLQueryItem] = []
    var body: Data? = nil
    var requiresAuth: Bool = true
    var idempotencyKey: String? = nil   // place-order માં duplicate અટકાવવા

    private static func json(_ dict: [String: String]) -> Data? { try? JSONEncoder().encode(dict) }

    // MARK: Auth
    static func login(email: String, password: String) -> Endpoint {
        Endpoint(path: "/auth/login", method: .post,
                 body: json(["email": email, "password": password]), requiresAuth: false)
    }
    static func signup(name: String, email: String, mobile: String, password: String) -> Endpoint {
        Endpoint(path: "/auth/signup", method: .post,
                 body: json(["name": name, "email": email, "mobile": mobile, "password": password]),
                 requiresAuth: false)
    }
    static func verifyOTP(email: String, otp: String) -> Endpoint {
        Endpoint(path: "/auth/verify-otp", method: .post,
                 body: json(["email": email, "otp": otp]), requiresAuth: false)
    }
    static func resendOTP(email: String) -> Endpoint {
        Endpoint(path: "/auth/resend-otp", method: .post, body: json(["email": email]), requiresAuth: false)
    }
    static func forgotPassword(email: String) -> Endpoint {
        Endpoint(path: "/auth/forgot-password", method: .post, body: json(["email": email]), requiresAuth: false)
    }
    static func resetPassword(email: String, otp: String, newPassword: String) -> Endpoint {
        Endpoint(path: "/auth/reset-password", method: .post,
                 body: json(["email": email, "otp": otp, "new_password": newPassword]), requiresAuth: false)
    }
    static func refresh(refreshToken: String) -> Endpoint {
        Endpoint(path: "/auth/refresh", method: .post,
                 body: json(["refresh_token": refreshToken]), requiresAuth: false)
    }

    // MARK: Profile
    static func profile() -> Endpoint { Endpoint(path: "/profile") }
    static func updateProfile(name: String, mobile: String) -> Endpoint {
        Endpoint(path: "/profile", method: .put, body: json(["name": name, "mobile": mobile]))
    }
    static func changePassword(current: String, new: String) -> Endpoint {
        Endpoint(path: "/profile/change-password", method: .post,
                 body: json(["current_password": current, "new_password": new]))
    }

    // MARK: Orders
    static func createOrder(_ request: OrderRequest, idempotencyKey: String) -> Endpoint {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return Endpoint(path: "/orders", method: .post, body: try? encoder.encode(request),
                        idempotencyKey: idempotencyKey)
    }
    static func orders() -> Endpoint { Endpoint(path: "/orders") }
    static func order(id: String) -> Endpoint { Endpoint(path: "/orders/\(id)") }
    static func cancelOrder(id: String) -> Endpoint { Endpoint(path: "/orders/\(id)/cancel", method: .post) }

    // MARK: Restaurants
    static func restaurants(page: Int, limit: Int = 10, category: String? = nil,
                            search: String = "", sort: RestaurantSort = .none) -> Endpoint {
        var items = [URLQueryItem(name: "_page", value: "\(page)"),
                     URLQueryItem(name: "_limit", value: "\(limit)")]
        if let category { items.append(URLQueryItem(name: "cuisine", value: category)) }
        if !search.isEmpty { items.append(URLQueryItem(name: "q", value: search)) }
        items += sort.queryItems
        return Endpoint(path: "/restaurants", query: items)
    }

    static func restaurant(id: Int) -> Endpoint { Endpoint(path: "/restaurants/\(id)") }

    static func menu(restaurantId: Int) -> Endpoint {
        Endpoint(path: "/menu", query: [URLQueryItem(name: "restaurant_id", value: "\(restaurantId)")])
    }

    static func popularItems(limit: Int = 8) -> Endpoint {
        Endpoint(path: "/menu", query: [URLQueryItem(name: "is_popular", value: "true"),
                                        URLQueryItem(name: "_limit", value: "\(limit)")])
    }
}
