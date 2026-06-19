import Foundation

/// One structured fact about the user's dictation, ready to render as a row. The
/// SF Symbol name is carried as data so the Kit stays framework-free while the UI
/// still gets a glyph hint.
public struct Insight: Sendable, Equatable, Identifiable {
    public var id: String
    public var symbol: String
    public var text: String

    public init(id: String, symbol: String, text: String) {
        self.id = id
        self.symbol = symbol
        self.text = text
    }
}

/// A snapshot of usage patterns derived purely from aggregate stats — never from
/// transcript text. Drives the Stats page's insights section and feeds the
/// optional on-device natural-language summary.
public struct UsageInsights: Sendable, Equatable {
    public var headline: String
    public var bullets: [Insight]
    public var topApps: [AppUsage]
    public var busiestDay: DailyStats?
    public var weekOverWeekWordDelta: Int

    public init(headline: String, bullets: [Insight], topApps: [AppUsage],
                busiestDay: DailyStats?, weekOverWeekWordDelta: Int) {
        self.headline = headline
        self.bullets = bullets
        self.topApps = topApps
        self.busiestDay = busiestDay
        self.weekOverWeekWordDelta = weekOverWeekWordDelta
    }
}

/// Turns the per-day log + lifetime totals into `UsageInsights`. Pure and
/// deterministic so it's fully unit-testable and **always works** — the Stats
/// page never needs the language model to show something useful.
public enum InsightsGenerator {
    public static func generate(from log: DailyStatsLog,
                                lifetime: DictationStats,
                                now: Date = Date(),
                                calendar: Calendar = .current) -> UsageInsights {
        let thisWeek = log.window(endingOn: now, days: 7, calendar: calendar)
        let thisWeekWords = thisWeek.reduce(0) { $0 + $1.words }

        let prevEnd = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let lastWeek = log.window(endingOn: prevEnd, days: 7, calendar: calendar)
        let lastWeekWords = lastWeek.reduce(0) { $0 + $1.words }
        let delta = thisWeekWords - lastWeekWords

        let topApps = log.topApps(limit: 5)
        let busiest = log.window(endingOn: now, days: 365, calendar: calendar)
            .max { $0.words < $1.words }
        let busiestDay = (busiest?.words ?? 0) > 0 ? busiest : nil

        var bullets: [Insight] = []

        if thisWeekWords > 0, lastWeekWords > 0 {
            let pct = Int((Double(delta) / Double(lastWeekWords) * 100).rounded())
            if pct != 0 {
                let up = pct > 0
                bullets.append(Insight(
                    id: "wow",
                    symbol: up ? "arrow.up.right" : "arrow.down.right",
                    text: "That's \(abs(pct))% \(up ? "up" : "down") from last week."))
            }
        }

        if let app = topApps.first, app.words > 0 {
            bullets.append(Insight(id: "topapp", symbol: "app.dashed",
                                   text: "You dictate most in \(app.name)."))
        }

        if let weekday = busiestWeekday(in: log, now: now, calendar: calendar) {
            bullets.append(Insight(id: "weekday", symbol: "calendar",
                                   text: "\(weekday) is your most active day."))
        }

        if lifetime.currentStreak > 1 {
            bullets.append(Insight(id: "streak", symbol: "flame.fill",
                                   text: "You're on a \(lifetime.currentStreak)-day streak."))
        }

        if lifetime.averageWordsPerMinute > 0 {
            bullets.append(Insight(id: "wpm", symbol: "gauge.with.dots.needle.67percent",
                                   text: "You average \(lifetime.averageWordsPerMinute) words per minute."))
        }

        if lifetime.totalWords > 0 {
            bullets.append(Insight(id: "total", symbol: "sum",
                                   text: "\(lifetime.totalWords.formatted()) words all-time across \(lifetime.sessionCount.formatted()) dictations."))
        }

        let headline: String
        if thisWeekWords > 0 {
            headline = "You dictated \(thisWeekWords.formatted()) words this week."
        } else if lifetime.totalWords > 0 {
            headline = "You've dictated \(lifetime.totalWords.formatted()) words with VoiceType."
        } else {
            headline = "Start dictating to see your patterns."
        }

        return UsageInsights(headline: headline, bullets: bullets, topApps: topApps,
                             busiestDay: busiestDay, weekOverWeekWordDelta: delta)
    }

    /// The weekday with the most dictated words over the last ~12 weeks, as a
    /// localized name (e.g. "Tuesday"), or nil if there's no activity.
    private static func busiestWeekday(in log: DailyStatsLog, now: Date,
                                       calendar: Calendar) -> String? {
        let window = log.window(endingOn: now, days: 84, calendar: calendar)
        var byWeekday: [Int: Int] = [:]          // weekday (1–7) → words
        for day in window where day.words > 0 {
            let wd = calendar.component(.weekday, from: day.day)
            byWeekday[wd, default: 0] += day.words
        }
        guard let top = byWeekday.max(by: { $0.value < $1.value })?.key else { return nil }

        let formatter = DateFormatter()
        formatter.locale = calendar.locale ?? .current
        let symbols = formatter.weekdaySymbols ?? []      // index 0 == Sunday (weekday 1)
        let index = top - 1
        return symbols.indices.contains(index) ? symbols[index] : nil
    }
}
