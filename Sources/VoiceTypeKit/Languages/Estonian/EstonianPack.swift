import Foundation

extension LanguagePack {
    /// Estonian.
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `aa`, `ää`, `ee`, `öö`, and `mm` occur as filled pauses, but they can
    ///   also be reactions, letter names, abbreviations, or real word forms
    ///   (`öö` = "of the night"; colloquial `ää` = `ära`). Only the
    ///   unlexicalized hesitation `õõ` is removed without context.
    /// - `noh`, `nagu`, `nii`, `siis`, `see`, `tähendab`, and `tegelikult`
    ///   may be discourse fillers, but every one also carries ordinary
    ///   meaning. They are model-only decisions, with an explicit keep-on-doubt
    ///   instruction in `EstonianPrompt.swift`.
    /// - Bare punctuation names (`punkt`, `koma`, `küsimärk`, …) are nouns.
    ///   Blind replacement would corrupt discussion about writing. The
    ///   deterministic rule renders them only after the explicit dictation cue
    ///   `kirjuta` or `kirjavahemärk`; technical `punkt` is separately guarded
    ///   by a known file extension.
    /// - Compound-word joining, inflection repair, number grouping, ranges,
    ///   and foreign-name correction all require lexical or semantic judgment.
    ///   Estonian ASR often gets them wrong, but guessing in a zero-context rule
    ///   would be worse, so the on-device model receives conservative guidance.
    /// - `või` can finish a colloquial question but is also the ordinary word
    ///   "or"; `ega` can open a negative question or a statement. Neither is a
    ///   deterministic question trigger. `kas` is the only safe prefix, and a
    ///   pack rule handles it sentence by sentence because the shared prefix
    ///   heuristic only examines the first token of the whole dictation.
    static let estonian = LanguagePack(
        code: "et",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["õõ"],
        spokenPunctuation: [:],
        questionPrefixWords: [],
        questionSuffixParticles: [],
        stopwords: LanguagePack.estonianStopwords,
        prompt: .estonian,
        rules: EstonianCleanupRules.all,
        spokenSymbolWords: [
            "punkt", "alakriips", "kriips", "sidekriips", "kaldkriips",
            "tilde", "koma", "ätt", "ava", "sulge", "sulg", "sulud",
            "nurksulg", "nurksulud",
        ],
        modelLeadInPatterns: [
            #"(?i)^\s*(?:muidugi|selge|hästi)[,!.]+\s*(?:siin on\s+)?[^\n:]{0,50}(?:puhastatud|parandatud|korrastatud)\s+(?:tekst|transkriptsioon)[^\n:]{0,20}:\s+"#,
            #"(?i)^\s*(?:siin on\s+)?(?:puhastatud|parandatud|korrastatud)\s+(?:tekst|transkriptsioon)\s*:\s+"#,
        ])

    /// Function words are weak evidence that model output preserved a
    /// dictation's opening, and unsafe neighbors for dictated identifiers.
    static let estonianStopwords: Set<String> = [
        "ja", "ning", "või", "aga", "kuid", "et", "kui", "sest", "siis",
        "ega", "ka", "kas", "kuigi",
        "ma", "mina", "mind", "mulle", "minu", "mu", "me", "meie", "meid",
        "sa", "sina", "sind", "sulle", "sinu", "su", "te", "teie", "tema",
        "ta", "teda", "nad", "nemad", "neid",
        "see", "seda", "selle", "need", "nende", "mis", "kes",
        "on", "olen", "oled", "oleme", "olete", "oli", "olid", "olnud",
        "ole", "olla", "ei",
        "üle", "alla", "läbi", "enne", "pärast", "juurde", "peale",
        "siin", "seal", "nüüd", "juba",
        "noh", "nagu", "nii", "tegelikult", "tähendab",
    ]
}

private enum EstonianCleanupRules {
    private static let decimalComma = "\u{E100}"
    private static let monthPeriod = "\u{E101}"
    private static let ellipsis = "\u{E102}"
    private static let numericPeriod = "\u{E103}"

    static let all: [CleanupRule] = [
        .regex(
            name: "protect Estonian decimal commas",
            stage: .early,
            runsInTerminal: true,
            pattern: #"(?<=\d),(?=\d)"#,
            template: decimalComma),
        .regex(
            name: "protect periods before Estonian month names",
            stage: .early,
            runsInTerminal: true,
            pattern: #"(?<=\d)\.(?=\s+(?:jaanuar|veebruar|märts|aprill|mai|juun|juul|august|septembr|oktoobr|novembr|detsembr)\p{L}*\b)"#,
            template: monthPeriod,
            options: [.caseInsensitive]),
        .regex(
            name: "protect Estonian numeric inner periods",
            stage: .early,
            runsInTerminal: true,
            pattern: #"(?<=\d)\.(?=\d)"#,
            template: numericPeriod),
        CleanupRule(
            name: "protect triple periods from shared punctuation collapse",
            stage: .early,
            runsInTerminal: true
        ) { text, _ in
            EstonianText.replace(text, pattern: #"\.{3,}"#, template: ellipsis)
        },
        CleanupRule(
            name: "render explicitly dictated Estonian punctuation",
            stage: .early
        ) { text, _ in
            EstonianText.renderExplicitPunctuation(text)
        },
        CleanupRule(
            name: "render Estonian spoken technical symbols",
            stage: .early,
            runsInTerminal: true
        ) { text, context in
            SpokenSymbols.render(
                text,
                category: context.category,
                vocabulary: .estonian)
        },
        .regex(
            name: "space Estonian euro amounts",
            stage: .afterPunctuation,
            pattern: #"(\d)\s*€"#,
            template: "$1 €"),
        .regex(
            name: "attach Estonian percent signs",
            stage: .afterPunctuation,
            pattern: #"(\d)\s+%"#,
            template: "$1%"),
        .regex(
            name: "format Celsius units",
            stage: .afterPunctuation,
            pattern: #"(\d)\s*°\s*c\b"#,
            template: "$1 °C",
            options: [.caseInsensitive]),
        CleanupRule(
            name: "normalize Estonian prose quotation marks",
            stage: .afterPunctuation
        ) { text, context in
            guard context.category == .general || context.category == .messaging else {
                return text
            }
            return EstonianText.normalizeQuotationMarks(text)
        },
        .regex(
            name: "mark non-initial kas questions",
            stage: .final,
            pattern: #"(^|[.!?]\s+)(kas\s+[^.!?]+)\."#,
            template: "$1$2?",
            options: [.caseInsensitive]),
        CleanupRule(
            name: "restore protected Estonian numeric punctuation",
            stage: .final,
            runsInTerminal: true
        ) { text, _ in
            text
                .replacingOccurrences(of: decimalComma, with: ",")
                .replacingOccurrences(of: monthPeriod, with: ".")
                .replacingOccurrences(of: numericPeriod, with: ".")
        },
        CleanupRule(
            name: "restore Estonian ellipses or code spread operators",
            stage: .final,
            runsInTerminal: true
        ) { text, context in
            let replacement =
                context.category == .general || context.category == .messaging
                ? "…" : "..."
            return text.replacingOccurrences(of: ellipsis, with: replacement)
        },
    ]
}

private enum EstonianText {
    /// Punctuation words remain prose unless the speaker explicitly frames
    /// them as a dictation command. Longest names run first.
    static func renderExplicitPunctuation(_ text: String) -> String {
        let punctuation: [(String, String)] = [
            ("kolm punkti", "…"),
            ("lahtijutumärk", "„"),
            ("kinnijutumärk", "“"),
            ("küsimärk", "?"),
            ("hüüumärk", "!"),
            ("semikoolon", ";"),
            ("mõttekriips", "–"),
            ("koolon", ":"),
            ("koma", ","),
            ("punkt", "."),
        ]
        return punctuation.reduce(text) { current, entry in
            let name = NSRegularExpression.escapedPattern(for: entry.0)
            return replace(
                current,
                pattern: #"\b(?:kirjuta|kirjavahemärk)\s+"# + name + #"\b"#,
                template: NSRegularExpression.escapedTemplate(for: entry.1),
                options: [.caseInsensitive])
        }
    }

    static func normalizeQuotationMarks(_ text: String) -> String {
        var out = text
        let pairs = [
            #""([^"\n]+)""#,
            #"“([^”\n]+)”"#,
            #"”([^”\n]+)”"#,
            #"„([^”\n]+)”"#,
        ]
        for pattern in pairs {
            out = replace(out, pattern: pattern, template: "„$1“")
        }
        out = replace(out, pattern: #"„\s+"#, template: "„")
        out = replace(out, pattern: #"\s+“"#, template: "“")
        return out
    }

    static func replace(_ text: String,
                        pattern: String,
                        template: String,
                        options: NSRegularExpression.Options = []) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: template)
    }
}
