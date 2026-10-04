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
                    NavigationLink { EditProfileView() } label: { RowLabel("Edit profile", "person.text.rectangle") }
                    NavigationLink { ChangePasswordView() } label: { RowLabel("Change password", "lock.fill") }
                    NavigationLink { AddressListView() } label: { RowLabel("Saved addresses", "mappin.and.ellipse") }
                }

                Section("Orders & preferences") {
                    Button { router.selectedTab = .orders } label: {
                        HStack { RowLabel("Order history", "bag.fill"); Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary) }
                    }
                    .foregroundColor(.primary)
                    NavigationLink { NotificationSettingsView() } label: { RowLabel("Notification settings", "bell.fill") }
                }

                Section {
                    Button(role: .destructive) { showLogout = true } label: {
                        RowLabel("Log out", "rectangle.portrait.and.arrow.right", color: .red)
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

/// Profile ની દરેક row: રંગીન icon-બોક્સ + લખાણ (બધી rows માં સરખો દેખાવ)
struct RowLabel: View {
    let title: String
    let icon: String
    var color: Color = .orange

    init(_ title: String, _ icon: String, color: Color = .orange) {
        self.title = title
        self.icon = icon
        self.color = color
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(title).foregroundColor(color == .red ? .red : .primary)
        }
    }
}
