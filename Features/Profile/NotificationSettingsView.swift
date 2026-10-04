import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject var profile: ProfileStore
    @EnvironmentObject var notifications: NotificationService
    @Environment(\.openURL) private var openURL

    var body: some View {
        Form {
            Section { permissionRow } header: { Text("Permission") } footer: {
                Text("Notifications tell you when your order is confirmed, being prepared, out for delivery and delivered.")
            }

            Section {
                Toggle("Order updates", isOn: $profile.orderUpdatesEnabled)
            } footer: {
                Text("Confirmed, preparing, out for delivery and delivered.")
            }
            Section {
                Toggle("Offers & promotions", isOn: $profile.offersEnabled)
            } footer: {
                Text("Deals and coupon codes from restaurants near you.")
            }

            if notifications.isAuthorized {
                Section {
                    Button("Send a test notification") { Task { await notifications.sendTest() } }
                } footer: {
                    Text("You'll get a notification in a couple of seconds.")
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task { await notifications.refreshStatus() }
        // Settings થી પાછા આવતાં status ફરી તપાસો
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await notifications.refreshStatus() }
        }
    }

    @ViewBuilder
    private var permissionRow: some View {
        switch notifications.status {
        case .authorized, .provisional, .ephemeral:
            Label("Notifications are on", systemImage: "checkmark.circle.fill").foregroundColor(.green)
        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                Label("Notifications are turned off", systemImage: "bell.slash.fill").foregroundColor(.red)
                Text("Turn them on in iPhone Settings to get order updates.")
                    .font(.footnote).foregroundColor(.secondary)
                Button("Open iPhone Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
        case .notDetermined:
            VStack(alignment: .leading, spacing: 8) {
                Label("Notifications are not enabled yet", systemImage: "bell.badge").foregroundColor(.orange)
                Button("Allow notifications") { Task { await notifications.requestPermission() } }
            }
        @unknown default:
            EmptyView()
        }
    }
}
