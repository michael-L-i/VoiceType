import Testing
import Foundation
@testable import VoiceTypeKit

/// A fixed UTC calendar so start-of-day bucketing is deterministic regardless of
/// the machine's time zone.
private var utc: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}

private let epoch = Date(timeIntervalSince1970: 0)              // 1970-01-01 UTC
private func day(_ n: Int) -> Date { epoch.addingTimeInterval(Double(n) * 86_400) }

private let slack = AppUsageKey(bundleID: "com.tinyspeck.slackmacgap", name: "Slack")
private let notes = AppUsageKey(bundleID: "com.apple.Notes", name: "Notes")

@Suite("Daily stats — per-day rollup")
struct DailyRollupTests {
    @Test("multiple dictations on one day accumulate into a single row")
    func sameDay() {
        var log = DailyStatsLog()
        log.record(words: 10, speakingTime: 5, app: slack, source: .microphone, on: day(0), calendar: utc)
        log.record(words: 5, speakingTime: 3, app: slack, source: .microphone, on: day(0), calendar: utc)
        let row = log.days[utc.startOfDay(for: day(0))]
        #expect(row?.words == 15)
        #expect(row?.sessions == 2)
        #expect(row?.speakingTime == 8)
        #expect(log.days.count == 1)
    }

    @Test("different days are separate rows")
    func separateDays() {
        var log = DailyStatsLog()
        log.record(words: 4, speakingTime: 2, app: nil, source: .microphone, on: day(0), calendar: utc)
        log.record(words: 6, speakingTime: 2, app: nil, source: .microphone, on: day(1), calendar: utc)
        #expect(log.days.count == 2)
    }

    @Test("words-per-minute is derived from the day's totals")
    func wpm() {
        var stats = DailyStats(day: day(0))
        stats.words = 120
        stats.speakingTime = 60          // 120 words in 1 min → 120 wpm
        #expect(stats.wordsPerMinute == 120)
        #expect(DailyStats(day: day(0)).wordsPerMinute == 0)   // guards /0
    }
}

@Suite("Daily stats — retention")
struct RetentionTests {
    @Test("days older than the retention window are pruned")
    func prune() {
        var log = DailyStatsLog(retentionDays: 30)
        log.record(words: 1, speakingTime: 1, app: nil, source: .microphone, on: day(0), calendar: utc)
        // A dictation 40 days later should evict the day-0 row (>30 day window).
        log.record(words: 1, speakingTime: 1, app: nil, source: .microphone, on: day(40), calendar: utc)
        #expect(log.days[utc.startOfDay(for: day(0))] == nil)
        #expect(log.days[utc.startOfDay(for: day(40))] != nil)
    }

    @Test("days inside the window survive")
    func keepRecent() {
        var log = DailyStatsLog(retentionDays: 30)
        log.record(words: 1, speakingTime: 1, app: nil, source: .microphone, on: day(20), calendar: utc)
        log.record(words: 1, speakingTime: 1, app: nil, source: .microphone, on: day(40), calendar: utc)
        #expect(log.days.count == 2)
    }
}

@Suite("Daily stats — heatmap window")
struct WindowTests {
    @Test("window is dense, gap-filled, and oldest→newest")
    func dense() {
        var log = DailyStatsLog()
        log.record(words: 10, speakingTime: 5, app: nil, source: .microphone, on: day(0), calendar: utc)
        log.record(words: 20, speakingTime: 5, app: nil, source: .microphone, on: day(2), calendar: utc)
        let w = log.window(endingOn: day(2), days: 3, calendar: utc)
        #expect(w.count == 3)
        #expect(w[0].words == 10)   // day 0
        #expect(w[1].words == 0)    // day 1 — gap filled
        #expect(w[2].words == 20)   // day 2 (newest, last)
    }

    @Test("empty window for non-positive counts")
    func emptyCount() {
        let log = DailyStatsLog()
        #expect(log.window(endingOn: day(0), days: 0, calendar: utc).isEmpty)
    }
}

@Suite("Daily stats — per-app tallies")
struct AppTallyTests {
    @Test("app totals accumulate and topApps is ordered by words")
    func topApps() {
        var log = DailyStatsLog()
        log.record(words: 100, speakingTime: 10, app: slack, source: .microphone, on: day(0), calendar: utc)
        log.record(words: 30, speakingTime: 4, app: notes, source: .microphone, on: day(0), calendar: utc)
        log.record(words: 50, speakingTime: 5, app: slack, source: .microphone, on: day(1), calendar: utc)
        let top = log.topApps()
        #expect(top.count == 2)
        #expect(top[0].bundleID == slack.bundleID)
        #expect(top[0].words == 150)
        #expect(top[0].sessions == 2)
        #expect(top[1].bundleID == notes.bundleID)
    }

    @Test("imported files have no app, so they don't touch app totals")
    func importedNoApp() {
        var log = DailyStatsLog()
        log.record(words: 80, speakingTime: 8, app: nil, source: .importedFile, on: day(0), calendar: utc)
        #expect(log.appTotals.isEmpty)
        #expect(log.days[utc.startOfDay(for: day(0))]?.words == 80)   // day still counts
    }

    @Test("the most recent display name wins")
    func nameUpdates() {
        var log = DailyStatsLog()
        log.record(words: 1, speakingTime: 1, app: AppUsageKey(bundleID: "x", name: "Old"),
                   source: .microphone, on: day(0), calendar: utc)
        log.record(words: 1, speakingTime: 1, app: AppUsageKey(bundleID: "x", name: "New"),
                   source: .microphone, on: day(0), calendar: utc)
        #expect(log.appTotals["x"]?.name == "New")
    }
}

@Suite("Daily stats — persistence shape")
struct CodableTests {
    @Test("a populated log round-trips through JSON")
    func roundTrip() throws {
        var log = DailyStatsLog()
        log.record(words: 12, speakingTime: 6, app: slack, source: .microphone, on: day(0), calendar: utc)
        log.record(words: 8, speakingTime: 4, app: notes, source: .microphone, on: day(1), calendar: utc)
        let data = try JSONEncoder().encode(log)
        let decoded = try JSONDecoder().decode(DailyStatsLog.self, from: data)
        #expect(decoded == log)
    }
}
