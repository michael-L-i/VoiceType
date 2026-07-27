import Foundation

extension SpokenSymbolVocabulary {
    /// Hungarian spoken-code vocabulary. This value intentionally is not placed
    /// in `LanguagePack.symbols`; a pack-local rule invokes it so the shared
    /// English-only integrity contract remains intact and model output gets the
    /// same repair.
    static let hungarian = SpokenSymbolVocabulary(
        dot: ["pont"],
        underscore: ["aláhúzásjel", "alulvonás", "alsóvonás"],
        dash: ["kötőjel", "mínuszjel", "mínusz"],
        slash: ["perjel"],
        tilde: ["tilde"],
        comma: ["vessző"],
        emailAt: ["kukac"],
        openers: ["nyitó"],
        closers: ["záró"],
        parenNouns: ["zárójel"],
        // "szögletes zárójel" is three tokens with nyitó/záró, beyond the
        // shared two-token bracket grammar; the LLM prompt handles it.
        bracketNouns: [],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h",
            "cpp", "hpp", "java", "rb", "php", "sh", "md", "txt", "json",
            "yaml", "yml", "toml", "html", "css", "xml", "sql", "csv", "log",
            "lock", "env",
        ],
        extensionHomophones: [
            "dzsézon": "json",
            "jézon": "json",
            "jamel": "yaml",
        ],
        emailTLDs: [
            "hu", "com", "net", "org", "io", "co", "dev", "app", "ai", "eu",
            "de", "at", "sk", "ro", "rs",
        ],
        joinGuards: LanguagePack.hungarianStopwords,
        emailLocalGuards: LanguagePack.hungarianStopwords.union([
            "nézd", "nézni", "megy", "menj", "találkozunk", "írj", "írni",
        ]))
}

enum HungarianSpokenSymbols {
    /// Words discounted by the faithfulness guard when they collapse into
    /// punctuation or identifier syntax.
    static let spokenWords: Set<String> = [
        "pont", "aláhúzásjel", "alulvonás", "alsóvonás", "kötőjel",
        "mínuszjel", "mínusz", "perjel", "tilde", "vessző", "kukac",
        "nyitó", "záró", "zárójel", "szögletes", "kérdőjel",
        "felkiáltójel", "kettőspont", "pontosvessző", "gondolatjel",
        "nagykötőjel", "három", "új", "sor", "bekezdés",
        "pé", "ipszilon", "jé", "es", "té", "er", "gé", "ó", "há", "em",
        "dé", "el", "cé", "plusz", "iksz", "vé", "ef", "en", "ká",
    ]

    /// Normalize Hungarian letter-name spellings only next to an explicit
    /// technical marker, then delegate to the shared conservative joiner.
    static func render(_ text: String, context: CleanupContext) -> String {
        var out = text

        let extensions: [(spoken: String, token: String)] = [
            ("té es iksz", "tsx"),
            ("jé es iksz", "jsx"),
            ("ipszilon em el", "yml"),
            ("cé plusz plusz", "cpp"),
            ("há pé pé", "hpp"),
            ("té iksz té", "txt"),
            ("pé ipszilon", "py"),
            ("jé es", "js"),
            ("té es", "ts"),
            ("er es", "rs"),
            ("gé ó", "go"),
            ("es há", "sh"),
            ("em dé", "md"),
            ("cé es es", "css"),
        ]
        for entry in extensions {
            out = replace(
                out,
                pattern: #"(?i)(?<![\p{L}\p{N}_])(pont)\s+\#(entry.spoken)(?![\p{L}\p{N}_])"#,
                template: "$1 \(entry.token)")
        }

        // Hungarian speakers commonly dictate short flags and handle letters
        // by the letter name. Restrict conversion to an explicit dash marker.
        let letterNames: [String: String] = [
            "á": "a", "bé": "b", "cé": "c", "dé": "d", "é": "e", "ef": "f",
            "gé": "g", "há": "h", "í": "i", "jé": "j", "ká": "k", "el": "l",
            "em": "m", "en": "n", "ó": "o", "pé": "p", "kú": "q", "er": "r",
            "es": "s", "té": "t", "ú": "u", "vé": "v", "dupla vé": "w",
            "iksz": "x", "ipszilon": "y", "zé": "z",
        ]
        for (spoken, letter) in letterNames.sorted(by: { $0.key.count > $1.key.count }) {
            out = replace(
                out,
                pattern: #"(?i)(?<![\p{L}\p{N}_])(kötőjel|mínuszjel|mínusz)\s+\#(spoken)(?![\p{L}\p{N}_])"#,
                template: "$1 \(letter)")
        }

        guard containsRenderableCommand(out, category: context.category) else {
            return text
        }

        // SpokenSymbols also assembles literal symbol tokens. Hide punctuation
        // already present in the transcript so only dictated names are joined.
        let literalOpenParen = "\u{E110}"
        let literalCloseParen = "\u{E111}"
        let literalOpenBracket = "\u{E112}"
        let literalCloseBracket = "\u{E113}"
        out = out
            .replacingOccurrences(of: "(", with: literalOpenParen)
            .replacingOccurrences(of: ")", with: literalCloseParen)
            .replacingOccurrences(of: "[", with: literalOpenBracket)
            .replacingOccurrences(of: "]", with: literalCloseBracket)
        return SpokenSymbols.render(
            out, category: context.category, vocabulary: .hungarian)
            .replacingOccurrences(of: literalOpenParen, with: "(")
            .replacingOccurrences(of: literalCloseParen, with: ")")
            .replacingOccurrences(of: literalOpenBracket, with: "[")
            .replacingOccurrences(of: literalCloseBracket, with: "]")
    }

    private static func containsRenderableCommand(
        _ text: String,
        category: AppCategory
    ) -> Bool {
        let words = text.lowercased()
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
        let unambiguousTriggers: Set<String> = [
            "aláhúzásjel", "alulvonás", "alsóvonás", "kukac",
            "nyitó", "záró",
        ]
        if words.contains(where: unambiguousTriggers.contains) { return true }
        if category == .terminal {
            let terminalTriggers: Set<String> = [
                "kötőjel", "mínuszjel", "mínusz", "perjel", "tilde",
            ]
            if words.contains(where: terminalTriggers.contains) { return true }
        }

        let extensions = SpokenSymbolVocabulary.hungarian.fileExtensions
            .union(SpokenSymbolVocabulary.hungarian.extensionHomophones.keys)
            .sorted { $0.count > $1.count }
            .map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
        guard let regex = try? NSRegularExpression(
            pattern: #"(?i)(?<![\p{L}\p{N}_])pont\s+(?:\#(extensions))(?![\p{L}\p{N}_])"#)
        else { return false }
        return regex.firstMatch(
            in: text,
            range: NSRange(text.startIndex..., in: text)) != nil
    }

    private static func replace(_ text: String,
                                pattern: String,
                                template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: template)
    }
}

enum HungarianCleanupRules {
    private static let decimalCommaPlaceholder = "\u{E100}"
    // ONE DOT LEADER is punctuation (so an initial `kb․` still capitalizes)
    // but is not a sentence terminator in the shared capitalization pass.
    private static let protectedPeriodPlaceholder = "\u{2024}"

    static let all: [CleanupRule] = [
        CleanupRule(
            name: "render context-guarded Hungarian spoken symbols",
            stage: .early,
            runsInTerminal: true
        ) { text, context in
            HungarianSpokenSymbols.render(text, context: context)
        },
        CleanupRule(
            name: "render unambiguous Hungarian punctuation commands as whole tokens",
            stage: .early
        ) { text, _ in
            renderPunctuationCommands(text)
        },
        CleanupRule(
            name: "mask Hungarian marks from incompatible shared punctuation rules",
            stage: .early
        ) { text, context in
            guard isProse(context) else { return text }
            return maskSensitiveMarks(text)
        },
        CleanupRule(
            name: "normalize unambiguous Hungarian prose typography",
            stage: .afterPunctuation
        ) { text, context in
            guard isProse(context) else { return text }
            return normalizeTypography(text)
        },
        CleanupRule(
            name: "restore Hungarian protected marks",
            stage: .final
        ) { text, context in
            guard isProse(context) else { return text }
            return text
                .replacingOccurrences(of: decimalCommaPlaceholder, with: ",")
                .replacingOccurrences(of: protectedPeriodPlaceholder, with: ".")
        },
    ]

    private static let punctuationCommands: [(spoken: String, mark: String)] = [
        ("nyitó szögletes zárójel", "["),
        ("záró szögletes zárójel", "]"),
        ("nyitó zárójel", "("),
        ("záró zárójel", ")"),
        ("felkiáltójel", "!"),
        ("pontosvessző", ";"),
        ("kettőspont", ":"),
        ("kérdőjel", "?"),
        ("nagykötőjel", "–"),
        ("gondolatjel", "–"),
        ("kötőjel", "-"),
    ]

    private static let internalAbbreviations = [
        "kb", "pl", "ill", "ún", "ti", "vö",
    ]

    private static let monthOrDateWords = [
        "január", "február", "március", "április", "május", "június",
        "július", "augusztus", "szeptember", "október", "november", "december",
        "évi", "tavaszi", "nyári", "őszi", "téli",
    ]

    private static func isProse(_ context: CleanupContext) -> Bool {
        context.category == .general || context.category == .messaging
    }

    private static func renderPunctuationCommands(_ text: String) -> String {
        var out = text
        let absorbed = #"(?:[,.!?;:()\[\]—–-]\s*)*"#
        for command in punctuationCommands {
            let words = command.spoken
                .split(separator: " ")
                .map { NSRegularExpression.escapedPattern(for: String($0)) }
                .joined(separator: #"\s+"#)
            let pattern = absorbed
                + #"(?<![\p{L}\p{N}_])"#
                + words
                + #"(?![\p{L}\p{N}_])"#
                + absorbed
            guard let regex = try? NSRegularExpression(
                pattern: pattern, options: [.caseInsensitive]) else { continue }
            out = regex.stringByReplacingMatches(
                in: out,
                range: NSRange(out.startIndex..., in: out),
                withTemplate: NSRegularExpression.escapedTemplate(for: command.mark))
        }
        return out
    }

    private static func maskSensitiveMarks(_ text: String) -> String {
        var out = replace(
            text,
            pattern: #"(?<=\d),(?=\d)"#,
            template: decimalCommaPlaceholder)

        // The shared repeated-punctuation pass would reduce `...` to one dot.
        // Unicode ellipsis is already a punctuation character and terminal mark,
        // so it needs no placeholder.
        out = replace(
            out,
            pattern: #"\.{3}"#,
            template: "…")

        // A date's year period and a mid-sentence abbreviation do not end a
        // sentence; hide only cases whose following lowercase token proves it.
        let dateAlternation = monthOrDateWords
            .map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
        out = replace(
            out,
            pattern: #"\b(\d{4})\.(?=\s+(?:\#(dateAlternation))\b)"#,
            template: "$1\(protectedPeriodPlaceholder)",
            options: [.caseInsensitive])

        let abbreviationAlternation = internalAbbreviations
            .map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
        return replace(
            out,
            pattern: #"\b(\#(abbreviationAlternation))\.(?=\s+\p{Ll})"#,
            template: "$1\(protectedPeriodPlaceholder)",
            options: [.caseInsensitive])
    }

    private static func normalizeTypography(_ text: String) -> String {
        var out = text

        // CleanupPolish does not run the shared Latin spacing pass, so enforce
        // the language's mechanical punctuation spacing here as well. Decimal
        // commas are still masked at this stage.
        out = replace(out, pattern: #"\s+([,.!?;:])"#, template: "$1")
        out = replace(
            out,
            pattern: #"([,!?;])(?=\S)"#,
            template: "$1 ")

        // Hungarian opening quotes are low and closing quotes high. Limit the
        // conversion to paired prose quotes; unmatched inch/code marks survive.
        out = replace(
            out,
            pattern: #"["“]([^"“”\n]+)["”]"#,
            template: "„$1”")
        out = replace(out, pattern: #"„\s+"#, template: "„")
        out = replace(out, pattern: #"\s+”"#, template: "”")
        out = replace(out, pattern: #"\(\s+"#, template: "(")
        out = replace(out, pattern: #"\s+\)"#, template: ")")

        // A tagoló kettőspont takes a following space; numeric time and ratios
        // are excluded because their next character is a digit.
        out = replace(out, pattern: #":(?=\p{L})"#, template: ": ")

        // Measures and currencies follow the number with a space. Percent is
        // the explicit Hungarian exception and attaches to the number.
        out = replace(
            out,
            pattern: #"(?<=\d)(?=(?:Ft|HUF|EUR|USD|GBP|mm|cm|km|mg|dkg|kg|ml|cl|dl|kWh|kHz|MHz|GHz|kB|MB|GB|TB)\b)"#,
            template: " ",
            options: [.caseInsensitive])
        out = replace(
            out,
            pattern: #"(?<=\d)(?=[€$£¥])"#,
            template: " ")
        out = replace(
            out,
            pattern: #"(?<=\d)(?=°C\b)"#,
            template: " ")
        out = replace(
            out,
            pattern: #"(\d)\s+%"#,
            template: "$1%")

        return out
    }

    private static func replace(
        _ text: String,
        pattern: String,
        template: String,
        options: NSRegularExpression.Options = []
    ) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: pattern, options: options) else { return text }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: template)
    }
}
