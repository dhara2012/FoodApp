import Foundation

enum HTTPMethod: String { case get = "GET", post = "POST", put = "PUT", delete = "DELETE" }

struct Endpoint {
    let path: String
    var method: HTTPMethod = .get
    var query: [URLQueryItem] = []
    var body: Data? = nil
    var requiresAuth: Bool = true
    var idempotencyKey: String? = nil   // used for place-order to avoid duplicates
    
    static func login(email: String, password: String) -> Endpoint {
        Endpoint(path: "/auth/login", method: .post,
                 body: try? JSONEncoder().encode(["email": email, "password": password]),
                 requiresAuth: false)
    }
    
    static func restaurants(page: Int, limit: Int = 10, category: String? = nil,
                            search: String = "", sort: RestaurantSort = .none) -> Endpoint {
        var items = [URLQueryItem(name: "_page", value: "\(page)"),
                     URLQueryItem(name: "_limit", value: "\(limit)")]
        if let category { items.append(URLQueryItem(name: "cuisine", value: category)) }
        if !search.isEmpty { items.append(URLQueryItem(name: "q", value: search)) }
        items += sort.queryItems
        return Endpoint(path: "/restaurants", query: items)
    }
}
