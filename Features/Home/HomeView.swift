//
//  HomeView.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    let api: APIClientProtocol
    @EnvironmentObject var session: SessionManager

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    if !viewModel.isFiltering { GreetingHeader(); BannerCarousel() }
                    categoryRow
                    if !viewModel.isFiltering && !viewModel.popularItems.isEmpty { popularSection }
                    restaurantsSection
                }
                .padding(.vertical, 8)
            }
            .refreshable {
                await viewModel.reload(showSpinner: false)
                await viewModel.loadPopular()
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                SearchBar(text: $viewModel.searchText, prompt: "Search restaurant or cuisine")
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { AddressHeaderButton() }
                ToolbarItemGroup(placement: .navigationBarTrailing) { CartButton(); ProfileAvatarButton() }
            }
            .safeAreaInset(edge: .bottom) { FloatingCartBar() }
            .sheet(item: $viewModel.popularSelection) { selection in
                ProductDetailView(viewModel: ProductDetailViewModel(item: selection.item),
                                  restaurant: selection.restaurant)
            }
        }
        .task {
            if viewModel.restaurants.isEmpty {
                await viewModel.reload()
                await viewModel.loadPopular()
            }
        }
    }

    // MARK: Categories
    private var categoryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(viewModel.categories) { cat in
                    let selected = viewModel.category == cat.name
                    Button { Task { await viewModel.toggleCategory(cat.name) } } label: {
                        VStack(spacing: 6) {
                            Text(cat.emoji).font(.system(size: 30))
                                .frame(width: 62, height: 62)
                                .background(selected ? Color.orange.opacity(0.25) : Color(.secondarySystemBackground))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(selected ? Color.orange : .clear, lineWidth: 2))
                            Text(cat.name).font(.caption.weight(selected ? .bold : .regular))
                                .foregroundColor(.primary)
                                .lineLimit(1).minimumScaleFactor(0.8)
                                .frame(width: 76)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
        }
    }

    // MARK: Popular dishes
    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Popular dishes 🔥").font(.title3.bold()).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.popularItems) { item in
                        Button { Task { await viewModel.openPopular(item) } } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                EmojiTile(emoji: item.emoji, size: 110, seed: item.id)
                                HStack(spacing: 4) { VegBadge(isVeg: item.isVeg)
                                    Text(item.name).font(.subheadline.bold()).lineLimit(1) }
                                Text(item.restaurantName ?? "").font(.caption).foregroundColor(.secondary).lineLimit(1)
                                Text(item.price.inr).font(.subheadline).foregroundColor(.primary)
                            }
                            .frame(width: 130, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: Restaurants
    @ViewBuilder
    private var restaurantsSection: some View {
        HStack {
            Text(viewModel.isFiltering ? "Results" : "Restaurants near you").font(.title3.bold())
            Spacer()
            sortMenu
        }
        .padding(.horizontal)

        switch viewModel.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
        case .failure(let message):
            VStack(spacing: 12) {
                Text(message).multilineTextAlignment(.center)
                Button("Retry") { Task { await viewModel.reload() } }.buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity).padding()
        case .empty:
            VStack(spacing: 6) {
                Text("🍽️").font(.system(size: 44))
                Text("No restaurants found").font(.headline)
                Text("Try a different search or category").font(.subheadline).foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity).padding(.top, 30)
        case .content:
            ForEach(viewModel.restaurants) { restaurant in
                NavigationLink {
                    RestaurantDetailView(viewModel: RestaurantDetailViewModel(
                        restaurant: restaurant, repository: MenuRepository(api: api)))
                } label: {
                    RestaurantCard(restaurant: restaurant)
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
                .task { await viewModel.loadMoreIfNeeded(current: restaurant) }
            }
            if viewModel.isLoadingMore { ProgressView().frame(maxWidth: .infinity) }
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(RestaurantSort.allCases) { option in
                Button { Task { await viewModel.changeSort(option) } } label: {
                    if viewModel.sort == option { Label(option.title, systemImage: "checkmark") }
                    else { Text(option.title) }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down").font(.subheadline)
        }
    }
}

// MARK: - Restaurant card
struct RestaurantCard: View {
    let restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                EmojiTile(emoji: restaurant.emoji, size: 140, seed: restaurant.id, fillWidth: true)
                if let offer = restaurant.offer {
                    Text(offer).font(.caption.bold()).foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.blue).clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(8)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(restaurant.name).font(.headline)
                    Spacer()
                    Label(String(format: "%.1f", restaurant.rating), systemImage: "star.fill")
                        .font(.caption.bold()).foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Color.green).clipShape(RoundedRectangle(cornerRadius: 6))
                }
                Text("\(restaurant.cuisine) • \(String(format: "%.1f", restaurant.distanceKm)) km")
                    .font(.subheadline).foregroundColor(.secondary)
                Text("\(restaurant.deliveryTimeMin) mins • " +
                     (restaurant.deliveryFee == 0 ? "Free delivery" : "\(restaurant.deliveryFee.inr) delivery"))
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.10), radius: 6, y: 2)
    }
}
