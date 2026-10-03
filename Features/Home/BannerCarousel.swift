import SwiftUI
import Combine

/// Offer banners: dots banner ની નીચે, દર 4 સેકન્ડે આપોઆપ swipe
struct BannerCarousel: View {
    private struct Banner {
        let title: String, subtitle: String, emoji: String, colors: [Color]
    }
    private let banners = [
        Banner(title: "50% OFF", subtitle: "Use code SAVE20 • up to ₹100", emoji: "🍕", colors: [.orange, .red]),
        Banner(title: "Flat ₹50 OFF", subtitle: "Use code FLAT50 on orders above ₹300", emoji: "🎟️", colors: [.purple, .indigo]),
        Banner(title: "Free delivery", subtitle: "On selected restaurants near you", emoji: "🛵", colors: [.green, .teal])
    ]

    @State private var index = 0
    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            TabView(selection: $index) {
                ForEach(banners.indices, id: \.self) { i in
                    card(banners[i]).tag(i).padding(.horizontal)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 130)

            HStack(spacing: 6) {
                ForEach(banners.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == index ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: i == index ? 18 : 6, height: 6)
                }
            }
            .animation(.easeInOut, value: index)
        }
        .onReceive(timer) { _ in
            withAnimation { index = (index + 1) % banners.count }
        }
    }

    private func card(_ b: Banner) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(b.title).font(.title.bold())
                Text(b.subtitle).font(.subheadline)
            }
            Spacer(minLength: 8)
            Text(b.emoji).font(.system(size: 56))
        }
        .foregroundColor(.white)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(LinearGradient(colors: b.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
