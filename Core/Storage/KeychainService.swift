import Foundation
import Security

protocol TokenStoring: AnyObject {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    func save(access: String, refresh: String)
    func clear()
}

final class KeychainTokenStore: TokenStoring {
    private let service = "com.example.FoodApp"

    var accessToken: String? { read(key: "access") }
    var refreshToken: String? { read(key: "refresh") }

    func save(access: String, refresh: String) {
        write(key: "access", value: access)
        write(key: "refresh", value: refresh)
    }

    func clear() {
        ["access", "refresh"].forEach { delete(key: $0) }
    }

    private func query(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: key]
    }

    private func write(key: String, value: String) {
        delete(key: key)
        var q = query(key)
        q[kSecValueData as String] = Data(value.utf8)
        q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(q as CFDictionary, nil)
    }

    private func read(key: String) -> String? {
        var q = query(key)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func delete(key: String) { SecItemDelete(query(key) as CFDictionary) }
}
