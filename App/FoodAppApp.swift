import SwiftUI

@main
struct FoodAppApp: App {
    private let tokenStore: KeychainTokenStore
    private let api: APIClient
    @StateObject private var session: SessionManager
    @StateObject private var cart = CartStore()

    init() {
        let store = KeychainTokenStore()
        tokenStore = store
        api = APIClient(baseURL: URL(string: "http://localhost:3000")!, tokenStore: store)
        _session = StateObject(wrappedValue: SessionManager(tokenStore: store))
    }

    var body: some Scene {
        WindowGroup {
            RootView(api: api, tokenStore: tokenStore)
                .environmentObject(session)
                .environmentObject(cart)
        }
    }
}
