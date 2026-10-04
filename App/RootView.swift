import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionManager
    let api: APIClientProtocol
    let tokenStore: TokenStoring

    var body: some View {
        if session.isLoggedIn {
            MainTabView(api: api)
        } else {
            let repository = AuthRepository(api: api, tokenStore: tokenStore)
            NavigationStack {
                LoginView(viewModel: LoginViewModel(repository: repository), repository: repository)
            }
        }
    }
}
