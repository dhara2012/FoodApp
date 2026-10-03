//
//  MenuRepository.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import Foundation

protocol MenuRepositoryProtocol {
    func menu(restaurantId: Int) async throws -> [MenuItem]
}

final class MenuRepository: MenuRepositoryProtocol {
    private let api: APIClientProtocol
    init(api: APIClientProtocol) { self.api = api }

    func menu(restaurantId: Int) async throws -> [MenuItem] {
        try await api.send(.menu(restaurantId: restaurantId))
    }
}
