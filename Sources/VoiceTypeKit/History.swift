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
    /// Where this dictation came from — the live mic or an imported file.
    public var source: DictationSource
    /// The imported file's name, for file transcriptions; nil for mic dictation.
    public var sourceFilename: String?
    /// The app this was typed into (mic dictation only); nil for file imports.
    public var appName: String?
    public var appBundleID: String?
    /// Audio duration in seconds — lets the UI show a per-record speaking pace.
    public var speakingTime: TimeInterval

    // Defaulted so records written before these fields existed still decode.
    public init(id: UUID = UUID(), date: Date, text: String,
                transcriptionEngine: TranscriptionEngineKind,
                cleanupEngine: CleanupEngineKind,
                timeToText: TimeInterval,
                source: DictationSource = .microphone,
                sourceFilename: String? = nil,
                appName: String? = nil,
                appBundleID: String? = nil,
                speakingTime: TimeInterval = 0) {
        self.id = id
        self.date = date
        self.text = text
        self.transcriptionEngine = transcriptionEngine
        self.cleanupEngine = cleanupEngine
        self.timeToText = timeToText
        self.source = source
        self.sourceFilename = sourceFilename
        self.appName = appName
        self.appBundleID = appBundleID
        self.speakingTime = speakingTime
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        text = try c.decode(String.self, forKey: .text)
        transcriptionEngine = try c.decode(TranscriptionEngineKind.self, forKey: .transcriptionEngine)
        cleanupEngine = try c.decode(CleanupEngineKind.self, forKey: .cleanupEngine)
        timeToText = try c.decode(TimeInterval.self, forKey: .timeToText)
        // New fields — absent in older payloads, so default them.
        source = try c.decodeIfPresent(DictationSource.self, forKey: .source) ?? .microphone
        sourceFilename = try c.decodeIfPresent(String.self, forKey: .sourceFilename)
        appName = try c.decodeIfPresent(String.self, forKey: .appName)
        appBundleID = try c.decodeIfPresent(String.self, forKey: .appBundleID)
        speakingTime = try c.decodeIfPresent(TimeInterval.self, forKey: .speakingTime) ?? 0
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

    /// Remove a single record by id (used by the Transcripts page's delete).
    public mutating func remove(id: UUID) {
        records.removeAll { $0.id == id }
    }

    public mutating func clear() {
        records.removeAll()
    }
}
