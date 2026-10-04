import Foundation
import Combine

/// Orders નો status દર થોડી સેકન્ડે તપાસે છે; બદલાય તો notification મોકલે છે.
/// (Production માં આ કામ server → APNs push કરે.)
@MainActor
final class OrderStatusMonitor: ObservableObject {
    private let orders: OrderRepositoryProtocol
    private let notifier: OrderNotifying
    private let isEnabled: @MainActor () -> Bool
    private let interval: UInt64
    private let defaults: UserDefaults
    private var known: [String: String]       // orderId -> છેલ્લો જોયેલો status
    private var task: Task<Void, Never>?
    private let key = "orderStatusSnapshot"

    init(orders: OrderRepositoryProtocol, notifier: OrderNotifying,
         isEnabled: @escaping @MainActor () -> Bool,
         interval: UInt64 = 8_000_000_000, defaults: UserDefaults = .standard) {
        self.orders = orders
        self.notifier = notifier
        self.isEnabled = isEnabled
        self.interval = interval
        self.defaults = defaults
        self.known = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
    }

    func start() {
        guard task == nil else { return }
        task = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.poll()
                try? await Task.sleep(nanoseconds: self.interval)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    func poll() async {
        guard let list = try? await orders.list() else { return }     // network fail → શાંતિથી ફરી પ્રયત્ન
        for order in list {
            let previous = known[order.id]
            known[order.id] = order.status.rawValue
            // પહેલી વાર જોયેલા order માટે notification નહીં (જૂના orders નો ઢગલો ન થાય)
            guard let previous, previous != order.status.rawValue else { continue }
            if isEnabled() { await notifier.notify(order: order) }
        }
        defaults.set(known, forKey: key)
    }
}
