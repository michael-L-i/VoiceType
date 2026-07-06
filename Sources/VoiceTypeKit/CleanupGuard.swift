import Foundation

/// Deterministic backstop against the on-device model *summarizing* a
/// dictation instead of tidying it. The model engine runs this on its output;
/// a flagged result is treated as a failure so the pipeline degrades to the
/// rule-based floor instead of shipping a truncated transcript.
///
/// The comparison counts **content words** on the raw side — whitespace-split
/// words minus fillers and spoken-symbol tokens — so legitimate shrinkage
/// never trips it: filler removal, self-corrections, and code rendering
/// ("print open paren x comma y close paren" → "print(x, y)") all collapse
/// words by design.
///
/// Non-space-delimited languages (Chinese, Japanese, Thai, …) mostly stay
/// under `minimumContentWords` when split on whitespace, so the guard
/// self-disables there rather than misfiring.
public enum CleanupGuard {
    /// Below this many raw content words, ratios are noise — a legitimate
    /// self-correction ("I want two, no three" → "I want three") can halve a
    /// short utterance. The guard only evaluates above the floor.
    public static let minimumContentWords = 8

    /// Cleaned output must retain at least this fraction of the raw content
    /// words. Fillers plus self-corrections rarely remove more than ~40% of
    /// content; real summarization compresses below ~30%. 0.5 sits between
    /// the two with margin on both sides.
    public static let minimumRetainedRatio = 0.5

    /// Spoken names of symbols and rendering directives that legitimately
    /// collapse into single characters or joined identifiers during cleanup.
    static let spokenSymbols: Set<String> = [
        "dot", "period", "comma", "dash", "hyphen", "underscore", "slash",
        "backslash", "tilde", "colon", "semicolon", "equals", "plus", "minus",
        "star", "asterisk", "percent", "ampersand", "pipe", "backtick",
        "quote", "unquote", "open", "close", "paren", "parens", "parenthesis",
        "bracket", "brackets", "brace", "braces", "angle", "camel", "case",
        "capital", "uppercase", "lowercase", "newline", "tab", "hash",
        "pound", "dollar", "caret", "at", "sign", "mark", "point", "space",
    ]

    /// True when `cleaned` is suspiciously short relative to `raw` — i.e. the
    /// model likely summarized instead of cleaning.
    public static func looksLikeSummary(raw: String, cleaned: String) -> Bool {
        let rawContent = contentWordCount(raw)
        guard rawContent >= minimumContentWords else { return false }
        // Count the cleaned side generously (every word counts): its filler
        // and symbol words are already gone, and over-counting there only
        // makes the guard harder to trip.
        let cleanedWords = wordCount(cleaned)
        return Double(cleanedWords) < minimumRetainedRatio * Double(rawContent)
    }

    /// Whitespace-split words minus fillers and spoken-symbol tokens.
    static func contentWordCount(_ text: String) -> Int {
        words(text).count { word in
            !RuleBasedCleanup.fillers.contains(word) && !spokenSymbols.contains(word)
        }
    }

    private static func wordCount(_ text: String) -> Int {
        words(text).count
    }

    /// Lowercased, punctuation-trimmed word tokens.
    private static func words(_ text: String) -> [String] {
        text.lowercased()
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
    }
}
