import Foundation

/// One past dictation, kept on-device only (never synced, never uploaded) so
/// the user can copy/redo a recent result. Audio is never stored — only text.
public struct DictationRecord: Sendable, Codable, Equatable, Identifiable {
    public var id: UUID
    public var date: Date
    public var text: String
    public var transcriptionEngine: TranscriptionEngineKind
    public var cleanupEngine: CleanupEngineKind
    public var timeToText: TimeInterval

    public init(id: UUID = UUID(), date: Date, text: String,
                transcriptionEngine: TranscriptionEngineKind,
                cleanupEngine: CleanupEngineKind,
                timeToText: TimeInterval) {
        self.id = id
        self.date = date
        self.text = text
        self.transcriptionEngine = transcriptionEngine
        self.cleanupEngine = cleanupEngine
        self.timeToText = timeToText
    }
}

/// A bounded, in-memory ring of recent dictations. Persistence (if `keepHistory`
/// is on) is the app layer's job; this just enforces the cap and ordering.
public struct DictationHistory: Sendable, Codable, Equatable {
    public private(set) var records: [DictationRecord]
    public let limit: Int

    public init(records: [DictationRecord] = [], limit: Int = 50) {
        self.limit = limit
        self.records = Array(records.suffix(limit))
    }

    /// Insert newest-first, trimming to the cap.
    public mutating func add(_ record: DictationRecord) {
        records.insert(record, at: 0)
        if records.count > limit {
            records.removeLast(records.count - limit)
        }
    }

    public mutating func clear() {
        records.removeAll()
    }
}
