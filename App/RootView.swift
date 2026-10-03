//
//  RootView.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionManager
    let api: APIClientProtocol
    let tokenStore: TokenStoring

    var body: some View {
        if session.isLoggedIn {
            HomeView(viewModel: HomeViewModel(repository: HomeRepository(api: api)))
        } else {
            LoginView(viewModel: LoginViewModel(
                repository: AuthRepository(api: api, tokenStore: tokenStore)))
        }
    }
}
