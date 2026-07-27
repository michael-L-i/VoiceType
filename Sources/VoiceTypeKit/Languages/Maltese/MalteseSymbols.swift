import Foundation

extension SpokenSymbolVocabulary {
    /// Technical Maltese is routinely code-switched, so the vocabulary admits
    /// the established English trigger alongside Maltese `punt`, `sing`,
    /// `virgola`, and `parentesi`. Neighbor guards keep those ordinary nouns
    /// as prose unless a known code shape surrounds them.
    static let maltese = SpokenSymbolVocabulary(
        dot: ["punt", "dot"],
        underscore: ["underscore"],
        dash: ["sing", "dash"],
        slash: ["slash"],
        tilde: ["tilde"],
        comma: ["virgola", "comma"],
        emailAt: ["at"],
        openers: ["iftaħ", "open"],
        closers: ["agħlaq", "close"],
        parenNouns: ["parentesi", "paren", "parens"],
        bracketNouns: ["bracket", "brackets"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
            "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
            "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
        ],
        extensionHomophones: [
            "pie": "py",
            "paj": "py",
        ],
        emailTLDs: [
            "com", "net", "org", "io", "co", "dev", "app", "ai", "edu", "gov", "me",
            "mt",
        ],
        joinGuards: LanguagePack.malteseStopwords,
        emailLocalGuards: LanguagePack.malteseStopwords.union([
            "ara", "mur", "ejja", "iltaqa", "iltaqgħu", "wasal", "waslu",
        ]))

    /// Discount both Maltese and code-switched technical trigger words in the
    /// model faithfulness guard. This does not enable the pack's forbidden
    /// `symbols` field; the local cleanup rule invokes the vocabulary.
    static let malteseSpokenWords: Set<String> = [
        "punt", "dot", "underscore", "sing", "dash", "slash", "tilde",
        "virgola", "comma", "at", "iftaħ", "agħlaq", "open", "close",
        "parentesi", "paren", "parens", "bracket", "brackets",
        "punt finali", "punt interrogattiv", "punt esklamattiv",
        "punt u virgola", "żewġ punti", "marka tal-mistoqsija",
        "marka tal-esklamazzjoni", "għelm il-mistoqsija", "għelm il-għaġeb",
        "virgoletti miftuħa", "virgoletti magħluqa",
        "linja ġdida", "paragrafu ġdid",
    ]
}

enum MalteseCleanupRules {
    private static let groupingComma = "\u{E100}"
    private static let abbreviationPeriod = "\u{E101}"
    private static let protectedCodeToken = "\u{E102}"
    private static let decimalPoint = "\u{E103}"
    // A real Unicode letter keeps the shared "plain word" capitalization
    // predicate true while temporarily standing in for an article hyphen.
    private static let articleHyphen = "\u{01BB}"
    private static let openQuote = "\u{E110}"
    private static let closeQuote = "\u{E111}"
    private static let openParen = "\u{E112}"
    private static let closeParen = "\u{E113}"
    private static let lineBreak = "\u{E114}"
    private static let paragraphBreak = "\u{E115}"

    static let all: [CleanupRule] = [
        CleanupRule(
            name: "render context-aware Maltese spoken symbols",
            stage: .early,
            runsInTerminal: true
        ) { text, context in
            SpokenSymbols.render(text, category: context.category, vocabulary: .maltese)
        },
        CleanupRule(
            name: "prepare Maltese apostrophes and article hyphens for casing",
            stage: .early,
            transform: { text, context in prepareForSharedCasing(text, context) }
        ),
        CleanupRule(
            name: "protect filler-shaped code and terminal tokens",
            stage: .early,
            runsInTerminal: true,
            transform: { text, context in protectCodeTokens(text, context) }
        ),
        CleanupRule(
            name: "render unambiguous Maltese spoken punctuation",
            stage: .early,
            transform: { text, context in renderSpokenPunctuation(text, context) }
        ),
        CleanupRule.regex(
            name: "protect Maltese thousands commas from shared spacing",
            stage: .early,
            runsInTerminal: true,
            pattern: #"(?<=\d),(?=\d{3}(?:\D|$))"#,
            template: groupingComma
        ),
        CleanupRule.regex(
            name: "protect Maltese decimal points from identifier detection",
            stage: .early,
            runsInTerminal: true,
            pattern: #"(?<=\d)\.(?=\d)"#,
            template: decimalPoint
        ),
        CleanupRule.regex(
            name: "protect continuing Maltese abbreviation periods",
            stage: .early,
            pattern: #"(?i)\b(eż|eċċ|nru)\.(?=\s+\p{Ll})"#,
            template: "$1\(abbreviationPeriod)"
        ),
        CleanupRule(
            name: "normalize Maltese punctuation spacing after either cleanup path",
            stage: .afterPunctuation,
            transform: { text, context in normalizePunctuationSpacing(text, context) }
        ),
        CleanupRule(
            name: "normalize unambiguous Maltese prose typography",
            stage: .afterPunctuation,
            transform: { text, context in normalizeProseTypography(text, context) }
        ),
        CleanupRule(
            name: "capitalize month names in explicit Maltese dates",
            stage: .afterPunctuation,
            transform: { text, context in capitalizeDateMonths(text, context) }
        ),
        CleanupRule.regex(
            name: "restore Maltese thousands commas",
            stage: .afterPunctuation,
            runsInTerminal: true,
            pattern: groupingComma,
            template: ","
        ),
        CleanupRule(
            name: "restore protected Maltese punctuation and code tokens",
            stage: .final,
            runsInTerminal: true,
            transform: { text, context in restoreProtectedText(text, context) }
        ),
    ]

    private static let spokenPunctuation: [(String, String)] = [
        ("marka tal-esklamazzjoni", "!"),
        ("marka tal-mistoqsija", "?"),
        ("parentesi magħluqa", closeParen),
        ("parentesi miftuħa", openParen),
        ("virgoletti magħluqa", closeQuote),
        ("virgoletti miftuħa", openQuote),
        ("punt esklamattiv", "!"),
        ("punt interrogattiv", "?"),
        ("għelm il-mistoqsija", "?"),
        ("għelm il-għaġeb", "!"),
        ("paragrafu ġdid", paragraphBreak),
        ("punt u virgola", ";"),
        ("linja ġdida", lineBreak),
        ("żewġ punti", ":"),
        ("punt finali", "."),
        ("virgola", ","),
    ]

    private static let months: [String: String] = [
        "jannar": "Jannar", "jan": "Jan",
        "frar": "Frar", "fra": "Fra",
        "marzu": "Marzu", "mar": "Mar",
        "april": "April", "apr": "Apr",
        "mejju": "Mejju", "mej": "Mej",
        "ġunju": "Ġunju", "ġun": "Ġun",
        "lulju": "Lulju", "lul": "Lul",
        "awwissu": "Awwissu", "aww": "Aww",
        "settembru": "Settembru", "set": "Set",
        "ottubru": "Ottubru", "ott": "Ott",
        "novembru": "Novembru", "nov": "Nov",
        "diċembru": "Diċembru", "diċ": "Diċ",
    ]

    private static func renderSpokenPunctuation(
        _ text: String,
        _ context: CleanupContext
    ) -> String {
        var out = text
        for (name, mark) in spokenPunctuation {
            let escaped = NSRegularExpression.escapedPattern(for: name)
            out = replacing(
                out,
                pattern: "(?i)(?<![\\p{L}\\p{N}])\(escaped)(?![\\p{L}\\p{N}])",
                template: NSRegularExpression.escapedTemplate(for: mark)
            )
        }
        return out
    }

    private static func protectCodeTokens(
        _ text: String,
        _ context: CleanupContext
    ) -> String {
        guard context.category == .terminal || context.category == .codeEditor else {
            return text
        }
        let pattern = #"(?i)(?<![\p{L}\p{N}_])(ee|em|emm|qq)(?![\p{L}\p{N}_])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        var out = text
        let matches = regex.matches(in: out, range: NSRange(out.startIndex..., in: out))
        for match in matches.reversed() {
            guard let range = Range(match.range, in: out) else { continue }
            let token = String(out[range])
            let insertion = token.index(after: token.startIndex)
            out.replaceSubrange(range, with: token[..<insertion] + protectedCodeToken + token[insertion...])
        }
        return out
    }

    private static func prepareForSharedCasing(
        _ text: String,
        _ context: CleanupContext
    ) -> String {
        guard context.category == .general || context.category == .messaging else {
            return text
        }
        var out = text
        // Keep ASCII apostrophes until the shared casing pass has run: its
        // conservative "plain word" predicate understands `'` but not `’`.
        out = replacing(
            out,
            pattern: #"(?i)\b([bfmxt])\s*['ʼ’]\s*(?=\p{L})"#,
            template: "$1'"
        )
        out = replacing(
            out,
            pattern: #"(?i)\b(ta|ma|sa)\s*['ʼ’](?=\s|$|[,.!?;:])"#,
            template: "$1'"
        )
        out = replacing(
            out,
            pattern: #"(?<=\p{L})[ʼ’](?=\p{L}|$|[\s,.!?;:])"#,
            template: "'"
        )
        // Mask only a supplied Maltese article hyphen. We never invent one.
        out = replacing(
            out,
            pattern: #"(?i)\b(il|iċ|id|in|ir|is|it|ix|iż|iz|l)\s*-\s*(?=\p{L})"#,
            template: "$1\(articleHyphen)"
        )
        return out
    }

    private static func normalizePunctuationSpacing(
        _ text: String,
        _ context: CleanupContext
    ) -> String {
        var out = replacing(text, pattern: #"\s+([,.!?;:])"#, template: "$1")
        out = replacing(out, pattern: #"([,!?;])(?=\S)"#, template: "$1 ")
        return out
    }

    private static func normalizeProseTypography(
        _ text: String,
        _ context: CleanupContext
    ) -> String {
        guard context.category == .general || context.category == .messaging else {
            return text
        }
        var out = text

        // The Malta ICT locale standard uses “…” in prose. Restrict smartening
        // to a balanced pair outside code/terminal contexts; inches and code
        // quotes fail these boundaries.
        out = replacing(
            out,
            pattern: #"(^|[\s(\[])\"([^\"\n]+)\"(?=$|[\s)\].,!?;:])"#,
            template: "$1“$2”"
        )

        // Maltese currency style places € / EUR directly before the amount.
        out = replacing(out, pattern: #"€\s+(?=\d)"#, template: "€")
        out = replacing(out, pattern: #"(?i)\bEUR\s+(?=\d)"#, template: "EUR")
        out = replacing(
            out,
            pattern: #"([\-–−])\s+(?=(?:€|EUR)\d)"#,
            template: "$1"
        )
        return out
    }

    private static func capitalizeDateMonths(
        _ text: String,
        _ context: CleanupContext
    ) -> String {
        guard context.category == .general || context.category == .messaging else {
            return text
        }
        let names = months.keys
            .sorted { $0.count > $1.count }
            .map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
        let pattern = #"(?i)\b\d{1,2}\s+(?:ta['’]|t['’])\s+(?:\#(names))\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        var out = text
        let matches = regex.matches(in: out, range: NSRange(out.startIndex..., in: out))
        for match in matches.reversed() {
            guard let whole = Range(match.range, in: out) else { continue }
            let original = String(out[whole])
            guard let wordRange = original.range(
                of: #"\p{L}+$"#,
                options: [.regularExpression]
            ) else { continue }
            let key = String(original[wordRange]).lowercased()
            guard let canonical = months[key] else { continue }
            out.replaceSubrange(whole, with: original[..<wordRange.lowerBound] + canonical)
        }
        return out
    }

    private static func restoreProtectedText(
        _ text: String,
        _ context: CleanupContext
    ) -> String {
        var out = text
            .replacingOccurrences(of: abbreviationPeriod, with: ".")
            .replacingOccurrences(of: protectedCodeToken, with: "")
            .replacingOccurrences(of: decimalPoint, with: ".")
            .replacingOccurrences(of: articleHyphen, with: "-")

        if context.category == .general || context.category == .messaging {
            // The apostrophe marks omission, not stress. Smartening happens
            // after shared capitalization so x’inhu can still become X’inhu.
            out = replacing(
                out,
                pattern: #"(?<=\p{L})['ʼ](?=\p{L}|$|[\s,.!?;:])"#,
                template: "’"
            )
        }

        // Spoken structure uses sentinels so the shared whitespace pass cannot
        // flatten line breaks and cannot insert spaces inside paired marks.
        out = out
            .replacingOccurrences(of: openQuote, with: "“")
            .replacingOccurrences(of: closeQuote, with: "”")
            .replacingOccurrences(of: openParen, with: "(")
            .replacingOccurrences(of: closeParen, with: ")")
        out = replacing(out, pattern: #"\(\s+"#, template: "(")
        out = replacing(out, pattern: #"\s+\)"#, template: ")")
        out = replacing(out, pattern: #"“\s+"#, template: "“")
        out = replacing(out, pattern: #"\s+”"#, template: "”")
        let paragraphPattern = NSRegularExpression.escapedPattern(for: paragraphBreak)
        let linePattern = NSRegularExpression.escapedPattern(for: lineBreak)
        out = replacing(out, pattern: "\\s*\(paragraphPattern)\\s*", template: "\n\n")
        out = replacing(out, pattern: "\\s*\(linePattern)\\s*", template: "\n")

        // An engine may already have emitted the same mark before retaining
        // the spoken name. Explicit dictation wins without doubled output.
        out = replacing(out, pattern: #"([,;:])(?:\s*\1)+"#, template: "$1")
        out = replacing(out, pattern: #"“(?:\s*“)+"#, template: "“")
        out = replacing(out, pattern: #"(?:”\s*)+”"#, template: "”")
        out = replacing(out, pattern: #"\((?:\s*\()+"#, template: "(")
        out = replacing(out, pattern: #"(?:\)\s*)+\)"#, template: ")")
        return out
    }

    private static func replacing(
        _ text: String,
        pattern: String,
        template: String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: template
        )
    }
}
