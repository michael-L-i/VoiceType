import Foundation
import VoiceTypeKit

/// Persists `AppSettings` to `UserDefaults` as JSON. Secrets (the Groq API key)
/// never come through here — they live in the Keychain, handled separately.
final class SettingsStore: @unchecked Sendable {
    static let shared = SettingsStore()
    private let key = "voicetype.settings.v1"
    private let defaults = UserDefaults.standard

    func load() -> AppSettings {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return decoded
    }

    func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }
}
