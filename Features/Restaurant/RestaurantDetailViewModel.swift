//
//  RestaurantDetailViewModel.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import Foundation
import Combine

@MainActor
final class RestaurantDetailViewModel: ObservableObject {
    enum State: Equatable { case loading, content, empty, failure(String) }

    let restaurant: Restaurant
    @Published private(set) var items: [MenuItem] = []
    @Published private(set) var state: State = .loading
    @Published var vegOnly = false
    @Published var searchText = ""

    private let repository: MenuRepositoryProtocol

    init(restaurant: Restaurant, repository: MenuRepositoryProtocol) {
        self.restaurant = restaurant
        self.repository = repository
    }

    var visibleItems: [MenuItem] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return items.filter { item in
            (!vegOnly || item.isVeg) &&
            (q.isEmpty || item.name.lowercased().contains(q) || (item.category ?? "").lowercased().contains(q))
        }
    }

    /// Menu ને category પ્રમાણે group (items ના ક્રમ પ્રમાણે)
    var sections: [(title: String, items: [MenuItem])] {
        var order: [String] = []
        var groups: [String: [MenuItem]] = [:]
        for item in visibleItems {
            let key = item.category ?? "Menu"
            if groups[key] == nil { order.append(key) }
            groups[key, default: []].append(item)
        }
        return order.map { ($0, groups[$0] ?? []) }
    }

    func load() async {
        state = .loading
        do {
            items = try await repository.menu(restaurantId: restaurant.id)
            state = items.isEmpty ? .empty : .content
        } catch {
            state = .failure((error as? NetworkError)?.localizedDescription ?? "Something went wrong.")
        }
    }
}
