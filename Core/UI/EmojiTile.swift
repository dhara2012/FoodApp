import SwiftUI

/// Photo ની જગ્યાએ emoji + gradient (network વગર પણ સુંદર દેખાય)
struct EmojiTile: View {
    let emoji: String?
    var size: CGFloat = 64
    var seed: Int = 0
    var fillWidth = false

    private static let palette: [[Color]] = [[.orange, .red], [.pink, .purple], [.green, .teal],
                                             [.blue, .indigo], [.yellow, .orange], [.mint, .green]]
    var body: some View {
        let colors = Self.palette[abs(seed) % Self.palette.count].map { $0.opacity(0.30) }
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            Text(emoji ?? "🍽️").font(.system(size: size * 0.5))
        }
        .frame(maxWidth: fillWidth ? .infinity : size, minHeight: size, maxHeight: size)
        .frame(width: fillWidth ? nil : size)
    }
}
