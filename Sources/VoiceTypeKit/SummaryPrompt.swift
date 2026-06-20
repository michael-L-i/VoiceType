import Foundation

/// Builds the system instructions and per-request prompt for the optional
/// on-device usage summary. Kept separate from the engine (mirrors `CleanupPrompt`)
/// so the wording is easy to read, test, and tune.
///
/// Privacy: the model is fed **aggregate facts only** — word counts, app names,
/// streaks — never transcript text. The prompt fences the facts so the model
/// treats them as data, not instructions.
public enum SummaryPrompt {
    public static func instructions() -> String {
        """
        You are a friendly writing assistant that summarizes a person's dictation \
        statistics. You will be given a list of facts about how they use a \
        voice-dictation app. Write a warm, encouraging short paragraph (about 4–6 \
        sentences) in the second person ("you") that describes their usage — their \
        pace, the apps they dictate into, their streak and totals, and how this \
        week is trending.

        Strict rules:
        - Use only the facts provided. Never invent numbers, apps, or trends.
        - No markdown, bullet points, headings, or quotes — plain sentences only.
        - Write flowing prose, like a note from a coach. Weave the numbers \
          together naturally; don't just list them back.
        - Do not give advice or instructions; just describe what the stats show.
        """
    }

    /// The per-request prompt. Renders the insights as plain fenced facts —
    /// aggregate counts only, never transcript text.
    public static func prompt(for insights: UsageInsights) -> String {
        var lines: [String] = [insights.headline]
        lines += insights.bullets.map { "- \($0.text)" }

        // Lifetime totals, woven into one line so the model has the raw numbers.
        let life = insights.lifetime
        var numbers: [String] = []
        if life.totalWords > 0 { numbers.append("\(life.totalWords.formatted()) words all-time") }
        if life.sessionCount > 0 { numbers.append("\(life.sessionCount.formatted()) dictations") }
        if life.totalSpeakingTime > 0 { numbers.append("\(duration(life.totalSpeakingTime)) spoken") }
        if life.averageWordsPerMinute > 0 { numbers.append("\(life.averageWordsPerMinute) words per minute") }
        if !numbers.isEmpty { lines.append("By the numbers: \(numbers.joined(separator: ", ")).") }

        // Top apps with depth — words, how many sessions, and time spent in each.
        if !insights.topApps.isEmpty {
            let apps = insights.topApps.prefix(5).map { app -> String in
                var parts = ["\(app.words.formatted()) words"]
                if app.sessions > 0 {
                    parts.append("\(app.sessions) \(app.sessions == 1 ? "session" : "sessions")")
                }
                if app.speakingTime > 0 { parts.append(duration(app.speakingTime)) }
                return "\(app.name) (\(parts.joined(separator: ", ")))"
            }.joined(separator: "; ")
            lines.append("Where you dictate: \(apps).")
        }

        if let busiest = insights.busiestDay, busiest.words > 0 {
            lines.append("Your busiest single day reached \(busiest.words.formatted()) words.")
        }

        return """
        Summarize these dictation stats in a warm, encouraging short paragraph. \
        Use only these facts.

        <<<STATS
        \(lines.joined(separator: "\n"))
        STATS>>>
        """
    }

    /// Human-friendly duration: "under a minute", "42 min", or "1 hr 9 min".
    private static func duration(_ seconds: TimeInterval) -> String {
        let totalMin = Int((seconds / 60).rounded())
        if totalMin < 1 { return "under a minute" }
        if totalMin < 60 { return "\(totalMin) min" }
        let (h, m) = (totalMin / 60, totalMin % 60)
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }
}
