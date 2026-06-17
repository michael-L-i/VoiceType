import Foundation

/// Lifetime dictation statistics, kept on-device only. These are aggregate
/// counts — never transcript text or audio — so they're safe to keep regardless
/// of the history setting. Persistence is the app layer's job; this is a pure,
/// testable value type that knows how to fold a new dictation into the totals.
public struct DictationStats: Sendable, Codable, Equatable {
    /// Total words dictated across all sessions.
    public var totalWords: Int
    /// Total speaking time (sum of audio durations) across all sessions, seconds.
    public var totalSpeakingTime: TimeInterval
    /// Number of dictations recorded.
    public var sessionCount: Int
    /// Current consecutive-day streak (see `record`).
    public var currentStreak: Int
    /// The day of the most recent dictation (calendar start-of-day), or nil.
    public var lastDictationDay: Date?

    public init(totalWords: Int = 0,
                totalSpeakingTime: TimeInterval = 0,
                sessionCount: Int = 0,
                currentStreak: Int = 0,
                lastDictationDay: Date? = nil) {
        self.totalWords = totalWords
        self.totalSpeakingTime = totalSpeakingTime
        self.sessionCount = sessionCount
        self.currentStreak = currentStreak
        self.lastDictationDay = lastDictationDay
    }

    /// Whitespace-delimited word count for a finished transcript.
    public static func wordCount(_ text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    /// Fold one completed dictation into the totals. `speakingTime` is the audio
    /// duration in seconds; `date` is when it finished (defaults handled by the
    /// caller). Streak handling lands in a later step.
    public mutating func record(words: Int,
                                speakingTime: TimeInterval,
                                on date: Date,
                                calendar: Calendar = .current) {
        totalWords += max(0, words)
        totalSpeakingTime += max(0, speakingTime)
        sessionCount += 1
    }
}
