import SwiftUI

@main
struct FoodAppApp: App {
    private let tokenStore: KeychainTokenStore
    private let api: APIClient
    @StateObject private var session: SessionManager
    @StateObject private var services: ServiceContainer
    @StateObject private var profile: ProfileStore
    @StateObject private var notifications: NotificationService
    @StateObject private var monitor: OrderStatusMonitor
    @StateObject private var cart = CartStore()
    @StateObject private var addressBook = AddressBook()
    @StateObject private var router: AppRouter

    init() {
        let store = KeychainTokenStore()
        let client = APIClient(baseURL: URL(string: "http://localhost:3000")!, tokenStore: store)
        let container = ServiceContainer(api: client)
        let profileStore = ProfileStore(repository: container.profile)
        let notificationService = NotificationService()
        let appRouter = AppRouter()

        // Notification tap → Order Details
        notificationService.onOpenOrder = { orderId in appRouter.openOrder(id: orderId) }
        let statusMonitor = OrderStatusMonitor(
            orders: container.orders, notifier: notificationService,
            isEnabled: { profileStore.orderUpdatesEnabled })

        tokenStore = store
        api = client
        _session = StateObject(wrappedValue: SessionManager(tokenStore: store))
        _services = StateObject(wrappedValue: container)
        _profile = StateObject(wrappedValue: profileStore)
        _notifications = StateObject(wrappedValue: notificationService)
        _monitor = StateObject(wrappedValue: statusMonitor)
        _router = StateObject(wrappedValue: appRouter)
    }

    var body: some Scene {
        WindowGroup {
            RootView(api: api, tokenStore: tokenStore)
                .tint(.orange)
                .environmentObject(session)
                .environmentObject(services)
                .environmentObject(profile)
                .environmentObject(notifications)
                .environmentObject(monitor)
                .environmentObject(cart)
                .environmentObject(addressBook)
                .environmentObject(router)
        }
    }
}
