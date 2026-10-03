import SwiftUI

extension OrderStatus {
    /// Normal delivery flow (Cancelled આમાં નથી)
    static let flow: [OrderStatus] = [.placed, .confirmed, .preparing, .outForDelivery, .delivered]

    var stepIndex: Int { Self.flow.firstIndex(of: self) ?? -1 }
    var isTerminal: Bool { self == .delivered || self == .cancelled }
    /// Restaurant તૈયારી શરૂ કરે તે પહેલાં જ cancel થઈ શકે
    var canCancel: Bool { self == .placed || self == .confirmed }

    var tint: Color {
        switch self {
        case .placed, .confirmed: return .blue
        case .preparing: return .orange
        case .outForDelivery: return .purple
        case .delivered: return .green
        case .cancelled: return .red
        }
    }
}

extension Order {
    var paymentMethodTitle: String {
        PaymentMethod.allCases.first { $0.apiValue == paymentMethod }?.title ?? paymentMethod.capitalized
    }
    var itemsSummary: String { items.map { "\($0.quantity) × \($0.name)" }.joined(separator: ", ") }
    var dateText: String { createdAt.formatted(date: .abbreviated, time: .shortened) }
}

struct StatusBadge: View {
    let status: OrderStatus
    var body: some View {
        Text(status.title).font(.caption.bold()).foregroundColor(status.tint)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(status.tint.opacity(0.15)).clipShape(Capsule())
    }
}

struct StatusTimeline: View {
    let status: OrderStatus

    var body: some View {
        if status == .cancelled {
            Label("Order cancelled", systemImage: "xmark.circle.fill").foregroundColor(.red)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(OrderStatus.flow.enumerated()), id: \.offset) { index, step in
                    let done = index <= status.stepIndex
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(done ? .green : .gray)
                            if index < OrderStatus.flow.count - 1 {
                                Rectangle()
                                    .fill(index < status.stepIndex ? Color.green : Color.gray.opacity(0.3))
                                    .frame(width: 2, height: 26)
                            }
                        }
                        Text(step.title)
                            .font(index == status.stepIndex ? .subheadline.bold() : .subheadline)
                            .foregroundColor(done ? .primary : .secondary)
                        Spacer()
                    }
                }
            }
        }
    }
}
