import Foundation

/// Deterministic touch-ups applied to *model* output after sanitizing. The
/// small on-device model is unreliable at exactly these mechanical details —
/// eval showed it leaving whole outputs lowercase, lone "i" pronouns, and
/// literal joiner words inside identifiers — so we guarantee them in code
/// instead of spending prompt tokens asking harder.
///
/// Everything here must be conservative: a rule that could corrupt a
/// legitimate output (file names, commands) doesn't belong in a blind
/// post-pass.
public enum CleanupPolish {
    public static func apply(_ text: String,
                             options: CleanupOptions,
                             context: CleanupContext = .general,
                             locale: String = "en-US") -> String {
        var out = text
        // The model sometimes keeps the spoken joiner inside an identifier:
        // "max_underscore_retries" → "max_retries". Underscores only ever come
        // from explicit dictation, so this replacement cannot touch prose.
        out = out.replacingOccurrences(
            of: "_underscore_", with: "_", options: [.caseInsensitive])

        // The model occasionally drifts into CJK punctuation ("。" for ".") even
        // when the words stay English — below the script guard's radar, since
        // punctuation isn't letters. Repair it unless the dictation language
        // legitimately writes with these marks.
        if !cjkPunctuationLanguages.contains(LanguageTag.code(for: locale)) {
            out = normalizeForeignPunctuation(out)
        }

        // The remaining repairs are prose rules: skip them in a terminal,
        // where "git status" must never gain a capital or a "?".
        let isTerminal = context.category == .terminal

        if options.addPunctuation && !isTerminal {
            out = ensureQuestionMark(out)
        }
        guard options.fixCapitalization, !isTerminal else { return out }
        if LanguageTag.code(for: locale) == "en" {
            out = RuleBasedCleanup.capitalizeStandaloneI(out)
        }
        return capitalizeFirstPlainWord(out)
    }

    /// Languages whose orthography uses the full-width marks below — for them
    /// the marks are correct output, never drift.
    static let cjkPunctuationLanguages: Set<String> = ["zh", "ja", "ko", "yue"]

    /// Full-width / CJK punctuation → the ASCII the speaker's language expects.
    static let foreignPunctuation: [Character: String] = [
        "。": ".", "，": ",", "、": ",", "？": "?", "！": "!",
        "：": ":", "；": ";", "（": "(", "）": ")", "\u{3000}": " ",
    ]

    static func normalizeForeignPunctuation(_ text: String) -> String {
        guard text.contains(where: { foreignPunctuation[$0] != nil }) else { return text }
        return String(text.flatMap { foreignPunctuation[$0] ?? String($0) })
    }

    /// English words that open a direct question.
    static let interrogatives: Set<String> = [
        "what", "where", "when", "who", "whom", "whose", "why", "how",
        "is", "are", "am", "was", "were", "do", "does", "did",
        "can", "could", "will", "would", "should", "shall", "may", "might",
    ]

    /// Append "?" to an unpunctuated output that opens like a question. Fires
    /// only when the model left NO terminal punctuation at all — if it chose
    /// "." or anything else, we respect that choice.
    static func ensureQuestionMark(_ text: String) -> String {
        guard let last = text.last, last.isLetter || last.isNumber else { return text }
        let first = text.prefix(while: { !$0.isWhitespace }).lowercased()
        guard interrogatives.contains(first) else { return text }
        return text + "?"
    }

    /// Uppercase the first letter, but only when the leading token is a plain
    /// word. A leading identifier, path, or file name ("app.py is missing",
    /// "~/projects has moved") must stay exactly as rendered.
    static func capitalizeFirstPlainWord(_ text: String) -> String {
        guard let firstChar = text.first, firstChar.isLowercase else { return text }
        // Trailing punctuation ("yeah,") is fine; internal symbols ("app.py",
        // "get_user", "~/x") mean the token is not a plain word.
        let firstToken = text.prefix(while: { !$0.isWhitespace })
            .trimmingCharacters(in: .punctuationCharacters)
        guard !firstToken.isEmpty,
              firstToken.allSatisfy({ $0.isLetter || $0 == "'" }) else { return text }
        return firstChar.uppercased() + text.dropFirst()
    }
}
