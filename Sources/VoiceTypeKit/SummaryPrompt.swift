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
        statistics. You will be given a short list of facts. Write 2–3 warm, \
        encouraging sentences in the second person ("you") that describe their \
        usage.

        Strict rules:
        - Use only the facts provided. Never invent numbers, apps, or trends.
        - No markdown, bullet points, headings, or quotes — plain sentences only.
        - Keep it brief and natural, like a note from a coach.
        - Do not give advice or instructions; just describe what the stats show.
        """
    }

    /// The per-request prompt. Renders the insights as plain fenced facts.
    public static func prompt(for insights: UsageInsights) -> String {
        var lines: [String] = [insights.headline]
        lines += insights.bullets.map { "- \($0.text)" }
        if !insights.topApps.isEmpty {
            let apps = insights.topApps.prefix(3)
                .map { "\($0.name) (\($0.words) words)" }
                .joined(separator: ", ")
            lines.append("Top apps: \(apps)")
        }

        return """
        Summarize these dictation stats in 2–3 sentences. Use only these facts.

        <<<STATS
        \(lines.joined(separator: "\n"))
        STATS>>>
        """
    }
}
