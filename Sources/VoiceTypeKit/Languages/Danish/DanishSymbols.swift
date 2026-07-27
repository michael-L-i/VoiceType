import Foundation

/// Danish's local rule set. Spoken symbols deliberately run through a rule
/// instead of `LanguagePack.symbols`: this reaches model output as well as the
/// zero-latency path and keeps the pack compatible with the cross-pack policy
/// that only English owns the shared field.
enum DanishCleanupRules {
    private static let decimalCommaPlaceholder = "\u{E100}"
    private static let abbreviationPeriodPlaceholder = "\u{E101}"

    static let all: [CleanupRule] = [
        CleanupRule.regex(
            name: "protect Danish decimal commas",
            stage: .early,
            runsInTerminal: true,
            pattern: #"(?<=\d),(?=\d)"#,
            template: decimalCommaPlaceholder),

        CleanupRule(
            name: "render contextual Danish spoken symbols",
            stage: .early,
            runsInTerminal: true
        ) { text, context in
            DanishSpokenCommands.renderSymbols(text, context: context)
        },

        CleanupRule(
            name: "render Danish spoken punctuation",
            stage: .early
        ) { text, _ in
            DanishSpokenCommands.renderPunctuation(text)
        },

        CleanupRule.regex(
            name: "protect Danish abbreviation periods",
            stage: .early,
            pattern: #"(?i)\b(bl\.a|dvs|osv|m\.fl|m\.m|f\.eks|ca|kl|kr|nr|evt|inkl|ekskl|jf|hhv|vedr|tlf)\."#,
            template: "$1\(abbreviationPeriodPlaceholder)"),

        CleanupRule(
            name: "normalize spacing for dictated Danish brackets and quotes",
            stage: .afterPunctuation,
            runsInTerminal: true
        ) { text, _ in
            DanishSpokenCommands.normalizePairedMarkSpacing(text)
        },

        CleanupRule.regex(
            name: "space Danish krone abbreviations",
            stage: .afterPunctuation,
            pattern: #"(?i)(?<=\d)[ \t]*(?=kr\.?(?![\p{L}\p{N}]))"#,
            template: " "),

        CleanupRule.regex(
            name: "complete Danish krone abbreviations",
            stage: .afterPunctuation,
            pattern: "(?i)(?<=\\d) (kr)(?![.\(abbreviationPeriodPlaceholder)])(?![\\p{L}\\p{N}])",
            template: " $1."),

        CleanupRule.regex(
            name: "complete Danish clock abbreviations",
            stage: .afterPunctuation,
            pattern: #"(?i)\bkl(?!\.)(?=\s+\d{1,2}(?:[.:]\d{2})?\b)"#,
            template: "kl."),

        CleanupRule(
            name: "restore Danish abbreviation periods",
            stage: .final
        ) { text, _ in
            text
                .replacingOccurrences(
                    of: abbreviationPeriodPlaceholder + ".",
                    with: ".")
                .replacingOccurrences(
                    of: abbreviationPeriodPlaceholder,
                    with: ".")
        },

        CleanupRule(
            name: "restore Danish decimal commas",
            stage: .final,
            runsInTerminal: true
        ) { text, _ in
            text.replacingOccurrences(of: decimalCommaPlaceholder, with: ",")
        },

        CleanupRule(
            name: "render Danish spoken line breaks",
            stage: .final
        ) { text, _ in
            DanishSpokenCommands.renderLineBreaks(text)
        },
    ]

    /// Discount only actual Danish command vocabulary in the faithfulness
    /// guard. Ordinary words that merely resemble English symbol names are not
    /// included.
    static let spokenSymbolWords: Set<String> = [
        "anførselstegn", "apostrof", "bindestreg", "cirkumfleks", "dollartegn",
        "ellipse", "gradtegn", "hashtag", "hash-tegn", "kantet", "kolon", "komma",
        "krøllet", "lighedstegn", "lodret", "minustegn", "nummertegn", "og-tegn",
        "omvendt", "parentes", "plustegn", "procenttegn", "punkt", "punktum", "prik",
        "pundtegn", "semikolon", "skråstreg", "snabel-a", "startparentes",
        "startvinkelparentes", "slutanførselstegn", "slutparentes",
        "slutvinkelparentes", "spørgsmålstegn", "streg", "tankestreg", "tilde",
        "udråbstegn", "understregning", "underscore",
    ]
}

private extension SpokenSymbolVocabulary {
    static let danish = SpokenSymbolVocabulary(
        dot: ["punktum", "punkt", "prik"],
        underscore: ["understregning", "underscore"],
        dash: ["bindestreg"],
        slash: ["skråstreg", "slash"],
        tilde: ["tilde"],
        comma: ["komma"],
        emailAt: ["snabel-a", "snabel a", "@-tegn"],
        openers: ["start", "åben", "venstre"],
        closers: ["slut", "luk", "højre"],
        parenNouns: ["parentes"],
        bracketNouns: ["klamme", "bracket"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
            "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
            "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
            "pdf", "docx", "xlsx", "zip",
        ],
        extensionHomophones: [
            "pie": "py",
        ],
        emailTLDs: [
            "dk", "com", "net", "org", "io", "co", "dev", "app", "ai", "eu", "nu",
        ],
        joinGuards: LanguagePack.danishStopwords,
        emailLocalGuards: LanguagePack.danishStopwords.union([
            "se", "ser", "kig", "kigger", "gå", "går", "kom", "kommer",
            "mød", "møder", "tilbage", "hen", "hjem",
        ]))
}

private enum DanishSpokenCommands {
    /// These are Apple's published Danish dictation command names. Multiword
    /// and `-tegn` forms are sufficiently explicit for unconditional rendering.
    /// The shorter punctuation nouns use the guarded path below.
    private static let directSymbolCommands: [String: String] = [
        "enkelt slutanførselstegn": "’",
        "enkelt startanførselstegn": "‘",
        "kantet startparentes": "[",
        "kantet slutparentes": "]",
        "krøllet startparentes": "{",
        "krøllet slutparentes": "}",
        "omvendt skråstreg": "\\",
        "større end-tegn": ">",
        "mindre end-tegn": "<",
        "startvinkelparentes": "<",
        "slutvinkelparentes": ">",
        "slutanførselstegn": "”",
        "startparentes": "(",
        "slutparentes": ")",
        "multiplikationstegn": "×",
        "understregning": "_",
        "lighedstegn": "=",
        "procenttegn": "%",
        "nummertegn": "#",
        "hash-tegn": "#",
        "pundtegn": "#",
        "dollartegn": "$",
        "plustegn": "+",
        "minustegn": "-",
        "gradtegn": "°",
        "og-tegn": "&",
        "@-tegn": "@",
        "snabel-a": "@",
        "lodret streg": "|",
        "cirkumfleks": "^",
        "skråstreg": "/",
        "bindestreg": "-",
        "tilde": "~",
        "apostrof": "’",
    ]

    private static let punctuationCommands: [String: String] = [
        "enkelt slutanførselstegn": "’",
        "enkelt startanførselstegn": "‘",
        "slutanførselstegn": "”",
        "anførselstegn": "“",
        "spørgsmålstegn": "?",
        "udråbstegn": "!",
        "semikolon": ";",
        "tankestreg": "–",
        "ellipse": "…",
        "punktum": ".",
        "komma": ",",
        "kolon": ":",
    ]

    /// Words next to a punctuation noun that strongly indicate the speaker is
    /// talking about the mark rather than issuing a dictation command.
    private static let metalinguisticNeighbors: Set<String> = [
        "anførsel", "betegner", "betyder", "bruge", "bruger", "bruges", "en", "et",
        "forklare", "forklarer", "før", "hedder", "kalder", "kaldes", "kommaet",
        "mangler", "navnet", "nævne", "nævner", "om", "ord", "ordet", "punktummet",
        "sige", "siger", "skrive", "skriver", "staves", "symbolet", "sætte",
        "tegnet", "tegn", "udtale", "udtales", "uden",
    ]

    static func renderSymbols(_ text: String, context: CleanupContext) -> String {
        let contextual = SpokenSymbols.render(
            text,
            category: context.category,
            vocabulary: .danish)
        return replacingContextualWholeWordCommands(
            contextual,
            commands: directSymbolCommands,
            requiresContextGuard: context.category != .terminal &&
                context.category != .codeEditor)
    }

    static func renderPunctuation(_ text: String) -> String {
        replacingPunctuationCommands(
            text,
            commands: punctuationCommands,
            requiresContextGuard: true)
    }

    static func renderLineBreaks(_ text: String) -> String {
        var out = replacingContextualWholeWordCommands(
            text,
            commands: [
                "nyt afsnit": "\n\n",
                "ny linje": "\n",
            ],
            requiresContextGuard: true)
        // Consume horizontal whitespace left around a successfully inserted
        // break; spaces in a protected prose phrase are untouched.
        guard let regex = try? NSRegularExpression(pattern: #"[ \t]*\n[ \t]*"#) else {
            return out
        }
        let range = NSRange(out.startIndex..., in: out)
        out = regex.stringByReplacingMatches(
            in: out,
            range: range,
            withTemplate: "\n")
        return out
    }

    private static func replacingContextualWholeWordCommands(
        _ text: String,
        commands: [String: String],
        requiresContextGuard: Bool
    ) -> String {
        var out = text
        for (command, symbol) in commands.sorted(by: { $0.key.count > $1.key.count }) {
            let escaped = NSRegularExpression.escapedPattern(for: command)
            let pattern = #"(?i)(?<![\p{L}\p{N}_])"# + escaped + #"(?![\p{L}\p{N}_])"#
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(out.startIndex..., in: out)
            let matches = regex.matches(in: out, range: range)
            for match in matches.reversed() {
                guard let matchRange = Range(match.range, in: out) else { continue }
                if requiresContextGuard {
                    let previous = nearestWord(
                        in: out[..<matchRange.lowerBound],
                        fromEnd: true)
                    let next = nearestWord(
                        in: out[matchRange.upperBound...],
                        fromEnd: false)
                    if previous.map(metalinguisticNeighbors.contains) == true ||
                        next.map(metalinguisticNeighbors.contains) == true {
                        continue
                    }
                }
                out.replaceSubrange(matchRange, with: symbol)
            }
        }
        return out
    }

    static func normalizePairedMarkSpacing(_ text: String) -> String {
        var out = text
        let substitutions: [(String, String)] = [
            (#"([\(\[\{<“‘])\s+"#, "$1"),
            (#"\s+([\)\]\}>”’])"#, "$1"),
            (#"([,.!?;:])\s*\1+"#, "$1"),
        ]
        for (pattern, template) in substitutions {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(out.startIndex..., in: out)
            out = regex.stringByReplacingMatches(
                in: out,
                range: range,
                withTemplate: template)
        }
        return out
    }

    private static func replacingPunctuationCommands(
        _ text: String,
        commands: [String: String],
        requiresContextGuard: Bool
    ) -> String {
        var out = text
        for (command, mark) in commands.sorted(by: { $0.key.count > $1.key.count }) {
            let escaped = NSRegularExpression.escapedPattern(for: command)
            let pattern =
                #"(?i)(?:[,.!?;:]\s*)?(?<![\p{L}\p{N}_])"# +
                escaped +
                #"(?![\p{L}\p{N}_])(?:\s*[,.!?;:])?"#
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let fullRange = NSRange(out.startIndex..., in: out)
            let matches = regex.matches(in: out, range: fullRange)
            for match in matches.reversed() {
                guard let range = Range(match.range, in: out) else { continue }
                if requiresContextGuard {
                    let previous = nearestWord(in: out[..<range.lowerBound], fromEnd: true)
                    let next = nearestWord(in: out[range.upperBound...], fromEnd: false)
                    if previous.map(metalinguisticNeighbors.contains) == true ||
                        next.map(metalinguisticNeighbors.contains) == true {
                        continue
                    }
                }
                out.replaceSubrange(range, with: mark)
            }
        }
        return out
    }

    private static func nearestWord(
        in text: Substring,
        fromEnd: Bool
    ) -> String? {
        let words = text.split(whereSeparator: { !$0.isLetter })
        let word = fromEnd ? words.last : words.first
        return word.map { String($0).lowercased() }
    }
}
