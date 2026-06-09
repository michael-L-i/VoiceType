import Foundation
import Security

/// Minimal Keychain-backed secret store. Secrets (the Groq API key) live here,
/// never in UserDefaults and never in the repo. The Groq milestone (task #4)
/// extends this with its settings UI; the read/write primitives are here so the
/// coordinator can fetch the key today.
final class KeychainStore: @unchecked Sendable {
    static let shared = KeychainStore()
    private let service = "com.voicetype.app"

    var groqAPIKey: String? {
        get { read(account: "groq.apiKey") }
        set {
            if let newValue, !newValue.isEmpty { write(newValue, account: "groq.apiKey") }
            else { delete(account: "groq.apiKey") }
        }
    }

    // MARK: - Primitives

    func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data, let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }

    func write(_ value: String, account: String) {
        delete(account: account)
        let attrs: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(value.utf8),
        ]
        SecItemAdd(attrs as CFDictionary, nil)
    }

    func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
