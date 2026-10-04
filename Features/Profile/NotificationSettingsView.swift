import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var profile: ProfileStore

    var body: some View {
        Form {
            Section {
                Toggle("Order updates", isOn: $profile.orderUpdatesEnabled)
            } footer: {
                Text("Get notified when your order is confirmed, being prepared, out for delivery and delivered.")
            }
            Section {
                Toggle("Offers & promotions", isOn: $profile.offersEnabled)
            } footer: {
                Text("Deals and coupon codes from restaurants near you.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
