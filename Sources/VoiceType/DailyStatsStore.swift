import Foundation
import VoiceTypeKit

/// Persists `DailyStatsLog` to `UserDefaults` as JSON. Mirrors `StatsStore`.
/// Per-day rows are tiny (a few ints per day, ~400 days), so UserDefaults is the
/// right home — far under any practical size limit. Only aggregate counts are
/// stored here; never transcript text or audio.
final class DailyStatsStore: @unchecked Sendable {
    static let shared = DailyStatsStore()
    private let key = "voicetype.dailyStats.v1"
    private let defaults = UserDefaults.standard

    func load() -> DailyStatsLog {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(DailyStatsLog.self, from: data) else {
            return DailyStatsLog()
        }
        return decoded
    }

    func save(_ log: DailyStatsLog) {
        guard let data = try? JSONEncoder().encode(log) else { return }
        defaults.set(data, forKey: key)
    }
}
