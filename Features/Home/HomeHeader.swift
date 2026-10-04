import SwiftUI

struct GreetingHeader: View {
    @EnvironmentObject var profile: ProfileStore

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Hi, \(profile.firstName) 👋").font(.title2.bold())
            Text("What are you craving today?").font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

/// ઉપર જમણે નાનો avatar; tap કરતાં Profile tab
struct ProfileAvatarButton: View {
    @EnvironmentObject var profile: ProfileStore
    @EnvironmentObject var router: AppRouter

    var body: some View {
        Button { router.selectedTab = .profile } label: {
            AvatarView(photo: profile.photo, initials: profile.initials, size: 32)
        }
        .accessibilityLabel("Profile")
    }
}
