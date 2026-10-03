//
//  HomeViewModel.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import Foundation
import Combine

struct FoodCategory: Identifiable, Hashable {
    let name: String
    let emoji: String
    var id: String { name }
}

struct PopularSelection: Identifiable {
    let item: MenuItem
    let restaurant: Restaurant
    var id: Int { item.id }
}

@MainActor
final class HomeViewModel: ObservableObject {
    enum State: Equatable { case loading, content, empty, failure(String) }

    @Published private(set) var restaurants: [Restaurant] = []
    @Published private(set) var popularItems: [MenuItem] = []
    @Published private(set) var state: State = .loading
    @Published private(set) var isLoadingMore = false
    @Published var searchText = ""
    @Published private(set) var category: String?
    @Published private(set) var sort: RestaurantSort = .none
    @Published var popularSelection: PopularSelection?

    let categories = [FoodCategory(name: "Pizza", emoji: "🍕"), FoodCategory(name: "Biryani", emoji: "🍛"),
                      FoodCategory(name: "Burger", emoji: "🍔"), FoodCategory(name: "Chinese", emoji: "🥡"),
                      FoodCategory(name: "South Indian", emoji: "🥞"), FoodCategory(name: "Desserts", emoji: "🍰"),
                      FoodCategory(name: "Healthy", emoji: "🥗"), FoodCategory(name: "Rolls", emoji: "🌯")]

    private let repository: HomeRepositoryProtocol
    private let pageSize = 10
    private var page = 1
    private var hasMore = true
    private var requestID = 0
    private var cancellables = Set<AnyCancellable>()

    init(repository: HomeRepositoryProtocol) {
        self.repository = repository
        $searchText
            .dropFirst()
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in Task { await self?.reload() } }
            .store(in: &cancellables)
    }

    var isFiltering: Bool {
        category != nil || !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func reload(showSpinner: Bool = true) async {
        requestID += 1
        let id = requestID
        page = 1
        hasMore = true
        if showSpinner { state = .loading }
        do {
            let result = try await fetch(page: 1)
            guard id == requestID else { return }
            restaurants = result
            hasMore = result.count == pageSize
            state = result.isEmpty ? .empty : .content
        } catch {
            guard id == requestID, !Task.isCancelled else { return }
            state = .failure((error as? NetworkError)?.localizedDescription ?? "Something went wrong.")
        }
    }

    func loadMoreIfNeeded(current restaurant: Restaurant) async {
        guard hasMore, !isLoadingMore, restaurant.id == restaurants.last?.id else { return }
        isLoadingMore = true
        let id = requestID
        defer { isLoadingMore = false }
        do {
            let next = try await fetch(page: page + 1)
            guard id == requestID else { return }
            page += 1
            restaurants += next
            hasMore = next.count == pageSize
        } catch { /* શાંતિથી ignore; ફરી scroll કરતાં retry થશે */ }
    }

    func loadPopular() async {
        popularItems = (try? await repository.popularItems()) ?? popularItems
    }

    func openPopular(_ item: MenuItem) async {
        guard let restaurant = try? await repository.restaurant(id: item.restaurantId) else { return }
        popularSelection = PopularSelection(item: item, restaurant: restaurant)
    }

    func toggleCategory(_ name: String) async {
        category = (category == name) ? nil : name
        await reload()
    }

    func changeSort(_ option: RestaurantSort) async {
        sort = option
        await reload()
    }

    private func fetch(page: Int) async throws -> [Restaurant] {
        try await repository.restaurants(
            page: page, limit: pageSize, category: category,
            search: searchText.trimmingCharacters(in: .whitespaces), sort: sort)
    }
}
