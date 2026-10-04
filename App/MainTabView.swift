import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var profile: ProfileStore
    let api: APIClientProtocol

    var body: some View {
        TabView(selection: $router.selectedTab) {
            HomeView(viewModel: HomeViewModel(repository: HomeRepository(api: api)), api: api)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)

            NavigationStack { OrderHistoryView() }
                .tabItem { Label("Orders", systemImage: "bag.fill") }
                .tag(AppTab.orders)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(AppTab.profile)
        }
        .tint(.orange)
        .task { await profile.load() }
    }
}
