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
        // Everything language-specific — fillers, spoken punctuation, writing
        // conventions — comes from the language pack. Languages nobody has
        // contributed yet get `.neutral`, i.e. the safe passes only.
        process(input, options: options, context: context,
                pack: LanguagePack.pack(for: locale))
    }

    /// The pack-taking form. Internal so a test (or a pack author's own test)
    /// can exercise a pack that isn't registered yet.
    static func process(_ input: String, options: CleanupOptions,
                        context: CleanupContext = .general,
                        pack: LanguagePack) -> String {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "" }

        // The pack's own rules run first, on raw transcriber output, before
        // any shared pass has reshaped it.
        text = pack.rules.applying(.early, to: text, context: context)

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
        // the model prompt does. Only languages that have contributed a
        // vocabulary opt in; the trigger words are the pack's, not English's.
        if let symbols = pack.symbols {
            text = SpokenSymbols.render(text, category: context.category,
                                        vocabulary: symbols)
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

        // After the shared spacing/width pass, so a language can restore a
        // convention that pass would otherwise flatten (French writes a space
        // before ; : ! ?, which `fixPunctuationSpacing` has just removed).
        text = pack.rules.applying(.afterPunctuation, to: text, context: context)

        // In a terminal the text is likely a shell command: capitalizing the
        // first word ("Git status") or appending a period breaks it, while a
        // missing period on prose is merely cosmetic. Fail conservative.
        let isTerminal = context.category == .terminal

        // Capitalization is meaningless without space-separated Latin words —
        // and a leading English fragment inside Chinese dictation must stay
        // exactly as spoken.
        if options.fixCapitalization && pack.separatesWordsWithSpaces {
            if !isTerminal { text = capitalizeSentences(text, pack: pack) }
            if let pronoun = pack.capitalizedStandalonePronoun {
                text = capitalizeStandalonePronoun(text, pronoun: pronoun, pack: pack)
            }
        }

        if options.addPunctuation && !isTerminal {
            // Same deterministic question-mark heuristic the model path gets
            // from CleanupPolish — before the period rule, which would
            // otherwise claim the unpunctuated ending first.
            text = CleanupPolish.ensureQuestionMark(text, pack: pack)
            text = ensureTerminalPunctuation(text, pack: pack)
        }

        // Last word goes to the pack: rules that need to see the finished
        // sentence (Spanish's opening ¿, matched to the ? just appended).
        text = pack.rules.applying(.final, to: text, context: context)

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
    /// names. Unconditional by design (the iOS-dictation convention). Marks
    /// already sitting next to the name are absorbed into the replacement —
    /// engines render "今天很好。句号" and the model wraps names in commas
    /// ("，顿号，") — so the dictated mark always wins without doubling.
    /// Internal: `CleanupPolish` runs the same renderer on model output.
    static func renderSpokenPunctuation(_ text: String, pack: LanguagePack) -> String {
        var out = text
        let absorbed = "[，。、；：？！,]*"
        for (name, mark) in pack.spokenPunctuation.sorted(by: { $0.key.count > $1.key.count }) {
            let pattern = absorbed + NSRegularExpression.escapedPattern(for: name) + absorbed
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(out.startIndex..., in: out)
            out = regex.stringByReplacingMatches(
                in: out, range: range,
                withTemplate: NSRegularExpression.escapedTemplate(for: mark))
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
    private static func capitalizeSentences(_ text: String, pack: LanguagePack) -> String {
        var out: [String] = []
        var capitalizeNext = true
        for word in text.split(separator: " ") {
            var w = String(word)
            if capitalizeNext, isPlainWord(w), let first = w.first, first.isLowercase {
                // The pack's casing, not Swift's: Turkish needs "İstanbul".
                w = pack.uppercased(String(first)) + w.dropFirst()
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

    /// Capitalize a language's standalone one-letter pronoun — English "i" →
    /// "I". Internal (not private) so `CleanupPolish` applies the same rule to
    /// model output.
    ///
    /// Plain `\b` treats `-`, `.`, `/` as boundaries, which would corrupt
    /// identifiers ("michael-L-i" → "michael-L-I"), so the lookarounds also
    /// reject symbol neighbors. Apostrophes stay allowed ("i'll" → "I'll").
    static func capitalizeStandalonePronoun(_ text: String, pronoun: String,
                                            pack: LanguagePack = .english) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: pronoun)
        return replace(text,
                       pattern: "(?<![\\w.\\-_/@~])\(escaped)(?![\\w.\\-_/@~])",
                       template: NSRegularExpression.escapedTemplate(for: pack.uppercased(pronoun)))
    }

    // MARK: - Terminal punctuation

    /// Internal: `CleanupPolish` reuses this for full-width packs — the small
    /// model routinely drops the terminal 。 in Chinese output.
    static func ensureTerminalPunctuation(_ text: String, pack: LanguagePack) -> String {
        guard let last = text.last else { return text }
        if pack.terminalMarks.contains(last) {
            return text
        }
        if pack.usesFullWidthPunctuation {
            // Append 。 only when the sentence actually ends in the language's
            // own script (Han or kana) — a trailing English brand or identifier
            // stays bare, same as the Latin rule below.
            guard let scalar = last.unicodeScalars.first, CJKPunctuation.isCJKLetter(scalar) else {
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
