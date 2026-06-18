import Foundation
import VoiceTypeKit

/// Persists `DictationStats` to `UserDefaults` as JSON. Mirrors `SettingsStore`.
/// Only aggregate counts are stored here — never transcript text or audio.
final class StatsStore: @unchecked Sendable {
    static let shared = StatsStore()
    private let key = "voicetype.stats.v1"
    private let defaults = UserDefaults.standard

    func load() -> DictationStats {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(DictationStats.self, from: data) else {
            return DictationStats()
        }
        return decoded
    }

    func save(_ stats: DictationStats) {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        defaults.set(data, forKey: key)
    }
}
