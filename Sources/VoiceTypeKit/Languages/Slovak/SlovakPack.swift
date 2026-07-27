import Foundation

extension LanguagePack {
    /// Slovak.
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `no`, `teda`, `vlastne`, `proste`, `akože`, `oné`, and `tento` can
    ///   hesitate, but every one is also ordinary Slovak content. `hm`/`mhm`
    ///   can communicate thought or agreement. Only the model may remove them,
    ///   and only in context.
    /// - `bodka`, `čiarka`, `pomlčka`, and the other punctuation names are
    ///   normal nouns. They are never unconditional `spokenPunctuation`
    ///   replacements. A Slovak-owned spoken-symbol rule uses them only in
    ///   contexts anchored by a file extension, identifier, email address,
    ///   shell flag, or path.
    /// - A period between digits might be a foreign decimal, version, IP
    ///   address, or file name; digit groups might be a year or identifier.
    ///   The deterministic pass preserves them. Semantic conversion to Slovak
    ///   decimal, thousands, date, and time notation belongs to the model.
    /// - Slovak yes/no questions can have declarative word order. The prefix
    ///   heuristic therefore lists only interrogative words, not finite verbs,
    ///   and omits highly ambiguous `ako` and `či`.
    static let slovak = LanguagePack(
        code: "sk",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Pure non-lexical hesitation spellings only. In particular, hm/mhm
        // are excluded because they can be meaningful responses.
        fillers: ["ehm", "éé", "ééé", "éééé"],
        // All Slovak punctuation names are lexical nouns. Context-anchored
        // technical rendering lives in `SlovakSymbols.swift`.
        spokenPunctuation: [:],
        questionPrefixWords: [
            "čo", "kto", "kde", "kedy", "prečo", "kam", "odkiaľ", "kadiaľ",
            "koľko", "koľký", "koľká", "koľké",
            "aký", "aká", "aké", "akí",
            "ktorý", "ktorá", "ktoré", "ktorí",
            "čí", "čia", "čie",
        ],
        questionSuffixParticles: [],
        stopwords: slovakStopwords,
        // Deliberately nil: a shared integrity gate reserves the pack field for
        // English. The Slovak-owned rule below invokes the same conservative
        // renderer, and unlike the field it also repairs model output.
        symbols: nil,
        prompt: .none,
        rules: slovakRules,
        spokenSymbolWords: SlovakSymbols.spokenWords,
        modelLeadInPatterns: [
            #"(?i)^\s*(?:jasné|samozrejme)[,.!]?\s+(?:tu\s+je|toto\s+je)\s+(?:upravený|vyčistený|opravený)\s+(?:text|prepis)\s*:\s*"#,
            #"(?i)^\s*tu\s+je\s+(?:upravený|vyčistený|opravený)\s+(?:text|prepis)\s*:\s*"#,
        ])

    /// Function words that should neither prove transcript retention nor be
    /// joined into a dictated identifier.
    static let slovakStopwords: Set<String> = [
        "a", "aj", "ale", "alebo", "ani", "aby", "ak", "keď", "že", "či",
        "v", "vo", "na", "do", "od", "z", "zo", "s", "so", "k", "ku", "o",
        "po", "pri", "pre", "pred", "za", "bez", "cez", "medzi", "nad", "pod",
        "u", "okolo",
        "ja", "ty", "on", "ona", "ono", "my", "vy", "oni", "ony",
        "ma", "mi", "mňa", "ťa", "ti", "nás", "nám", "vás", "vám",
        "môj", "moja", "moje", "tvoj", "tvoja", "tvoje", "náš", "váš",
        "je", "som", "si", "sme", "ste", "sú", "bol", "bola", "bolo", "boli",
        "by", "som", "si", "sme", "ste",
        "to", "toto", "ten", "tá", "tie", "tam", "tu", "tak",
        "no", "teda", "vlastne", "proste", "akože", "oné", "tento",
        "nie", "oprava",
    ]

    /// Slovak-owned rules. Placeholder pairs intentionally share terminal
    /// participation so no private-use character can leak into a command.
    private static let slovakRules: [CleanupRule] = [
        CleanupRule(
            name: "mask Slovak decimal commas",
            stage: .early,
            runsInTerminal: true
        ) { text, context in
            SlovakOrthography.maskDecimalCommas(text, context)
        },
        CleanupRule(
            name: "mask abbreviation and ordinal periods",
            stage: .early
        ) { text, context in
            SlovakOrthography.maskNonSentencePeriods(text, context)
        },
        CleanupRule(
            name: "render context-anchored Slovak technical symbols",
            stage: .early,
            runsInTerminal: true
        ) { text, context in
            SlovakSymbols.render(text, context)
        },
        CleanupRule(
            name: "normalize unmistakable Slovak prose marks",
            stage: .early
        ) { text, context in
            SlovakOrthography.normalizeProseMarks(text, context)
        },
        CleanupRule(
            name: "normalize Slovak enclosure and slash spacing",
            stage: .afterPunctuation
        ) { text, context in
            SlovakOrthography.normalizeInnerSpacing(text, context)
        },
        CleanupRule(
            name: "restore masked Slovak decimal commas",
            stage: .final,
            runsInTerminal: true
        ) { text, context in
            SlovakOrthography.restoreDecimalCommas(text, context)
        },
        CleanupRule(
            name: "restore masked abbreviation and ordinal periods",
            stage: .final
        ) { text, context in
            SlovakOrthography.restoreNonSentencePeriods(text, context)
        },
        CleanupRule(
            name: "use fixed spaces before Slovak measurement marks",
            stage: .final
        ) { text, context in
            SlovakOrthography.normalizeMeasurementSpacing(text, context)
        },
    ]
}

private enum SlovakOrthography {
    private static let decimalComma = "\u{E100}"
    private static let nonSentencePeriod = "\u{E101}"
    private static let fixedSpace = "\u{00A0}"

    static func maskDecimalCommas(_ text: String, _: CleanupContext) -> String {
        replace(text, pattern: #"(?<=\d),(?=\d)"#, template: decimalComma)
    }

    static func restoreDecimalCommas(_ text: String, _: CleanupContext) -> String {
        text.replacingOccurrences(of: decimalComma, with: ",")
    }

    static func maskNonSentencePeriods(_ text: String, _: CleanupContext) -> String {
        var out = text
        // Multi-token abbreviations must be masked as a unit: otherwise `t. j.`
        // would capitalize both `j.` and the following ordinary word.
        out = replace(
            out,
            pattern: #"\b(t)\.\s+(j)\.(?=\s+\p{Ll})"#,
            template: "$1\(nonSentencePeriod) $2\(nonSentencePeriod)",
            options: [.caseInsensitive])
        out = replace(
            out,
            pattern: #"\b(a)\s+(pod)\.(?=\s+\p{Ll})"#,
            template: "$1 $2\(nonSentencePeriod)",
            options: [.caseInsensitive])
        out = replace(
            out,
            pattern: #"\b(napr|resp|tzv|atď|príp|porov|obr|tab)\.(?=\s+\p{Ll})"#,
            template: "$1\(nonSentencePeriod)",
            options: [.caseInsensitive])
        // A dot after a digit marks an ordinal number in Slovak, not a sentence
        // boundary: `1. miesto`, `3. verzia`.
        return replace(
            out,
            pattern: #"(?<=\d)\.(?=\s+\p{Ll})"#,
            template: nonSentencePeriod)
    }

    static func restoreNonSentencePeriods(_ text: String, _: CleanupContext) -> String {
        text.replacingOccurrences(of: nonSentencePeriod, with: ".")
    }

    static func normalizeProseMarks(_ text: String, _ context: CleanupContext) -> String {
        guard context.category != .codeEditor else { return text }
        var out = text
        // Preserve an ellipsis before the shared repeated-punctuation pass
        // would flatten three periods to one.
        out = replace(out, pattern: #"\.{3,}"#, template: "…")
        // A spaced ASCII hyphen is unambiguously punctuation, not a compound's
        // hyphen. Slovak prose uses a spaced en dash for this function.
        out = replace(out, pattern: #"\s+-\s+"#, template: " – ")
        // Normalize complete quote pairs only; unmatched ASCII quotes and all
        // single quotes are left alone.
        out = replace(out, pattern: #"“([^”\n]+)”"#, template: "„$1“")
        out = replace(out, pattern: #""([^"\n]+)""#, template: "„$1“")
        // Slovak's apostrophe is U+2019. Limit normalization to obvious
        // apostrophes inside names/foreign words or before a two-digit year.
        out = replace(out, pattern: #"(?<=\p{L})'(?=\p{L})"#, template: "’")
        return replace(out, pattern: #"(?<![\p{L}\p{N}])'(?=\d{2}\b)"#, template: "’")
    }

    static func normalizeInnerSpacing(_ text: String, _ context: CleanupContext) -> String {
        guard context.category != .codeEditor else { return text }
        var out = text
        out = replace(out, pattern: #"([\(\[\{„])\s+"#, template: "$1")
        out = replace(out, pattern: #"\s+([\)\]\}“])"#, template: "$1")
        out = replace(out, pattern: #"(?<=\p{L})„"#, template: " „")
        out = replace(out, pattern: #"“(?=\p{L})"#, template: "“ ")
        out = replace(out, pattern: #"\s+…"#, template: "…")
        out = replace(out, pattern: #"…(?=\S)"#, template: "… ")
        // Slash-separated words and numbers have no surrounding spaces. The
        // letter/digit guards leave mathematical and stylistic uses alone.
        return replace(
            out,
            pattern: #"(?<=[\p{L}\p{N}])\s*/\s*(?=[\p{L}\p{N}])"#,
            template: "/")
    }

    static func normalizeMeasurementSpacing(_ text: String, _ context: CleanupContext) -> String {
        guard context.category != .codeEditor else { return text }
        var out = replace(
            text,
            pattern: #"(\d)[ \t\u{00A0}]*(%|€|EUR\b|USD\b|CZK\b)"#,
            template: "$1\(fixedSpace)$2",
            options: [.caseInsensitive])
        out = replace(
            out,
            pattern: #"(\d)[ \t\u{00A0}]*(°)[ \t]*(C|F)\b"#,
            template: "$1\(fixedSpace)$2$3",
            options: [.caseInsensitive])
        return out
    }

    private static func replace(
        _ text: String,
        pattern: String,
        template: String,
        options: NSRegularExpression.Options = []
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: template)
    }
}
