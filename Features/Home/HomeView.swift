//
//  HomeView.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @EnvironmentObject var session: SessionManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryBar
                content
            }
            .navigationTitle("Restaurants")
            .searchable(text: $viewModel.searchText, prompt: "Search restaurants or cuisine")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") { session.logout() }
                }
                ToolbarItem(placement: .navigationBarTrailing) { sortMenu }
            }
        }
        .task { if viewModel.restaurants.isEmpty { await viewModel.reload() } }
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.categories, id: \.self) { name in
                    let selected = viewModel.category == name
                    Button { Task { await viewModel.toggleCategory(name) } } label: {
                        Text(name)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(selected ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundColor(selected ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal).padding(.vertical, 8)
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(RestaurantSort.allCases) { option in
                Button { Task { await viewModel.changeSort(option) } } label: {
                    if viewModel.sort == option {
                        Label(option.title, systemImage: "checkmark")
                    } else {
                        Text(option.title)
                    }
                }
            }
        } label: { Image(systemName: "arrow.up.arrow.down") }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failure(let message):
            VStack(spacing: 12) {
                Text(message).multilineTextAlignment(.center)
                Button("Retry") { Task { await viewModel.reload() } }
                    .buttonStyle(.borderedProminent)
            }
            .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            Text("No restaurants found").foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .content:
            List {
                ForEach(viewModel.restaurants) { restaurant in
                    RestaurantRow(restaurant: restaurant)
                        .task { await viewModel.loadMoreIfNeeded(current: restaurant) }
                }
                if viewModel.isLoadingMore {
                    ProgressView().frame(maxWidth: .infinity)
                }
            }
            .listStyle(.plain)
            .refreshable { await viewModel.reload(showSpinner: false) }
        }
    }
}

struct RestaurantRow: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
                .frame(width: 72, height: 72)
                .overlay(Image(systemName: "fork.knife").foregroundColor(.secondary))

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name).font(.headline)
                Text(restaurant.cuisine).font(.subheadline).foregroundColor(.secondary)
                HStack(spacing: 10) {
                    Label(String(format: "%.1f", restaurant.rating), systemImage: "star.fill")
                        .foregroundColor(.orange)
                    Text("\(restaurant.deliveryTimeMin) min")
                    Text(String(format: "%.1f km", restaurant.distanceKm))
                    Text("₹\(restaurant.deliveryFee) delivery")
                }
                .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
