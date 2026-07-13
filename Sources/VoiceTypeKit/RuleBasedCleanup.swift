import Foundation

/// Deterministic, dependency-free cleanup. This is the floor everything else
/// degrades to: it always works, offline, with zero models. It removes filler
/// words, collapses whitespace, renders spoken symbols (`SpokenSymbols`),
/// applies light capitalization, and adds terminal punctuation — without ever
/// rewriting the speaker's words.
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

        // Everything language-specific — fillers, spoken punctuation, writing
        // conventions — comes from the language pack. Languages nobody has
        // contributed yet get `.neutral`, i.e. the safe passes only.
        let pack = LanguagePack.pack(for: locale)

        if options.removeFillers && !pack.fillers.isEmpty {
            text = removeFillers(text, pack: pack)
        }

        text = collapseWhitespace(text)

        // Spoken punctuation names ("句号" → "。") render before any spacing
        // or terminal-punctuation pass sees the text.
        if !pack.spokenPunctuation.isEmpty {
            text = renderSpokenPunctuation(text, pack: pack)
        }

        // Render spoken symbol names ("main dot pie" → main.py) the same way
        // the model prompt does. English-only by SpokenSymbols' contract: the
        // trigger words are English.
        if pack.code == "en" {
            text = SpokenSymbols.render(text, category: context.category)
        }

        // Tidy spacing/width around punctuation regardless of cleanup options,
        // since raw transcribers occasionally emit " ," or doubled marks.
        // Full-width languages get the CJK conventions instead of the
        // Latin-spacing rules.
        if pack.usesFullWidthPunctuation {
            text = CJKPunctuation.normalize(text)
        } else {
            text = fixPunctuationSpacing(text)
        }

        // In a terminal the text is likely a shell command: capitalizing the
        // first word ("Git status") or appending a period breaks it, while a
        // missing period on prose is merely cosmetic. Fail conservative.
        let isTerminal = context.category == .terminal

        // Capitalization is meaningless without space-separated Latin words —
        // and a leading English fragment inside Chinese dictation must stay
        // exactly as spoken.
        if options.fixCapitalization && pack.separatesWordsWithSpaces {
            if !isTerminal { text = capitalizeSentences(text) }
            if pack.code == "en" { text = capitalizeStandaloneI(text) }
        }

        if options.addPunctuation && !isTerminal {
            // Same deterministic question-mark heuristic the model path gets
            // from CleanupPolish — before the period rule, which would
            // otherwise claim the unpunctuated ending first.
            text = CleanupPolish.ensureQuestionMark(text, pack: pack)
            text = ensureTerminalPunctuation(text, pack: pack)
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Filler removal

    private static func removeFillers(_ text: String, pack: LanguagePack) -> String {
        let names = pack.fillers
            .sorted { $0.count > $1.count }
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
        let pattern: String
        if pack.separatesWordsWithSpaces {
            // Match a filler as a whole word (optionally trailed by a comma),
            // case insensitive, including any surrounding spaces so we don't
            // leave gaps.
            pattern = "\\b(" + names + ")\\b,?"
        } else {
            // No word boundaries in CJK text. A filler run is removed only when
            // anchored at the start or after whitespace/punctuation — engines
            // punctuate disfluencies ("嗯，今天…"), and the anchor keeps rare
            // legitimate uses mid-word (呃逆) intact.
            pattern = "(?:^|(?<=[\\s\\p{P}]))(?:" + names + ")+[，、,]?"
        }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        let template = pack.separatesWordsWithSpaces ? " " : ""
        let stripped = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
        return collapseWhitespace(stripped)
    }

    // MARK: - Spoken punctuation

    /// Direct longest-name-first replacement of the pack's spoken punctuation
    /// names. Unconditional by design (the iOS-dictation convention); doubled
    /// marks from an engine that already rendered the name are collapsed by
    /// the pack's punctuation normalization right after.
    private static func renderSpokenPunctuation(_ text: String, pack: LanguagePack) -> String {
        var out = text
        for (name, mark) in pack.spokenPunctuation.sorted(by: { $0.key.count > $1.key.count }) {
            out = out.replacingOccurrences(of: name, with: mark)
        }
        return out
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
        // Ensure a single space *after* sentence punctuation when followed by a
        // word. Deliberately excludes "." and ":" — they appear inside rendered
        // identifiers, paths, and times (main.py, ~/x, 5:30), which a blind
        // space-after rule would split apart.
        result = replace(result, pattern: "([,!?;])(?=\\S)", template: "$1 ")
        // Collapse repeated terminal punctuation: "?." or ".." -> first mark.
        result = replace(result, pattern: "([.!?])[.!?]+", template: "$1")
        return collapseWhitespace(result)
    }

    // MARK: - Capitalization

    /// Word-wise so identifiers survive: only a *plain* word (letters and
    /// apostrophes) at a sentence start gains a capital, and only punctuation
    /// that ends a word re-arms the rule — the dots inside "main.py" are
    /// neither a sentence end nor a capitalizable start.
    private static func capitalizeSentences(_ text: String) -> String {
        var out: [String] = []
        var capitalizeNext = true
        for word in text.split(separator: " ") {
            var w = String(word)
            if capitalizeNext, isPlainWord(w), let first = w.first, first.isLowercase {
                w = first.uppercased() + w.dropFirst()
            }
            capitalizeNext = w.hasSuffix(".") || w.hasSuffix("!") || w.hasSuffix("?")
            out.append(w)
        }
        return out.joined(separator: " ")
    }

    /// True when the token is an ordinary word once trailing/leading punctuation
    /// is trimmed — same notion `CleanupPolish.capitalizeFirstPlainWord` uses.
    private static func isPlainWord(_ token: String) -> Bool {
        let core = token.trimmingCharacters(in: .punctuationCharacters)
        return !core.isEmpty && core.allSatisfy { $0.isLetter || $0 == "'" }
    }

    /// Capitalize the standalone pronoun "i" -> "I". Internal (not private) so
    /// `CleanupPolish` applies the same rule to model output.
    ///
    /// Plain `\b` treats `-`, `.`, `/` as boundaries, which would corrupt
    /// identifiers ("michael-L-i" → "michael-L-I"), so the lookarounds also
    /// reject symbol neighbors. Apostrophes stay allowed ("i'll" → "I'll").
    static func capitalizeStandaloneI(_ text: String) -> String {
        replace(text, pattern: "(?<![\\w.\\-_/@~])i(?![\\w.\\-_/@~])", template: "I")
    }

    // MARK: - Terminal punctuation

    private static func ensureTerminalPunctuation(_ text: String, pack: LanguagePack) -> String {
        guard let last = text.last else { return text }
        if ".!?:,。！？：，…；;\n".contains(last) {
            return text
        }
        if pack.usesFullWidthPunctuation {
            // Append 。 only when the sentence actually ends in the language's
            // own script — a trailing English brand or identifier stays bare,
            // same as the Latin rule below.
            guard let scalar = last.unicodeScalars.first, CJKPunctuation.isHan(scalar) else {
                return text
            }
            return text + pack.terminalPeriod
        }
        // A sentence ending in an identifier, path, email, or file name keeps
        // its bare ending: a period glued onto "main.py" or an address is worse
        // than a missing one on prose.
        let lastToken = text.split(separator: " ").last.map(String.init) ?? ""
        if lastToken.contains(where: { "_/~@()[]".contains($0) }) { return text }
        if lastToken.range(of: "\\.[A-Za-z0-9]{1,6}$", options: .regularExpression) != nil {
            return text
        }
        return text + pack.terminalPeriod
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
