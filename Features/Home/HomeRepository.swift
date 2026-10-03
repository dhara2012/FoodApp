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
    func popularItems() async throws -> [MenuItem]
    func restaurant(id: Int) async throws -> Restaurant
}

final class HomeRepository: HomeRepositoryProtocol {
    private let api: APIClientProtocol
    init(api: APIClientProtocol) { self.api = api }

    func restaurants(page: Int, limit: Int, category: String?,
                     search: String, sort: RestaurantSort) async throws -> [Restaurant] {
        try await api.send(.restaurants(page: page, limit: limit, category: category,
                                        search: search, sort: sort))
    }
    func popularItems() async throws -> [MenuItem] { try await api.send(.popularItems()) }
    func restaurant(id: Int) async throws -> Restaurant { try await api.send(.restaurant(id: id)) }
}
