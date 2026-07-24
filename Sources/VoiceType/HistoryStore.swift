import Foundation
import VoiceTypeKit

/// Persists dictation transcripts to a JSON file in Application Support. Unlike
/// stats (tiny, in UserDefaults), records hold full transcript text and there can
/// be many, so they live in their own file. Transcripts are kept on-device only —
/// never synced or uploaded.
///
/// Writes happen off the main thread on a serial queue (ordered, non-blocking)
/// and are atomic, so a crash mid-write can never corrupt the file — at worst the
/// last record isn't yet on disk.
final class HistoryStore: @unchecked Sendable {
    static let shared = HistoryStore()
    private let filename = "history.v1.json"
    private let cap = 1000
    private let queue = DispatchQueue(label: "com.voicetype.history.io", qos: .utility)

    /// Versioned envelope so the schema can evolve without breaking old files.
    private struct StoredFile: Codable {
        var version: Int
        var records: [DictationRecord]
    }

    /// Load persisted transcripts, newest-first, capped. Returns empty on any
    /// read/decode failure (never throws — matches the other stores).
    func load() -> DictationHistory {
        guard let url = try? AppSupport.fileURL(filename),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(StoredFile.self, from: data) else {
            return DictationHistory(records: [], limit: cap)
        }
        return DictationHistory(records: file.records, limit: cap)
    }

    /// Persist the current history (trimmed to the cap, newest-first).
    func save(_ history: DictationHistory) {
        let records = Array(history.records.prefix(cap))
        queue.async { [weak self] in self?.write(records) }
    }

    /// Forget everything — deletes the file.
    func clearAll() {
        queue.async {
            if let url = try? AppSupport.fileURL(self.filename) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private func write(_ records: [DictationRecord]) {
        guard let url = try? AppSupport.fileURL(filename),
              let data = try? JSONEncoder().encode(StoredFile(version: 1, records: records)) else {
            return
        }
        do {
            try data.write(to: url, options: .atomic)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: url.path
            )
        } catch {
            // Persistence is best-effort: dictation must keep working even when
            // Application Support is temporarily unavailable.
        }
    }
}
