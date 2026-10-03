//
//  HomeViewModel.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    enum State: Equatable { case loading, content, empty, failure(String) }

    @Published private(set) var restaurants: [Restaurant] = []
    @Published private(set) var state: State = .loading
    @Published private(set) var isLoadingMore = false
    @Published var searchText = ""
    @Published private(set) var category: String?
    @Published private(set) var sort: RestaurantSort = .none

    let categories = ["Pizza", "Biryani", "Burger"]

    private let repository: HomeRepositoryProtocol
    private let pageSize = 10          // pagination test માટે થોડીવાર 2 કરો
    private var page = 1
    private var hasMore = true
    private var requestID = 0          // જૂના (stale) response ને ignore કરવા
    private var cancellables = Set<AnyCancellable>()

    init(repository: HomeRepositoryProtocol) {
        self.repository = repository
        // Search debounce: ટાઈપ બંધ થયાના 0.4 સેકન્ડ પછી જ API call
        $searchText
            .dropFirst()
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in Task { await self?.reload() } }
            .store(in: &cancellables)
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
        } catch {
            // શાંતિથી ignore: યુઝર ફરી scroll કરશે તો retry થશે
        }
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
