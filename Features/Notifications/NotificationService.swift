import Foundation
import Combine
import UserNotifications

protocol OrderNotifying {
    func notify(order: Order) async
}

/// Permission, local notification મોકલવી અને notification tap handle કરવું
@MainActor
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate, OrderNotifying {
    @Published private(set) var status: UNAuthorizationStatus = .notDetermined
    /// Notification tap → ક્યા order ખોલવો (App માં router સાથે જોડાય છે)
    var onOpenOrder: (@MainActor (String) -> Void)?

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self      // App શરૂ થતાં જ set, જેથી notification થી launch થાય તો પણ tap મળે
        Task { await refreshStatus() }
    }

    var isAuthorized: Bool { status == .authorized || status == .provisional || status == .ephemeral }

    func refreshStatus() async {
        status = await center.notificationSettings().authorizationStatus
    }

    @discardableResult
    func requestPermission() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await refreshStatus()
        return granted
    }

    /// પહેલો order મૂક્યા પછી (યોગ્ય સમયે) permission પૂછવા
    func requestPermissionIfUndetermined() async {
        await refreshStatus()
        if status == .notDetermined { await requestPermission() }
    }

    func notify(order: Order) async {
        await refreshStatus()
        guard isAuthorized, let text = OrderNotification.content(for: order) else { return }
        let content = UNMutableNotificationContent()
        content.title = text.title
        content.body = text.body
        content.sound = .default
        content.userInfo = ["orderId": order.id]
        let request = UNNotificationRequest(
            identifier: "\(order.id)-\(order.status.rawValue)",     // એક status ની એક જ notification
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        try? await center.add(request)
    }

    /// Settings માંથી test notification
    func sendTest() async {
        await refreshStatus()
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "Test notification 🔔"
        content.body = "Notifications are working."
        content.sound = .default
        try? await center.add(UNNotificationRequest(
            identifier: "test-\(UUID().uuidString)", content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)))
    }

    // MARK: UNUserNotificationCenterDelegate

    /// App ખુલ્લી હોય ત્યારે પણ banner બતાવો
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    /// Notification tap → સંબંધિત Order Details
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        guard let orderId = response.notification.request.content.userInfo["orderId"] as? String else { return }
        await MainActor.run { self.onOpenOrder?(orderId) }
    }
}
