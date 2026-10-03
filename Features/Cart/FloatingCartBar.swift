import SwiftUI

/// Swiggy જેવો નીચેનો "View Cart" bar
struct FloatingCartBar: View {
    @EnvironmentObject var cart: CartStore
    @State private var showCart = false

    var body: some View {
        Group {
            if cart.itemCount > 0 {
                Button { showCart = true } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(cart.itemCount) item\(cart.itemCount > 1 ? "s" : "") • \(cart.breakdown.itemTotal.inr)")
                                .font(.subheadline.bold())
                            Text(cart.restaurantName).font(.caption).opacity(0.85)
                        }
                        Spacer()
                        Text("View Cart ›").font(.subheadline.bold())
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal).padding(.bottom, 6)
                }
            }
        }
        .sheet(isPresented: $showCart) { CartView() }
    }
}
