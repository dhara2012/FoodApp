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
    private var cancellables = Set<AnyCancellable>()

    init(tokenStore: TokenStoring) {
        self.tokenStore = tokenStore
        self.isLoggedIn = tokenStore.accessToken != nil   // app ફરી ખોલતાં login જળવાય

        // Refresh token પણ expire થાય તો આપોઆપ Login screen
        NotificationCenter.default.publisher(for: .sessionExpired)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.isLoggedIn = false }
            .store(in: &cancellables)
    }

    func didLogin() { isLoggedIn = true }

    func logout() {
        tokenStore.clear()
        isLoggedIn = false
    }
}
