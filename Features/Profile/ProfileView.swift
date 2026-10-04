import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var profile: ProfileStore
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var router: AppRouter
    @State private var pickerItem: PhotosPickerItem?
    @State private var showLogout = false
    @State private var photoError: String?

    var body: some View {
        NavigationStack {
            List {
                Section { header }

                Section("Account") {
                    NavigationLink { EditProfileView() } label: { Label("Edit profile", systemImage: "person.text.rectangle") }
                    NavigationLink { ChangePasswordView() } label: { Label("Change password", systemImage: "lock") }
                    NavigationLink { AddressListView() } label: { Label("Saved addresses", systemImage: "mappin.and.ellipse") }
                }

                Section("Orders & preferences") {
                    Button { router.selectedTab = .orders } label: {
                        HStack { Label("Order history", systemImage: "bag"); Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary) }
                    }
                    .foregroundColor(.primary)
                    NavigationLink { NotificationSettingsView() } label: { Label("Notification settings", systemImage: "bell") }
                }

                Section {
                    Button(role: .destructive) { showLogout = true } label: {
                        Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } footer: {
                    Text("FoodApp 1.0").frame(maxWidth: .infinity).padding(.top, 8)
                }
            }
            .navigationTitle("Profile")
            .confirmationDialog("Log out of FoodApp?", isPresented: $showLogout, titleVisibility: .visible) {
                Button("Log out", role: .destructive) { profile.reset(); session.logout() }
                Button("Cancel", role: .cancel) {}
            }
            .onChange(of: pickerItem) { item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        profile.setPhoto(data); photoError = nil
                    } else { photoError = "Couldn't load that photo. Please try another." }
                    pickerItem = nil
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                AvatarView(photo: profile.photo, initials: profile.initials, size: 76)
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "camera.fill").font(.caption).foregroundColor(.white)
                        .padding(7).background(Color.orange).clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                }
                .accessibilityLabel("Change profile photo")
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.user?.name ?? "Foodie").font(.title3.bold())
                Text(profile.user?.email ?? "").font(.subheadline).foregroundColor(.secondary)
                if let mobile = profile.user?.mobile { Text("📞 \(mobile)").font(.caption).foregroundColor(.secondary) }
                if let error = photoError { Text(error).font(.caption).foregroundColor(.red) }
                if profile.photo != nil {
                    Button("Remove photo") { profile.removePhoto() }.font(.caption).buttonStyle(.borderless)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
