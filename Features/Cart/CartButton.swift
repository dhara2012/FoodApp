//
//  CartButton.swift
//  FoodApp
//
//  Created by Shubham Trivedi on 03/10/26.
//

import SwiftUI

struct CartButton: View {
    @EnvironmentObject var cart: CartStore
    @State private var showCart = false

    var body: some View {
        let count = cart.itemCount
        Button { showCart = true } label: {
            // Badge બટનની અંદર જ રાખ્યો છે, જેથી toolbar માં કપાય નહીં
            ZStack(alignment: .topTrailing) {
                Image(systemName: "cart")
                    .frame(width: 36, height: 36)
                if count > 0 {
                    Text(count > 9 ? "9+" : "\(count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Capsule().fill(Color.red))
                        .padding(.top, 1).padding(.trailing, 1)
                }
            }
        }
        .accessibilityLabel("Cart, \(count) items")
        .sheet(isPresented: $showCart) { CartView() }
    }
}
