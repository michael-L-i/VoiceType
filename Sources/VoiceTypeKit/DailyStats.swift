import Foundation

/// Where a dictation came from: the live microphone, or an imported audio/video
/// file. Recorded per dictation so the UI can distinguish typed-everywhere
/// dictation from one-off file transcriptions.
public enum DictationSource: String, Sendable, Codable, Equatable {
    case microphone
    case importedFile
}

/// Identifies the foreground app a dictation was typed into. Keyed on bundle id
/// (stable); the name is the last-seen display name (for showing in the UI).
/// On-device only — like all stats, this never leaves the Mac.
public struct AppUsageKey: Sendable, Codable, Equatable, Hashable {
    public var bundleID: String
    public var name: String

    public init(bundleID: String, name: String) {
        self.bundleID = bundleID
        self.name = name
    }
}

/// Lifetime per-app dictation tally (counts only, never text).
public struct AppUsage: Sendable, Codable, Equatable, Identifiable {
    public var bundleID: String
    public var name: String
    public var words: Int
    public var sessions: Int
    public var speakingTime: TimeInterval

    public var id: String { bundleID }

    public init(bundleID: String, name: String, words: Int = 0,
                sessions: Int = 0, speakingTime: TimeInterval = 0) {
        self.bundleID = bundleID
        self.name = name
        self.words = words
        self.sessions = sessions
        self.speakingTime = speakingTime
    }
}

/// One calendar day's dictation activity. The unit the activity heatmap and the
/// usage trends are built from. Counts only — never transcript text or audio.
public struct DailyStats: Sendable, Codable, Equatable, Identifiable {
    /// Calendar start-of-day this row aggregates.
    public var day: Date
    public var words: Int
    public var sessions: Int
    public var speakingTime: TimeInterval

    public var id: Date { day }

    public init(day: Date, words: Int = 0, sessions: Int = 0,
                speakingTime: TimeInterval = 0) {
        self.day = day
        self.words = words
        self.sessions = sessions
        self.speakingTime = speakingTime
    }

    /// Whole words per minute for the day, or zero with no measurable speaking
    /// time (guards division by zero).
    public var wordsPerMinute: Int {
        guard speakingTime > 0 else { return 0 }
        return Int((Double(words) / (speakingTime / 60)).rounded())
    }
}

/// A bounded log of per-day activity plus lifetime per-app tallies. Pure and
/// testable — folding a finished dictation in mirrors `DictationStats.record`.
/// Persistence is the app layer's job (`DailyStatsStore`). Everything here is an
/// aggregate count, so it's safe to keep regardless of the history setting.
public struct DailyStatsLog: Sendable, Codable, Equatable {
    /// Per-day rows keyed by calendar start-of-day. Pruned to `retentionDays`.
    public private(set) var days: [Date: DailyStats]
    /// Lifetime per-app tallies keyed by bundle id.
    public private(set) var appTotals: [String: AppUsage]
    /// How many days of per-day history to keep (>1 year for the heatmap).
    public let retentionDays: Int

    /// Defensive cap on tracked apps so a long tail of one-off apps can't grow
    /// unbounded. The lowest-word apps are evicted past this.
    private let appCap = 200

    public init(days: [Date: DailyStats] = [:],
                appTotals: [String: AppUsage] = [:],
                retentionDays: Int = 400) {
        self.days = days
        self.appTotals = appTotals
        self.retentionDays = retentionDays
    }

    private enum CodingKeys: String, CodingKey { case days, appTotals, retentionDays }

    /// Fold one finished dictation into the per-day row and per-app tally. `app`
    /// is nil for file imports (no foreground app). Prunes old days afterward so
    /// the log stays bounded.
    public mutating func record(words: Int,
                                speakingTime: TimeInterval,
                                app: AppUsageKey?,
                                source: DictationSource,
                                on date: Date,
                                calendar: Calendar = .current) {
        let w = max(0, words)
        let t = max(0, speakingTime)

        let day = calendar.startOfDay(for: date)
        var row = days[day] ?? DailyStats(day: day)
        row.words += w
        row.sessions += 1
        row.speakingTime += t
        days[day] = row

        if let app {
            var usage = appTotals[app.bundleID] ?? AppUsage(bundleID: app.bundleID, name: app.name)
            usage.name = app.name          // keep the most recent display name
            usage.words += w
            usage.sessions += 1
            usage.speakingTime += t
            appTotals[app.bundleID] = usage
        }

        prune(relativeTo: day, calendar: calendar)
    }

    /// Drop days older than the retention window (measured from the newest day
    /// folded in) and cap the app table to its busiest entries.
    private mutating func prune(relativeTo newest: Date, calendar: Calendar) {
        if let cutoff = calendar.date(byAdding: .day, value: -retentionDays, to: newest) {
            days = days.filter { $0.key >= cutoff }
        }
        if appTotals.count > appCap {
            let keep = appTotals.values
                .sorted { $0.words > $1.words }
                .prefix(appCap)
            appTotals = Dictionary(uniqueKeysWithValues: keep.map { ($0.bundleID, $0) })
        }
    }

    /// A dense, oldest→newest run of `count` days ending on the day containing
    /// `end`, with empty days filled in as zero rows. This is what the heatmap
    /// and trend sparkline render — every cell present, no gaps.
    public func window(endingOn end: Date,
                       days count: Int,
                       calendar: Calendar = .current) -> [DailyStats] {
        guard count > 0 else { return [] }
        let last = calendar.startOfDay(for: end)
        var result: [DailyStats] = []
        result.reserveCapacity(count)
        // Walk from the oldest day forward so the array reads left→right in time.
        for offset in stride(from: count - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: last) else { continue }
            result.append(days[day] ?? DailyStats(day: day))
        }
        return result
    }

    /// The busiest apps by lifetime words, most first.
    public func topApps(limit: Int = .max) -> [AppUsage] {
        appTotals.values
            .sorted { $0.words > $1.words }
            .prefix(limit)
            .map { $0 }
    }
}
