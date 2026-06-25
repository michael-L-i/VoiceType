import Foundation
import VoiceTypeKit

/// Persists `AppSettings` to `UserDefaults` as JSON. Everything runs on-device,
/// so there are no secrets to keep here or anywhere else.
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
