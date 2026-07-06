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

    /// Cleaned output growing past this ratio of the raw word count (plus a
    /// small absolute slack) means the model added words that were never
    /// spoken. Cleanup only removes and re-punctuates; it has no legitimate
    /// reason to grow the text. Observed failure mode: the model regurgitating
    /// a few-shot example verbatim when the dictation resembles it.
    public static let maximumGrowthRatio = 1.5

    /// The combined production check: true when the output is a summary (too
    /// short), a fabrication (too long), lost its opening, or contains words
    /// the user never spoke. Either way the engine must discard it and fall
    /// back to the deterministic floor.
    public static func looksUnfaithful(raw: String, cleaned: String) -> Bool {
        looksLikeSummary(raw: raw, cleaned: cleaned)
            || looksFabricated(raw: raw, cleaned: cleaned)
            || droppedOpening(raw: raw, cleaned: cleaned)
            || !inventedWords(raw: raw, cleaned: cleaned).isEmpty
    }

    /// Words in `cleaned` that cannot be traced back to anything in `raw` —
    /// the model answering a dictated question ("one plus one" → "… is two"),
    /// or echoing prompt content. Cleanup only removes and re-renders; every
    /// output word must come from input words.
    ///
    /// A cleaned token counts as traceable when it, or each of its fragments
    /// (split on join symbols and camelCase boundaries: utils.ts → utils, ts;
    /// parseRequest → parse, request), is a raw word, a short join artifact
    /// (≤ 2 chars, like "py" from "pie"), or a concatenation of raw words
    /// ("voicetype" ← "voice type").
    public static func inventedWords(raw: String, cleaned: String) -> [String] {
        let rawNorms = Set(words(raw).map { $0.replacingOccurrences(of: "'", with: "") })
        let rawHasDigits = rawNorms.contains { $0.contains(where: \.isNumber) }
        var invented: [String] = []
        for token in caseTokens(cleaned) {
            let norm = token.lowercased().replacingOccurrences(of: "'", with: "")
            if norm.isEmpty || rawNorms.contains(norm) { continue }
            // A digit the user never spoke as a digit is invented content
            // ("one plus one" → "2"), regardless of length.
            if norm.contains(where: \.isNumber) && !rawHasDigits {
                invented.append(norm)
                continue
            }
            if norm.count <= 2 { continue }
            let traceable = fragments(of: token).allSatisfy { fragment in
                fragment.count <= 2 || composable(fragment, from: rawNorms)
            }
            if !traceable { invented.append(norm) }
        }
        return invented
    }

    /// Whitespace-split tokens with edge punctuation trimmed but CASE KEPT,
    /// so camelCase boundaries survive for fragment splitting.
    private static func caseTokens(_ text: String) -> [String] {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
    }

    /// Split a token on join symbols and lowercase→uppercase camel boundaries,
    /// returning lowercased, apostrophe-free fragments.
    private static func fragments(of token: String) -> [String] {
        var parts: [String] = []
        var current = ""
        var previous: Character?
        for char in token {
            if symbolSeparators.contains(char) || "()[]{},".contains(char) {
                if !current.isEmpty { parts.append(current); current = "" }
            } else {
                if char.isUppercase, let previous, previous.isLowercase {
                    parts.append(current)
                    current = ""
                }
                current.append(char)
            }
            previous = char
        }
        if !current.isEmpty { parts.append(current) }
        return parts.map { $0.lowercased().replacingOccurrences(of: "'", with: "") }
            .filter { !$0.isEmpty }
    }

    /// True when `fragment` is a raw word or a left-to-right concatenation of
    /// raw words ("voicetype" ← "voice" + "type").
    private static func composable(_ fragment: String, from rawNorms: Set<String>) -> Bool {
        if rawNorms.contains(fragment) { return true }
        guard fragment.count >= 4 else { return false }
        for i in fragment.indices.dropFirst() {
            let prefix = String(fragment[..<i])
            if rawNorms.contains(prefix),
               composable(String(fragment[i...]), from: rawNorms) || fragment[i...].count <= 2 {
                return true
            }
        }
        return false
    }

    /// Function words too common to prove anything about whether the opening
    /// of the dictation survived into the output.
    static let openerStopwords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "so", "to", "of", "in", "on",
        "at", "for", "with", "about", "from",
        "i", "we", "you", "he", "she", "they", "it", "me", "my", "your", "our", "us",
        "is", "are", "was", "were", "be", "been", "am",
        "do", "does", "did", "have", "has", "had",
        "there", "here", "this", "that", "these", "those",
        "okay", "ok", "yeah", "yes", "well", "just", "like", "really",
        // Self-correction markers: legitimately removed along with the words
        // they retract, so they prove nothing about the opening.
        "no", "not", "wait", "actually", "sorry",
    ]

    /// True when the start of the dictation vanished from the output. The
    /// observed failure mode: the model treats a declarative opener ("we have
    /// to do three things", "the way I see it") as disposable framing and
    /// starts the output partway in — a content loss the retention ratio
    /// misses because the rest survives intact.
    ///
    /// Probe: the distinctive (non-stopword, non-filler, multi-letter) words
    /// among the first eight raw words. If fewer than half survive near the
    /// START of the output, the opening was dropped.
    ///
    /// Two subtleties, both learned from eval false results:
    /// - Survival is positional (first 12 output words). Matching anywhere let
    ///   a probe word collide with an unrelated later word ("the way I see
    ///   it" … "way too much space") and mask a dropped opening.
    /// - Joined code tokens are split for matching (utils.ts → utils, ts), and
    ///   single spoken letters ("t", "s") are not probed, so legitimate code
    ///   rendering near the opening never reads as a drop.
    public static func droppedOpening(raw: String, cleaned: String) -> Bool {
        guard contentWordCount(raw) >= minimumContentWords else { return false }
        let probe = words(raw).prefix(8).filter { word in
            word.count >= 2
                && !RuleBasedCleanup.fillers.contains(word)
                && !spokenSymbols.contains(word)
                && !openerStopwords.contains(word)
        }
        guard probe.count >= 2 else { return false }
        var opening = Set<String>()
        for token in words(cleaned).prefix(12) {
            opening.insert(token)
            for fragment in token.split(whereSeparator: { symbolSeparators.contains($0) })
            where fragment.count >= 2 {
                opening.insert(String(fragment))
            }
        }
        let surviving = probe.filter { opening.contains($0) }.count
        return Double(surviving) < 0.5 * Double(probe.count)
    }

    /// Characters that join spoken words into rendered identifiers/paths.
    private static let symbolSeparators: Set<Character> = [".", "_", "-", "/", "@", "~", ":"]

    /// True when `cleaned` is suspiciously long relative to `raw` — i.e. the
    /// model invented content (e.g. echoed a prompt example) instead of
    /// cleaning what was spoken.
    public static func looksFabricated(raw: String, cleaned: String) -> Bool {
        let rawCount = wordCount(raw)
        guard rawCount >= 3 else { return false }
        let cleanedCount = wordCount(cleaned)
        return Double(cleanedCount) > maximumGrowthRatio * Double(rawCount) + 3
    }

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
