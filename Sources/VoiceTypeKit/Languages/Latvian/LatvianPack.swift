import Foundation

extension LanguagePack {
    /// Latvian (latviešu valoda).
    ///
    /// Deliberate limits:
    /// - `nu`, `tā`, `tā kā`, `tipa`, `respektīvi`, and `zini` can all carry
    ///   meaning. They are prompt-only fillers; deterministic removal would
    ///   delete real Latvian.
    /// - A lone `ē` is also excluded: it can be a dictated letter. Only
    ///   elongated/non-word hesitation spellings are safe to remove blindly.
    /// - `punkts` is not flat spoken punctuation because it also means a point,
    ///   item, score, or decimal point. The contextual tech-symbol rule renders
    ///   it only beside a known file extension; prose is left alone.
    /// - Decimal points are not blindly changed to commas: a digit-dot-digit
    ///   sequence may be a time, date, version, IP address, or file name.
    /// - Latvian's rich inflection makes ASR word-ending errors common. No rule
    ///   guesses at endings or missing diacritics; those edits need context and
    ///   can change meaning.
    static let latvian = LanguagePack(
        code: "lv",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: [
            "ēē", "ēēē", "ēēēē",
            "emm", "emmm", "emmmm",
        ],
        // Spoken punctuation is context-gated in `rules` so shell commands do
        // not unexpectedly acquire punctuation.
        spokenPunctuation: [:],
        questionPrefixWords: [
            "vai",
            "kas", "ko", "kam",
            "kur", "kad", "kāpēc", "cik", "kā",
            "kurš", "kura", "kuri", "kuras", "kuru", "kuriem", "kurām",
            "kāds", "kāda", "kādi", "kādas",
        ],
        questionSuffixParticles: [],
        stopwords: latvianStopwords,
        prompt: .latvian,
        rules: [
            latvianSpokenTechSymbols,
            latvianSpokenPunctuation,
            latvianProtectNumericPunctuation,
            latvianProtectAbbreviations,
            latvianTypography,
            latvianRestoreAbbreviations,
            latvianRestoreNumericPunctuation,
        ],
        spokenSymbolWords: [
            "punkts", "komats", "defise", "pasvītra", "slīpsvītra", "tilde",
            "et", "atverošā", "aizverošā", "iekava", "kvadrātiekava",
            "kols", "semikols", "domuzīme", "daudzpunkte",
        ],
        modelLeadInPatterns: [
            #"(?i)^\s*(?:protams|labi|skaidrs)[,!.]+\s*(?:lūk[,!.\s]+)?[^\n:]{0,60}(?:attīrītais|izlabotais|sakārtotais)\s+(?:teksts|transkripts)[^\n:]{0,20}:\s+"#,
            #"(?i)^\s*lūk[,!.\s]+(?:attīrītais|izlabotais|sakārtotais)\s+(?:teksts|transkripts)[^\n:]{0,20}:\s+"#,
        ])

    /// Common function words are weak evidence for the faithfulness guard and
    /// unsafe neighbors for a dictated identifier.
    static let latvianStopwords: Set<String> = [
        "aiz", "ap", "ar", "bez", "bet", "caur", "dēļ", "gar", "jo", "ka",
        "lai", "līdz", "no", "par", "pa", "pār", "pēc", "pie", "pirms",
        "pret", "starp", "un", "uz", "vai",
        "es", "tu", "viņš", "viņa", "mēs", "jūs", "viņi", "viņas",
        "man", "tev", "viņam", "viņai", "mums", "jums", "viņiem", "viņām",
        "mans", "tavs", "mūsu", "jūsu", "savs",
        "šis", "šī", "šie", "šīs", "tas", "tā", "tie", "tās", "to",
        "ir", "esmu", "esi", "esam", "esat", "bija", "būs", "būt",
        "nav", "nebija", "nebūs", "var", "varu", "vari", "varam", "varat",
        "te", "tur", "tad", "tagad", "jau", "vēl", "tikai",
        // Contextual discourse markers and correction words are deliberately
        // retained in rules, but they do not prove content survived the model.
        "nu", "tātad", "respektīvi", "tipa", "zini", "nē", "pareizāk",
    ]
}

// MARK: - Spoken punctuation and tech symbols

private let latvianSpokenTechSymbols = CleanupRule(
    name: "render contextual Latvian tech symbols",
    stage: .early,
    runsInTerminal: true
) { text, context in
    SpokenSymbols.render(text, category: context.category, vocabulary: .latvian)
}

private let latvianSpokenPunctuation = CleanupRule(
    name: "render unambiguous Latvian spoken punctuation",
    stage: .early
) { text, _ in
    let names: [(String, String)] = [
        ("atverošās pēdiņas", "„"),
        ("aizverošās pēdiņas", "”"),
        ("atverošā iekava", "("),
        ("aizverošā iekava", ")"),
        ("jautājuma zīme", "?"),
        ("izsaukuma zīme", "!"),
        ("daudzpunkte", "..."),
        ("domuzīme", "–"),
        ("semikols", ";"),
        ("komats", ","),
        ("kols", ":"),
    ]

    var result = text
    for (name, mark) in names {
        let escapedName = NSRegularExpression.escapedPattern(for: name)
        let escapedMark = NSRegularExpression.escapedPattern(for: mark)
        // If the transcriber already emitted the mark as well as its spoken
        // name, consume the duplicate before rendering the name.
        result = latvianRegexReplace(
            result,
            pattern: escapedMark + #"\s*"# + escapedName,
            template: name,
            options: [.caseInsensitive])
        result = latvianRegexReplace(
            result,
            pattern: escapedName + #"\s*"# + escapedMark,
            template: name,
            options: [.caseInsensitive])
        result = latvianRegexReplace(
            result,
            pattern: escapedName,
            template: NSRegularExpression.escapedTemplate(for: mark),
            options: [.caseInsensitive])
    }
    return result
}

// MARK: - Punctuation protection

private let latvianDecimalCommaPlaceholder = "\u{E000}"
private let latvianEllipsisPlaceholder = "\u{E001}"
private let latvianAbbreviationPeriodPlaceholder = "\u{E002}"

/// The shared Latin spacing pass would turn `12,5` into `12, 5`, and its
/// repeated-mark repair would collapse an ellipsis to one period. Both forms
/// are valid in terminals too, so the mask and restore rules opt in together.
private let latvianProtectNumericPunctuation = CleanupRule(
    name: "protect Latvian decimal commas and ellipses",
    stage: .early,
    runsInTerminal: true
) { text, _ in
    latvianRegexReplace(
        text.replacingOccurrences(of: "...", with: latvianEllipsisPlaceholder),
        pattern: #"(?<=\d),(?=\d)"#,
        template: latvianDecimalCommaPlaceholder)
}

private let latvianRestoreNumericPunctuation = CleanupRule(
    name: "restore Latvian decimal commas and ellipses",
    stage: .final,
    runsInTerminal: true
) { text, _ in
    text
        .replacingOccurrences(
            of: latvianEllipsisPlaceholder + ".",
            with: "...")
        .replacingOccurrences(
            of: latvianEllipsisPlaceholder,
            with: "...")
        .replacingOccurrences(
            of: latvianDecimalCommaPlaceholder,
            with: ",")
}

/// Canonical multi-part abbreviations use a non-breaking internal space. Their
/// final period is hidden from the shared sentence-capitalizer so `t. i.
/// piemērs` does not become `t. i. Piemērs`.
private let latvianProtectAbbreviations = CleanupRule(
    name: "normalize and protect Latvian multi-part abbreviations",
    stage: .early
) { text, context in
    guard context.category != .codeEditor else { return text }
    let protected = latvianAbbreviationPeriodPlaceholder
    let replacements: [(String, String)] = [
        (#"(?i)\b([uU])\s*\.\s*tml\s*\."#, "$1.\u{00A0}tml\(protected)"),
        (#"(?i)\b([uU])\s*\.\s*c\s*\."#, "$1.\u{00A0}c\(protected)"),
        (#"(?i)\b([tT])\s*\.\s*i\s*\."#, "$1.\u{00A0}i\(protected)"),
        (#"(?i)\b([šŠ])\s*\.\s*g\s*\."#, "$1.\u{00A0}g\(protected)"),
    ]
    return replacements.reduce(text) { current, replacement in
        latvianRegexReplace(
            current,
            pattern: replacement.0,
            template: replacement.1)
    }
}

private let latvianRestoreAbbreviations = CleanupRule(
    name: "restore Latvian abbreviation periods",
    stage: .final
) { text, context in
    guard context.category != .codeEditor else { return text }
    return text
        .replacingOccurrences(
            of: latvianAbbreviationPeriodPlaceholder + ".",
            with: ".")
        .replacingOccurrences(
            of: latvianAbbreviationPeriodPlaceholder,
            with: ".")
}

// MARK: - Typography

private let latvianTypography = CleanupRule(
    name: "normalize Latvian prose typography",
    stage: .afterPunctuation
) { text, context in
    guard context.category == .general || context.category == .messaging else {
        return text
    }

    var result = text

    // `CleanupPolish` does not rerun the shared Latin spacing pass, so repeat
    // its safe prose subset here for spoken marks left by a model.
    result = latvianRegexReplace(
        result,
        pattern: #"\s+([,.!?;:])"#,
        template: "$1")
    result = latvianRegexReplace(
        result,
        pattern: #"([,!?;])(?=\S)"#,
        template: "$1 ")

    // Latvian quotation marks are low opening and high closing double quotes.
    result = latvianRegexReplace(
        result,
        pattern: #""([^"\n]+)""#,
        template: "„$1”")
    result = latvianRegexReplace(
        result,
        pattern: #"“([^”\n]+)”"#,
        template: "„$1”")
    result = latvianRegexReplace(result, pattern: #"„\s+"#, template: "„")
    result = latvianRegexReplace(result, pattern: #"\s+”"#, template: "”")
    result = latvianRegexReplace(result, pattern: #"\(\s+"#, template: "(")
    result = latvianRegexReplace(result, pattern: #"\s+\)"#, template: ")")

    // Ordinal numerals in worded dates take a period and a (preferably
    // non-breaking) space before `gada` or a month name.
    result = latvianRegexReplace(
        result,
        pattern: #"(?i)(\d{4})\.\s*(?=gad(?:a|ā|u|us|am|iem|os)\b)"#,
        template: "$1.\u{00A0}")
    result = latvianRegexReplace(
        result,
        pattern: #"(?i)(\d{1,2})\.\s*(?=(?:janvār|februār|mart|aprīl|maij|jūnij|jūlij|august|septembr|oktobr|novembr|decembr)\p{L}*\b)"#,
        template: "$1.\u{00A0}")
    result = latvianRegexReplace(
        result,
        pattern: #"(?i)\bplkst\.\s*(?=\d)"#,
        template: "plkst.\u{00A0}")

    // Percent and currency designators follow the amount with a non-breaking
    // space in Latvian. Normalize both foreign prefix order and missing spaces.
    result = latvianRegexReplace(
        result,
        pattern: #"(?i)(?<![\p{L}\p{N}_])([€$£¥]|EUR|USD|GBP|SEK|NOK|DKK|PLN|JPY)\s*(\d+(?:[ \u00A0]\d{3})*(?:[,\uE000]\d+)?)"#,
        template: "$2\u{00A0}$1")
    result = latvianRegexReplace(
        result,
        pattern: #"(?i)(\d+(?:[ \u00A0]\d{3})*(?:[,\uE000]\d+)?)\s*([€$£¥]|EUR|USD|GBP|SEK|NOK|DKK|PLN|JPY)\b"#,
        template: "$1\u{00A0}$2")
    result = latvianRegexReplace(
        result,
        pattern: #"(\d)\s*%"#,
        template: "$1\u{00A0}%")

    return result
}

private func latvianRegexReplace(
    _ text: String,
    pattern: String,
    template: String,
    options: NSRegularExpression.Options = []
) -> String {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
        return text
    }
    let range = NSRange(text.startIndex..., in: text)
    return regex.stringByReplacingMatches(
        in: text,
        options: [],
        range: range,
        withTemplate: template)
}
