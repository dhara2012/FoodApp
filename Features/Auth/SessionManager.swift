//
//  SessionManager.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var isLoggedIn: Bool
    private let tokenStore: TokenStoring

    init(tokenStore: TokenStoring) {
        self.tokenStore = tokenStore
        self.isLoggedIn = tokenStore.accessToken != nil   // app reopen પર login જળવાય
    }

    func didLogin() { isLoggedIn = true }

    func logout() {
        tokenStore.clear()
        isLoggedIn = false
    }
}
