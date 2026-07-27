import Foundation

extension LanguagePack {
    /// Lithuanian.
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - na / nu / žodžiu / ta prasme / tipo / žinai are discourse words and
    ///   phrases with real meanings. hmm and mmm can express doubt, agreement,
    ///   or enjoyment. Only context may decide whether any of them is filler,
    ///   so they live in the LLM guidance and never in `fillers`.
    /// - taškas is a point, location, score, decimal point, or full stop.
    ///   It is not an unconditional spoken-punctuation replacement. A local
    ///   symbol rule renders it only beside a known file extension, while the
    ///   model handles prose punctuation from context.
    /// - Most Lithuanian question words can also introduce a sentence-initial
    ///   subordinate clause ("Kai grįšime, ...", "Kaip minėjau, ..."). The
    ///   deterministic heuristic therefore uses only explicit interrogative
    ///   particles; semantic question detection stays with the model.
    /// - Missing diacritics, colloquial short forms, inflectional endings, and
    ///   foreign names are lexical decisions. Blind repair would readily turn
    ///   one valid Lithuanian word or identifier into another, so no rule
    ///   guesses at them.
    /// - `symbols` remains nil because shared integrity policy reserves that
    ///   field for English. `render Lithuanian technical symbols` invokes the
    ///   same vocabulary from a local rule, which also repairs model output.
    static let lithuanian = LanguagePack(
        code: "lt",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Written-out hesitation vowels only. The orthography handbook treats
        // repeated ė/e sounds as lengthened interjections; unlike lexical
        // discourse markers, these transcriber tokens carry no proposition.
        fillers: ["ėėė", "ėėėė", "eee", "eeee"],
        // Punctuation-only terms and explicit open/close commands. `taškas`
        // and `brūkšnys` are intentionally absent because both are ordinary
        // content words; technical uses are context-anchored in the local
        // spoken-symbol rule.
        spokenPunctuation: [
            "atidaromosios kabutės": "„",
            "atidarymo kabutės": "„",
            "uždaromosios kabutės": "“",
            "uždarymo kabutės": "“",
            "atidaromasis laužtinis skliaustas": "[",
            "uždaromasis laužtinis skliaustas": "]",
            "atvirasis skliaustas": "(",
            "uždarasis skliaustas": ")",
            "kabliataškis": ";",
            "kabliataškį": ";",
            "dvitaškis": ":",
            "dvitaškį": ":",
            "daugtaškis": "…",
            "daugtaškį": "…",
            "klaustukas": "?",
            "klaustuką": "?",
            "šauktukas": "!",
            "šauktuką": "!",
            "kablelis": ",",
            "kablelį": ",",
        ],
        questionPrefixWords: ["ar", "argi", "nejau", "nejaugi"],
        questionSuffixParticles: [],
        stopwords: LanguagePack.lithuanianStopwords,
        prompt: .lithuanian,
        rules: LithuanianCleanupRules.all,
        spokenSymbolWords: LithuanianCleanupRules.spokenSymbolWords,
        modelLeadInPatterns: [
            #"(?i)^\s*(?:žinoma|gerai|aišku|supratau)[,!.]+\s*(?:štai|čia)?[^\n:]{0,80}:\s+"#,
            #"(?i)^\s*(?:štai|čia)?[^\n:]{0,50}(?:sutvarkytas|išvalytas|pataisytas|redaguotas)\s+(?:tekstas|transkriptas|diktavimo tekstas)[^\n:]{0,20}:\s+"#,
        ])

    /// Function words that neither prove model faithfulness nor make safe
    /// identifier components. Ambiguous discourse markers are included here
    /// without being fillers: the guard may ignore them, but rules keep them.
    static let lithuanianStopwords: Set<String> = [
        "aš", "tu", "jis", "ji", "mes", "jūs", "jie", "jos",
        "man", "mane", "mano", "tau", "tave", "tavo", "mums", "mūsų", "jums", "jūsų",
        "ir", "ar", "argi", "bet", "o", "kad", "jog", "jei", "kai", "nes",
        "su", "be", "į", "iš", "ant", "apie", "prie", "už", "nuo", "per", "po", "iki", "dėl",
        "yra", "buvo", "bus", "būti", "tai", "tas", "ta", "tie", "tos", "šis", "ši", "šie", "šios",
        "čia", "ten", "taip", "ne", "gal", "tik", "dar", "jau", "labai",
        "na", "nu", "gerai", "tiesiog", "žinai", "žodžiu", "tipo",
    ]
}

private enum LithuanianCleanupRules {
    private static let decimalComma = "\u{E100}"
    private static let abbreviationPeriod = "\u{E101}"
    private static let codeStart = "\u{E102}"
    private static let codeEnd = "\u{E103}"
    private static let nonbreakingSpace = "\u{00A0}"

    static let spokenSymbolWords: Set<String> = [
        "taškas", "tašką", "kablelis", "kablelį",
        "pabraukimo", "apatinis", "brūkšnys", "brūkšnelis", "minusas",
        "pasvirasis", "dešininis", "tildė", "eta", "ženklas",
        "atidaromasis", "atvirasis", "kairysis",
        "uždaromasis", "uždarasis", "dešinysis",
        "skliaustas", "skliaustai", "laužtinis",
    ]

    static let all: [CleanupRule] = [
        CleanupRule(
            name: "render Lithuanian technical symbols",
            stage: .early,
            runsInTerminal: true
        ) { text, context in
            LithuanianSpokenSymbols.render(text, category: context.category)
        },
        CleanupRule(
            name: "protect Lithuanian decimal commas",
            stage: .early,
            runsInTerminal: true
        ) { text, _ in
            maskDecimalCommas(in: text)
        },
        CleanupRule(
            name: "protect leading code-editor syntax",
            stage: .early
        ) { text, context in
            protectCodeEditorSyntax(in: text, context: context)
        },
        CleanupRule(
            name: "protect Lithuanian abbreviation periods",
            stage: .early
        ) { text, _ in
            maskAbbreviationPeriods(in: text)
        },
        CleanupRule(
            name: "restore Lithuanian decimal commas",
            stage: .afterPunctuation,
            runsInTerminal: true
        ) { text, _ in
            text.replacingOccurrences(of: decimalComma, with: ",")
        },
        CleanupRule.regex(
            name: "collapse duplicated Lithuanian spoken terminal marks",
            stage: .afterPunctuation,
            pattern: #"([.!?])\s*[.!?]"#,
            template: "$1"),
        CleanupRule(
            name: "restore Lithuanian abbreviation periods",
            stage: .final
        ) { text, _ in
            text.replacingOccurrences(of: abbreviationPeriod, with: ".")
        },
        CleanupRule(
            name: "restore leading code-editor syntax",
            stage: .final
        ) { text, _ in
            restoreCodeEditorSyntax(in: text)
        },
        CleanupRule(
            name: "apply Lithuanian prose typography",
            stage: .final
        ) { text, context in
            applyProseTypography(to: text, context: context)
        },
    ]

    /// A digit-comma-digit sequence is a Lithuanian decimal. Masking it keeps
    /// the shared Latin spacing pass from turning 3,14 into 3, 14. A spoken
    /// kablelis between digits receives the same protection before the flat
    /// punctuation vocabulary runs.
    private static func maskDecimalCommas(in text: String) -> String {
        var out = replace(
            text,
            pattern: #"(?<=\d),(?=\d)"#,
            template: decimalComma)
        out = replace(
            out,
            pattern: #"(?<=\d)\s+(?:kablelis|kablelį)\s+(?=\d)"#,
            template: decimalComma,
            options: [.caseInsensitive])
        return out
    }

    /// The shared prose pass capitalizes and punctuates every code-editor input.
    /// Mask only a leading, lowercase programming keyword and the end of that
    /// same snippet. Lithuanian comments and documentation still receive prose
    /// cleanup, while `let value = "x"` stays executable source.
    private static func protectCodeEditorSyntax(
        in text: String,
        context: CleanupContext
    ) -> String {
        guard context.category == .codeEditor else { return text }
        let pattern = #"^(?:let|var|func|class|struct|enum|protocol|extension|import|return|if|else|for|while|switch|case|guard|throw|try|await)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)) != nil else {
            return text
        }
        return codeStart + text + codeEnd
    }

    private static func restoreCodeEditorSyntax(in text: String) -> String {
        text
            .replacingOccurrences(of: codeStart, with: "")
            .replacingOccurrences(of: codeEnd + ".", with: "")
            .replacingOccurrences(of: codeEnd, with: "")
    }

    /// The shared capitalization pass treats every period-ended token as a
    /// sentence end. Mask recognized abbreviations only when a lowercase word
    /// follows, which prevents "pvz. failą" becoming "pvz. Failą" without
    /// interfering with a true sentence-final period.
    private static func maskAbbreviationPeriods(in text: String) -> String {
        let abbreviations = [
            "t. y.", "t. t.", "t. p.", "š. m.", "a. k.", "a. s.", "p. d.",
            "pvz.", "plg.", "žr.", "kt.", "pan.", "vad.", "mažd.",
            "prof.", "doc.", "dr.", "tel.", "el.", "val.", "min.", "sek.",
            "mėn.", "mln.", "mlrd.", "tūkst.", "m.", "d.", "a.", "g.",
        ]
        let names = abbreviations
            .sorted { $0.count > $1.count }
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
        let pattern = #"(?<![\p{L}\p{N}])(?:\#(names))(?=\s+[a-ząčęėįšųūž])"#
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]) else { return text }

        var out = text
        let matches = regex.matches(
            in: text,
            range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let range = Range(match.range, in: out) else { continue }
            let masked = out[range].replacingOccurrences(
                of: ".",
                with: abbreviationPeriod)
            out.replaceSubrange(range, with: masked)
        }
        return out
    }

    /// Apply conventions that are invariant in Lithuanian prose but unsafe in
    /// source code and shell commands: Lithuanian quote shape, no-break spaces
    /// in grouped numbers and before units, canonical compact numeric dates,
    /// and an en dash in place of a spaced typewriter hyphen.
    private static func applyProseTypography(
        to text: String,
        context: CleanupContext
    ) -> String {
        switch context.category {
        case .terminal, .codeEditor:
            return text
        case .general, .messaging:
            break
        }

        var out = text
        out = replace(
            out,
            pattern: #""([^"\n]+)""#,
            template: "„$1“")
        out = replace(
            out,
            pattern: #"“([^”\n]+)”"#,
            template: "„$1“")
        out = replace(
            out,
            pattern: #"„\s+"#,
            template: "„")
        out = replace(
            out,
            pattern: #"\s+“"#,
            template: "“")
        out = replace(
            out,
            pattern: #"\b(\d{4})\s*-\s*(\d{2})\s*-\s*(\d{2})\b"#,
            template: "$1-$2-$3")
        out = replace(
            out,
            pattern: #"(?<=\d) (?=\d{3}(?:\b|[\s,.]))"#,
            template: nonbreakingSpace)
        out = replace(
            out,
            pattern: #"(\d)[ \#(nonbreakingSpace)]*(?=[%€])"#,
            template: "$1" + nonbreakingSpace)
        out = replace(
            out,
            pattern: #"(\d)[ \#(nonbreakingSpace)]*(Eur)\b"#,
            template: "$1" + nonbreakingSpace + "$2",
            options: [.caseInsensitive])
        out = replace(
            out,
            pattern: #"(\d)[ \#(nonbreakingSpace)]*(m\.|d\.|val\.|min\.|sek\.)"#,
            template: "$1" + nonbreakingSpace + "$2",
            options: [.caseInsensitive])
        out = replace(
            out,
            pattern: #"(\d)[ \#(nonbreakingSpace)]*(kg|mg|km|cm|mm|ml|g|m|l|h)\b"#,
            template: "$1" + nonbreakingSpace + "$2",
            options: [.caseInsensitive])
        out = replace(
            out,
            pattern: #"\s+-\s+"#,
            template: " – ")
        return out
    }

    private static func replace(
        _ text: String,
        pattern: String,
        template: String,
        options: NSRegularExpression.Options = []
    ) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: options) else { return text }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: template)
    }
}
