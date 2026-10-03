//
//  RestaurantDetailView.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import SwiftUI

struct RestaurantDetailView: View {
    @StateObject var viewModel: RestaurantDetailViewModel
    @State private var selectedItem: MenuItem?

    var body: some View {
        List {
            Section {
                let r = viewModel.restaurant
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(r.cuisine)").foregroundColor(.secondary)
                        Spacer()
                        Label(String(format: "%.1f", r.rating), systemImage: "star.fill")
                            .font(.caption.bold()).foregroundColor(.white)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(Color.green).clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    Text("\(r.deliveryTimeMin) mins • \(String(format: "%.1f", r.distanceKm)) km • " +
                         (r.deliveryFee == 0 ? "Free delivery" : "\(r.deliveryFee.inr) delivery"))
                        .font(.subheadline).foregroundColor(.secondary)
                    if let offer = r.offer {
                        Label(offer, systemImage: "tag.fill").font(.subheadline.bold()).foregroundColor(.blue)
                    }
                }
                Toggle("Veg only 🟢", isOn: $viewModel.vegOnly)
            }

            switch viewModel.state {
            case .loading:
                ProgressView().frame(maxWidth: .infinity)
            case .failure(let message):
                VStack(spacing: 10) {
                    Text(message)
                    Button("Retry") { Task { await viewModel.load() } }
                }
                .frame(maxWidth: .infinity)
            case .empty:
                Text("No items available").foregroundColor(.secondary)
            case .content:
                if viewModel.sections.isEmpty {
                    Text("No dishes match your search").foregroundColor(.secondary)
                }
                ForEach(viewModel.sections, id: \.title) { section in
                    Section("\(section.title) (\(section.items.count))") {
                        ForEach(section.items) { item in
                            MenuItemRow(item: item) { selectedItem = item }
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.restaurant.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top, spacing: 0) {
            SearchBar(text: $viewModel.searchText, prompt: "Search in menu")
        }
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { CartButton() } }
        .safeAreaInset(edge: .bottom) { FloatingCartBar() }
        .task { if viewModel.state == .loading { await viewModel.load() } }
        .sheet(item: $selectedItem) { item in
            ProductDetailView(viewModel: ProductDetailViewModel(item: item),
                              restaurant: viewModel.restaurant)
        }
    }
}

struct MenuItemRow: View {
    let item: MenuItem
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                VegBadge(isVeg: item.isVeg)
                Text(item.name).font(.headline)
                Text(item.price.inr).font(.subheadline)
                Text(item.description).font(.caption).foregroundColor(.secondary).lineLimit(2)
                if !item.variants.isEmpty || !item.addOns.isEmpty {
                    Text("Customisable").font(.caption2).foregroundColor(.orange)
                }
            }
            Spacer()
            VStack(spacing: 6) {
                EmojiTile(emoji: item.emoji, size: 80, seed: item.id)
                Button(action: onAdd) {
                    Text("ADD").font(.subheadline.bold()).foregroundColor(.green)
                        .padding(.horizontal, 22).padding(.vertical, 5)
                        .background(Color(.systemBackground))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green))
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
}

struct VegBadge: View {
    let isVeg: Bool
    var body: some View {
        let color: Color = isVeg ? .green : .red
        RoundedRectangle(cornerRadius: 3)
            .stroke(color, lineWidth: 1.5)
            .frame(width: 16, height: 16)
            .overlay(Circle().fill(color).frame(width: 8, height: 8))
            .accessibilityLabel(isVeg ? "Vegetarian" : "Non vegetarian")
    }
}
