import Foundation

/// Deterministic, dependency-free cleanup. This is the floor everything else
/// degrades to: it always works, offline, with zero models. It removes filler
/// words, collapses whitespace, applies light capitalization, and adds terminal
/// punctuation — without ever rewriting the speaker's words.
public struct RuleBasedCleanup: CleanupEngine {
    public let kind: CleanupEngineKind = .ruleBased

    public init() {}

    public func isAvailable() async -> Bool { true }

    public func cleanup(_ text: String, options: CleanupOptions, context: CleanupContext, locale: String) async throws -> String {
        Self.process(text, options: options, context: context, locale: locale)
    }

    // Exposed as a static, synchronous helper so other engines can reuse it as
    // their own fallback and so it is trivially testable.
    public static func process(_ input: String, options: CleanupOptions,
                               context: CleanupContext = .general,
                               locale: String = "en-US") -> String {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "" }

        // Our deterministic filler list and the standalone-"I" rule are English.
        // Applying them to other languages does nothing useful and can be wrong
        // (e.g. Italian "i" is a real word), so gate them on the language.
        let isEnglish = LanguageTag.code(for: locale) == "en"

        if options.removeFillers && isEnglish {
            text = removeFillers(text)
        }

        text = collapseWhitespace(text)

        // Tidy spacing around punctuation regardless of cleanup options, since
        // raw transcribers occasionally emit " ," or doubled marks.
        text = fixPunctuationSpacing(text)

        // In a terminal the text is likely a shell command: capitalizing the
        // first word ("Git status") or appending a period breaks it, while a
        // missing period on prose is merely cosmetic. Fail conservative.
        let isTerminal = context.category == .terminal

        if options.fixCapitalization {
            if !isTerminal { text = capitalizeSentences(text) }
            if isEnglish { text = capitalizeStandaloneI(text) }
        }

        if options.addPunctuation && !isTerminal {
            text = ensureTerminalPunctuation(text)
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Filler removal

    /// Standalone disfluencies to drop. Kept conservative: only tokens that are
    /// almost never meaningful content. We deliberately do NOT strip "like",
    /// "so", "well" — they're too often real words.
    private static let fillers: Set<String> = [
        "um", "umm", "uh", "uhh", "uhm", "er", "erm", "ah", "hmm", "mhm",
    ]

    private static func removeFillers(_ text: String) -> String {
        // Match a filler as a whole word (optionally trailed by a comma), case
        // insensitive, including any surrounding spaces so we don't leave gaps.
        let pattern = "\\b(" + fillers.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|") + ")\\b,?"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        let stripped = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: " ")
        return collapseWhitespace(stripped)
    }

    // MARK: - Whitespace

    private static func collapseWhitespace(_ text: String) -> String {
        let parts = text.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" })
        return parts.joined(separator: " ")
    }

    private static func fixPunctuationSpacing(_ text: String) -> String {
        var result = text
        // Remove space *before* sentence punctuation: "word ." -> "word."
        result = replace(result, pattern: "\\s+([,.!?;:])", template: "$1")
        // Ensure a single space *after* sentence punctuation when followed by a word.
        result = replace(result, pattern: "([,.!?;:])(?=\\S)", template: "$1 ")
        // Collapse repeated terminal punctuation: "?." or ".." -> first mark.
        result = replace(result, pattern: "([.!?])[.!?]+", template: "$1")
        return collapseWhitespace(result)
    }

    // MARK: - Capitalization

    private static func capitalizeSentences(_ text: String) -> String {
        var chars = Array(text)
        var capitalizeNext = true
        for i in chars.indices {
            let c = chars[i]
            if capitalizeNext, c.isLetter {
                chars[i] = Character(String(c).uppercased())
                capitalizeNext = false
            } else if c == "." || c == "!" || c == "?" {
                capitalizeNext = true
            } else if c == "\n" {
                capitalizeNext = true
            }
        }
        return String(chars)
    }

    /// Capitalize the standalone pronoun "i" -> "I".
    private static func capitalizeStandaloneI(_ text: String) -> String {
        replace(text, pattern: "\\bi\\b", template: "I")
    }

    // MARK: - Terminal punctuation

    private static func ensureTerminalPunctuation(_ text: String) -> String {
        guard let last = text.last else { return text }
        if last == "." || last == "!" || last == "?" || last == ":" || last == "," {
            return text
        }
        return text + "."
    }

    // MARK: - Helpers

    private static func replace(_ text: String, pattern: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
    }
}
