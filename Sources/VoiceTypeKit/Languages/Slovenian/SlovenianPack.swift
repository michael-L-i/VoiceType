import Foundation

extension LanguagePack {
    /// Slovenian (sl).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `hm`, `mhm`, `no`, `pa`, `torej`, `mislim`, `pravzaprav` and
    ///   `v bistvu` can all carry discourse or lexical meaning. Only `eee`,
    ///   the written form of a non-lexical filled pause, is removed blindly.
    ///   Context-dependent removal belongs to the LLM prompt.
    /// - Spoken punctuation names are ordinary words too: `pika` can mean a
    ///   point or dot, `vejica` a twig, and `vprašaj` is also "ask". The flat
    ///   unconditional punctuation table therefore stays empty. A guarded
    ///   Slovenian symbol rule renders `pika` only before a known extension
    ///   (or inside an email/path) and reaches repaired model output too.
    /// - Colloquial yes/no openers `a` and `mar`, verb-first questions, comma
    ///   placement between clauses, date-looking version numbers, and a bare
    ///   decimal point are context-sensitive. The deterministic floor never
    ///   guesses; the prompt handles them.
    /// - Dialect forms, dual forms, case endings, names, and missing carons are
    ///   not rewritten blindly. An apparently "non-standard" form may be the
    ///   speaker's intended voice or an identifier.
    static let slovenian = LanguagePack(
        code: "sl",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["eee"],
        spokenPunctuation: [:],
        // Explicit interrogative pronouns/adverbs and the standard yes/no
        // particle. Deliberately excludes ambiguous colloquial particles and
        // finite verbs.
        questionPrefixWords: [
            "ali",
            "kaj", "kdo", "koga", "komu", "kom", "čigav", "čigava", "čigavo",
            "čigavi", "čigave",
            "kje", "kam", "kod", "odkod", "kdaj", "zakaj", "čemu",
            "kako", "koliko",
            "kateri", "katera", "katero", "katere", "kateremu", "katerim",
        ],
        questionSuffixParticles: [],
        stopwords: LanguagePack.slovenianStopwords,
        prompt: .slovenian,
        rules: SlovenianCleanupRules.all,
        spokenSymbolWords: SlovenianSymbols.spokenWords,
        modelLeadInPatterns: [
            #"(?i)^\s*(?:seveda[,!]?\s*)?(?:tukaj|tu)\s+(?:je|so)\s+(?:očiščeno|popravljeno|urejeno)\s+besedilo\s*:\s*"#,
            #"(?i)^\s*(?:očiščeno|popravljeno|urejeno)\s+besedilo\s*:\s*"#,
        ])

    /// Function words do not prove that the opening of a Slovenian dictation
    /// survived, and must never become pieces of dictated identifiers.
    static let slovenianStopwords: Set<String> = [
        "a", "ali", "ampak", "da", "če", "in", "ker", "ko", "kot", "oziroma",
        "pa", "ter", "toda", "zato",
        "brez", "do", "iz", "med", "na", "nad", "ob", "od", "po", "pod",
        "pred", "pri", "proti", "s", "skozi", "v", "za", "z",
        "jaz", "ti", "on", "ona", "ono", "midva", "midve", "vidva", "vidve",
        "mi", "vi", "oni", "one", "me", "te", "ga", "jo", "nas", "vas", "jih",
        "moj", "moja", "moje", "tvoj", "tvoja", "tvoje", "svoj", "svoja",
        "ta", "to", "tisti", "tista", "tisto",
        "sem", "si", "sva", "sta", "smo", "ste", "so", "je", "bo", "bodo",
        "bi", "bila", "bilo", "bili", "bile",
        "ne", "ja", "no", "hm", "mhm", "torej", "mislim", "pravzaprav",
    ]
}

private enum SlovenianCleanupRules {
    /// U+2024 is punctuation (so sentence-initial abbreviation tokens can
    /// still capitalize) but is not a sentence terminator. It temporarily
    /// hides abbreviation periods from the shared sentence-capitalizer.
    private static let abbreviationDot = "\u{2024}"
    private static let decimalComma = "\u{E100}"
    private static let asciiEllipsis = "\u{E101}"
    private static let unicodeEllipsis = "\u{E102}"
    private static let clockSeparator = "\u{E103}"

    static let all: [CleanupRule] = [
        CleanupRule(
            name: "render guarded Slovenian spoken symbols",
            stage: .early,
            runsInTerminal: true
        ) { text, context in
            SlovenianSymbols.render(text, context: context)
        },
        CleanupRule.regex(
            name: "protect Slovenian decimal commas",
            stage: .early,
            runsInTerminal: true,
            pattern: #"(?<=\d)\s*,\s*(?=\d)"#,
            template: decimalComma),
        CleanupRule(
            name: "protect Slovenian abbreviation periods",
            stage: .early
        ) { text, _ in
            maskAbbreviationPeriods(in: text)
        },
        CleanupRule(
            name: "protect Slovenian ellipses",
            stage: .early,
            runsInTerminal: true
        ) { text, _ in
            text
                .replacingOccurrences(of: "...", with: asciiEllipsis)
                .replacingOccurrences(of: "…", with: unicodeEllipsis)
        },
        CleanupRule(
            name: "restore Slovenian decimal commas",
            stage: .afterPunctuation,
            runsInTerminal: true
        ) { text, _ in
            text.replacingOccurrences(of: decimalComma, with: ",")
        },
        CleanupRule(
            name: "normalize Slovenian prose typography",
            stage: .afterPunctuation
        ) { text, context in
            guard context.category == .general || context.category == .messaging else {
                return text
            }
            return normalizeProseTypography(text)
        },
        CleanupRule(
            name: "restore Slovenian abbreviation periods",
            stage: .final
        ) { text, _ in
            text
                .replacingOccurrences(of: abbreviationDot + ".", with: ".")
                .replacingOccurrences(of: abbreviationDot, with: ".")
        },
        CleanupRule(
            name: "restore Slovenian clock separators",
            stage: .final
        ) { text, _ in
            text.replacingOccurrences(of: clockSeparator, with: ".")
        },
        CleanupRule(
            name: "restore Slovenian spoken braces",
            stage: .final,
            runsInTerminal: true
        ) { text, _ in
            text
                .replacingOccurrences(
                    of: SlovenianSymbols.closingBraceMarker + ".",
                    with: "}"
                )
                .replacingOccurrences(
                    of: SlovenianSymbols.closingBraceMarker,
                    with: "}"
                )
        },
        CleanupRule(
            name: "restore Slovenian ellipses",
            stage: .final,
            runsInTerminal: true
        ) { text, _ in
            text
                .replacingOccurrences(of: asciiEllipsis + ".", with: "...")
                .replacingOccurrences(of: unicodeEllipsis + ".", with: "…")
                .replacingOccurrences(of: asciiEllipsis, with: "...")
                .replacingOccurrences(of: unicodeEllipsis, with: "…")
        },
    ]

    private static func maskAbbreviationPeriods(in text: String) -> String {
        var out = text

        // Multi-part abbreviations first, so their internal periods never
        // re-arm capitalization (`t. i. primer`, `d. o. o. posluje`).
        let multiPartPatterns = [
            #"\bt\.\s+i\."#,
            #"\bd\.\s+o\.\s+o\."#,
            #"\bs\.\s+p\."#,
            #"\bv\.\s+d\."#,
            #"\bp\.\s+p\."#,
            #"\bk\.\s+o\."#,
            #"\bl\.\s+r\."#,
        ]
        for pattern in multiPartPatterns {
            out = maskPeriods(in: out, matching: pattern)
        }

        // Only established abbreviations whose period is not a sentence
        // boundary. Titles such as `dr.` are excluded: a following name may
        // legitimately need capitalization.
        return maskPeriods(
            in: out,
            matching: #"\b(?:npr|itd|itn|ipd|tj|oz|št|pribl|str|tel|jan|feb|mar|apr|jun|jul|avg|sept|okt|nov|dec)\."#
        )
    }

    private static func maskPeriods(in text: String, matching pattern: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else { return text }
        var out = text
        let matches = regex.matches(
            in: text,
            range: NSRange(text.startIndex..., in: text)
        )
        for match in matches.reversed() {
            guard let range = Range(match.range, in: out) else { continue }
            let masked = out[range].replacingOccurrences(of: ".", with: abbreviationDot)
            out.replaceSubrange(range, with: masked)
        }
        return out
    }

    private static func normalizeProseTypography(_ text: String) -> String {
        var out = replacing(
            text,
            pattern: #"(?<![\p{L}\p{N}_])"([^"\n]+)"(?![\p{L}\p{N}_])"#,
            template: "»$1«"
        )
        out = replacing(out, pattern: #"»\s+"#, template: "»")
        out = replacing(out, pattern: #"\s+«"#, template: "«")

        // Slovenian writes a (preferably non-breaking) space between a number
        // and %, ‰, or a currency symbol, and between a temperature and °C.
        out = replacing(
            out,
            pattern: #"(?<=\d)[ \t ]*(?=[%‰€](?:$|[\s.,!?;:)»]))"#,
            template: "\u{00A0}"
        )
        out = replacing(
            out,
            pattern: #"(?<=\d)[ \t ]*°[ \t]*C\b"#,
            template: "\u{00A0}°C"
        )

        // A clock time introduced by `ob` is unambiguously a time-of-day:
        // Slovenian separates hour and minute with a dot. Colons elsewhere
        // may be measured durations or code and are deliberately preserved.
        out = replacing(
            out,
            pattern: #"\bob\s+([01]?\d|2[0-3]):([0-5]\d)\b"#,
            template: "ob $1\(clockSeparator)$2",
            options: [.caseInsensitive]
        )

        // `dne` anchors the following dotted number as a calendar date, making
        // the required spaces safe. Unanchored 1.5.2026 may be a version.
        out = replacing(
            out,
            pattern: #"\bdne\s+([0-3]?\d)\.\s*([01]?\d)\.\s*((?:19|20)\d{2})\b"#,
            template: "dne $1. $2. $3",
            options: [.caseInsensitive]
        )
        return out
    }

    private static func replacing(
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
            withTemplate: template
        )
    }
}
