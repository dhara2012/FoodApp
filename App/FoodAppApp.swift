import SwiftUI

@main
struct FoodAppApp: App {
    private let tokenStore: KeychainTokenStore
    private let api: APIClient
    @StateObject private var session: SessionManager
    @StateObject private var services: ServiceContainer
    @StateObject private var profile: ProfileStore
    @StateObject private var cart = CartStore()
    @StateObject private var addressBook = AddressBook()
    @StateObject private var router = AppRouter()

    init() {
        let store = KeychainTokenStore()
        let client = APIClient(baseURL: URL(string: "http://localhost:3000")!, tokenStore: store)
        let container = ServiceContainer(api: client)
        tokenStore = store
        api = client
        _session = StateObject(wrappedValue: SessionManager(tokenStore: store))
        _services = StateObject(wrappedValue: container)
        _profile = StateObject(wrappedValue: ProfileStore(repository: container.profile))
    }

    var body: some Scene {
        WindowGroup {
            RootView(api: api, tokenStore: tokenStore)
                .tint(.orange)   // આખી app માં એક જ accent color
                .environmentObject(session)
                .environmentObject(services)
                .environmentObject(profile)
                .environmentObject(cart)
                .environmentObject(addressBook)
                .environmentObject(router)
        }
    }
}
