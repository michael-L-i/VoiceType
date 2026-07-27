import Foundation

/// Bulgarian-owned deterministic rules. Private-use placeholders hide
/// language-valid punctuation from shared passes and are always restored by a
/// paired rule with the same terminal policy.
enum BulgarianCleanup {
    private static let decimalComma = "\u{E100}"
    private static let abbreviationPeriod = "\u{E101}"
    private static let underscorePhrase = "\u{E102}"
    private static let slashPhrase = "\u{E103}"
    private static let emailAtPhrase = "\u{E104}"
    private static let squareBracketNoun = "\u{E105}"

    static let spokenSymbolWords: Set<String> = [
        "точка", "запетая", "двоеточие", "многоточие",
        "въпросителен", "удивителен", "знак",
        "долна", "черта", "ъндърскор", "ъндерскор",
        "тире", "дефис", "минус", "слеш", "наклонена", "тилда",
        "отваряща", "затваряща", "отвори", "затвори",
        "лява", "дясна", "скоба", "скоби", "квадратна",
        "кльомба", "маймунско",
    ]

    static let rules: [CleanupRule] = [
        .regex(
            name: "protect Bulgarian decimal comma",
            stage: .early,
            runsInTerminal: true,
            pattern: #"(?<=\d),(?=\d)"#,
            template: decimalComma),
        CleanupRule(
            name: "protect Bulgarian abbreviation periods",
            stage: .early) { text, _ in
                protectAbbreviationPeriods(text)
            },
        CleanupRule(
            name: "render guarded Bulgarian spoken symbols",
            stage: .early,
            runsInTerminal: true) { text, context in
                renderSpokenSymbols(text, context: context)
            },
        CleanupRule(
            name: "render unambiguous Bulgarian spoken punctuation",
            stage: .early) { text, _ in
                renderSpokenPunctuation(text)
            },
        CleanupRule(
            name: "normalize Bulgarian prose quotation marks",
            stage: .afterPunctuation) { text, context in
                guard context.category != .codeEditor else { return text }
                return normalizeQuotationMarks(text)
            },
        .regex(
            name: "normalize Bulgarian elision apostrophe",
            // Run after capitalization: the shared plain-word probe accepts a
            // straight apostrophe but intentionally rejects typographic
            // punctuation inside a token.
            stage: .final,
            pattern: #"(?<=[А-Яа-яЍѝ])'(?=[А-Яа-яЍѝ])"#,
            template: "’"),
        .regex(
            name: "normalize Bulgarian digit grouping spaces",
            stage: .final,
            pattern: "(?<=\\d)[ \u{00A0}\u{202F}](?=\\d{3}(?:\\D|$))",
            template: "\u{00A0}"),
        .regex(
            name: "space Bulgarian trailing currency",
            stage: .final,
            pattern: "(\\d)[ \u{00A0}\u{202F}]*(€|EUR|BGN|лв\\.?)",
            template: "$1\u{00A0}$2",
            options: [.caseInsensitive]),
        .regex(
            name: "restore Bulgarian decimal comma",
            stage: .final,
            runsInTerminal: true,
            pattern: decimalComma,
            template: ","),
        .regex(
            name: "restore Bulgarian abbreviation periods",
            stage: .final,
            pattern: abbreviationPeriod,
            template: "."),
    ]

    private static let symbolVocabulary = SpokenSymbolVocabulary(
        dot: ["точка"],
        underscore: ["ъндърскор", "ъндерскор", underscorePhrase],
        dash: ["тире", "дефис", "минус"],
        slash: ["слеш", slashPhrase],
        tilde: ["тилда"],
        comma: ["запетая"],
        emailAt: ["кльомба", emailAtPhrase],
        openers: ["отваряща", "отвори", "лява"],
        closers: ["затваряща", "затвори", "дясна"],
        parenNouns: ["скоба", "скоби"],
        bracketNouns: [squareBracketNoun],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
            "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
            "toml", "html", "css", "xml", "sql", "csv", "log", "env",
        ],
        extensionHomophones: [
            "пай": "py",
            "пиуай": "py",
            "джейес": "js",
            "джейсон": "json",
        ],
        emailTLDs: [
            "bg", "com", "net", "org", "io", "eu", "dev", "app", "ai", "edu",
        ],
        joinGuards: LanguagePack.bulgarianStopwords,
        emailLocalGuards: LanguagePack.bulgarianStopwords.union([
            "виж", "гледай", "пиши", "отиди", "ела", "среща",
        ]))

    private static let spokenPunctuation: [(String, String)] = [
        ("точка и запетая", ";"),
        ("въпросителен знак", "?"),
        ("удивителен знак", "!"),
        ("отварящи кавички", "„"),
        ("затварящи кавички", "“"),
        // The shared spacing pass deliberately does not add a space after
        // colons because it must preserve paths and times. A spoken prose
        // colon supplies its own following space.
        ("двоеточие", ": "),
        ("многоточие", "… "),
        ("запетая", ","),
    ]

    private static func protectAbbreviationPeriods(_ text: String) -> String {
        replace(
            text,
            pattern: #"(?i)\b(г|стр|чл|ал|бр|бул|ул|пл|ч|мин|сек|напр|др|проф|доц)\.(?=\s+[а-яѝ])"#,
            template: "$1" + abbreviationPeriod)
    }

    private static func renderSpokenSymbols(_ text: String,
                                            context: CleanupContext) -> String {
        var masked = replacePhrase(text, phrase: "долна черта", with: underscorePhrase)
        masked = replacePhrase(masked, phrase: "наклонена черта", with: slashPhrase)
        masked = replacePhrase(masked, phrase: "маймунско а", with: emailAtPhrase)
        masked = replacePhrase(masked, phrase: "квадратна скоба", with: squareBracketNoun)

        var rendered = SpokenSymbols.render(
            masked,
            category: context.category,
            vocabulary: symbolVocabulary)
        rendered = rendered.replacingOccurrences(of: underscorePhrase, with: "долна черта")
        rendered = rendered.replacingOccurrences(of: slashPhrase, with: "наклонена черта")
        rendered = rendered.replacingOccurrences(of: emailAtPhrase, with: "маймунско а")
        rendered = rendered.replacingOccurrences(of: squareBracketNoun, with: "квадратна скоба")
        return rendered
    }

    private static func renderSpokenPunctuation(_ text: String) -> String {
        var out = text
        for (name, mark) in spokenPunctuation {
            let escaped = NSRegularExpression.escapedPattern(for: name)
            out = replace(
                out,
                pattern: #"[,;:!?]*\s*"# + escaped + #"\s*[,;:!?]*"#,
                template: NSRegularExpression.escapedTemplate(for: mark))
        }
        return out
    }

    private static func normalizeQuotationMarks(_ text: String) -> String {
        var out = replace(
            text,
            pattern: #"“\s*([^”\n]+?)\s*”"#,
            template: "„$1“")
        out = replace(
            out,
            pattern: #""\s*([^"\n]+?)\s*""#,
            template: "„$1“")
        return out
    }

    private static func replacePhrase(_ text: String,
                                      phrase: String,
                                      with replacement: String) -> String {
        replace(
            text,
            pattern: #"(?i)(?<![\p{L}\p{N}_])"# +
                NSRegularExpression.escapedPattern(for: phrase) +
                #"(?![\p{L}\p{N}_])"#,
            template: NSRegularExpression.escapedTemplate(for: replacement))
    }

    private static func replace(_ text: String,
                                pattern: String,
                                template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: range,
            withTemplate: template)
    }
}
