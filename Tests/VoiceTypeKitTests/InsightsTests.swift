import Testing
import Foundation
@testable import VoiceTypeKit

private var utc: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    c.locale = Locale(identifier: "en_US")
    return c
}
private let epoch = Date(timeIntervalSince1970: 0)
private func day(_ n: Int) -> Date { epoch.addingTimeInterval(Double(n) * 86_400) }
private let slack = AppUsageKey(bundleID: "com.tinyspeck.slackmacgap", name: "Slack")

@Suite("Insights — deterministic generation")
struct InsightsGenerationTests {
    @Test("empty stats yield a get-started headline and no bullets")
    func empty() {
        let insights = InsightsGenerator.generate(from: DailyStatsLog(),
                                                  lifetime: DictationStats(),
                                                  now: day(10), calendar: utc)
        #expect(insights.headline == "Start dictating to see your patterns.")
        #expect(insights.bullets.isEmpty)
        #expect(insights.topApps.isEmpty)
        #expect(insights.busiestDay == nil)
    }

    @Test("this-week words drive the headline")
    func weekHeadline() {
        var log = DailyStatsLog()
        log.record(words: 300, speakingTime: 60, app: slack, source: .microphone, on: day(10), calendar: utc)
        let insights = InsightsGenerator.generate(from: log, lifetime: DictationStats(),
                                                  now: day(10), calendar: utc)
        #expect(insights.headline.contains("this week"))
        #expect(insights.topApps.first?.name == "Slack")
    }

    @Test("week-over-week delta and bullet are computed")
    func weekOverWeek() {
        var log = DailyStatsLog()
        log.record(words: 100, speakingTime: 30, app: nil, source: .microphone, on: day(3), calendar: utc)  // last week
        log.record(words: 200, speakingTime: 30, app: nil, source: .microphone, on: day(10), calendar: utc) // this week
        let insights = InsightsGenerator.generate(from: log, lifetime: DictationStats(),
                                                  now: day(10), calendar: utc)
        #expect(insights.weekOverWeekWordDelta == 100)
        #expect(insights.bullets.contains { $0.id == "wow" && $0.text.contains("up") })
    }

    @Test("busiest day is the highest-word day")
    func busiest() {
        var log = DailyStatsLog()
        log.record(words: 50, speakingTime: 20, app: nil, source: .microphone, on: day(8), calendar: utc)
        log.record(words: 400, speakingTime: 60, app: nil, source: .microphone, on: day(9), calendar: utc)
        let insights = InsightsGenerator.generate(from: log, lifetime: DictationStats(),
                                                  now: day(10), calendar: utc)
        #expect(insights.busiestDay?.words == 400)
    }

    @Test("lifetime streak and total surface as bullets")
    func lifetimeBullets() {
        let lifetime = DictationStats(totalWords: 5000, totalSpeakingTime: 600,
                                      sessionCount: 40, currentStreak: 6,
                                      lastDictationDay: day(10))
        let insights = InsightsGenerator.generate(from: DailyStatsLog(), lifetime: lifetime,
                                                  now: day(10), calendar: utc)
        #expect(insights.bullets.contains { $0.id == "streak" && $0.text.contains("6-day") })
        #expect(insights.bullets.contains { $0.id == "total" })
        #expect(insights.bullets.contains { $0.id == "wpm" })
    }
}

@Suite("Insights — summary prompt (privacy)")
struct SummaryPromptTests {
    @Test("the prompt carries the facts, fenced, and never transcript text")
    func promptShape() {
        var log = DailyStatsLog()
        log.record(words: 300, speakingTime: 60, app: slack, source: .microphone, on: day(10), calendar: utc)
        let insights = InsightsGenerator.generate(from: log, lifetime: DictationStats(),
                                                  now: day(10), calendar: utc)
        let prompt = SummaryPrompt.prompt(for: insights)
        #expect(prompt.contains(insights.headline))
        #expect(prompt.contains("<<<STATS"))
        #expect(prompt.contains("STATS>>>"))
        #expect(prompt.contains("Slack"))
    }

    @Test("instructions forbid invention and markdown")
    func instructions() {
        let text = SummaryPrompt.instructions()
        #expect(text.contains("only the facts"))
        #expect(text.lowercased().contains("markdown"))
    }

    @Test("prompt carries the richer aggregate facts: totals, per-app depth, busiest day")
    func richFacts() {
        var log = DailyStatsLog()
        log.record(words: 300, speakingTime: 120, app: slack, source: .microphone, on: day(9), calendar: utc)
        log.record(words: 500, speakingTime: 180, app: slack, source: .microphone, on: day(10), calendar: utc)
        let lifetime = DictationStats(totalWords: 5000, totalSpeakingTime: 3000,
                                      sessionCount: 40, currentStreak: 6, lastDictationDay: day(10))
        let insights = InsightsGenerator.generate(from: log, lifetime: lifetime,
                                                  now: day(10), calendar: utc)
        let prompt = SummaryPrompt.prompt(for: insights)
        // Lifetime totals woven in (words, dictations, speaking time, pace).
        #expect(prompt.contains("By the numbers"))
        #expect(prompt.contains("5,000 words all-time"))
        #expect(prompt.contains("40 dictations"))
        #expect(prompt.contains("spoken"))
        // Per-app depth: sessions + time, not just words.
        #expect(prompt.contains("Where you dictate"))
        #expect(prompt.contains("sessions"))
        // Busiest single day surfaced.
        #expect(prompt.contains("busiest single day"))
        // Still fenced, still no transcript text could leak (no record text exists).
        #expect(prompt.contains("<<<STATS"))
    }
}
