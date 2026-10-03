//
//  HomeRepository.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import Foundation

protocol HomeRepositoryProtocol {
    func restaurants(page: Int, limit: Int, category: String?,
                     search: String, sort: RestaurantSort) async throws -> [Restaurant]
}

final class HomeRepository: HomeRepositoryProtocol {
    private let api: APIClientProtocol
    init(api: APIClientProtocol) { self.api = api }

    func restaurants(page: Int, limit: Int, category: String?,
                     search: String, sort: RestaurantSort) async throws -> [Restaurant] {
        try await api.send(.restaurants(page: page, limit: limit, category: category,
                                        search: search, sort: sort))
    }
}
