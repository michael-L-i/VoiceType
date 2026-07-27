import Foundation

/// Croatian dictation commands and contextual spoken-code rendering.
///
/// This deliberately lives in a CleanupRule instead of `LanguagePack.symbols`:
/// the repository's cross-language policy reserves that field for English, and
/// a rule also repairs literal symbol words left behind by model output.
enum CroatianDictation {
    private static let lineBreak = "\u{E002}"
    private static let paragraphBreak = "\u{E003}"

    /// Terms discounted by the model faithfulness guard when they collapse to
    /// punctuation or a compact identifier.
    static let spokenSymbolWords: Set<String> = [
        "točka", "zarez", "upitnik", "uskličnik", "dvotočka", "trotočka",
        "crtica", "spojnica", "minus", "donja", "crta", "underscore",
        "kosa", "slash", "tilda", "tilde", "afna", "at", "znak",
        "otvori", "zatvori", "obla", "oblu", "uglata", "uglatu", "zagrada",
        "zagradu", "novi", "redak", "odlomak", "navodnik", "početak", "kraj",
        "citata",
    ]

    private static let vocabulary = SpokenSymbolVocabulary(
        dot: ["točka"],
        underscore: ["donja_crta", "underscore"],
        dash: ["crtica", "spojnica", "minus", "dash"],
        slash: ["kosa_crta", "slash"],
        tilde: ["tilda", "tilde"],
        comma: ["zarez"],
        emailAt: ["afna", "znak_at", "at"],
        openers: ["otvori"],
        closers: ["zatvori"],
        parenNouns: ["obla", "oblu", "zagrada", "zagradu"],
        bracketNouns: ["uglata", "uglatu"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "json", "yaml", "yml", "toml",
            "swift", "c", "h", "cpp", "hpp", "java", "kt", "go", "rs", "rb",
            "php", "sh", "zsh", "md", "txt", "html", "css", "xml", "sql",
            "csv", "log", "env", "lock",
        ],
        extensionHomophones: [
            "pi": "py",
        ],
        emailTLDs: [
            "hr", "com", "net", "org", "io", "co", "dev", "app", "ai", "eu",
            "info", "me",
        ],
        joinGuards: LanguagePack.croatianStopwords,
        emailLocalGuards: LanguagePack.croatianStopwords.union([
            "pogledaj", "gledaj", "idi", "dođi", "ostani", "vrati", "javi",
        ]))

    /// Render only the specialized punctuation nouns that have no competing
    /// lexical sense. `točka` is conspicuously absent and reaches only the
    /// contextual file-extension renderer below.
    private static let punctuationCommands: [(name: String, mark: String)] = [
        ("navodnik za početak citata", "„"),
        ("navodnik za kraj citata", "”"),
        ("točka sa zarezom", ";"),
        ("novi odlomak", paragraphBreak),
        ("novi redak", lineBreak),
        ("dvotočka", ":"),
        ("trotočka", "…"),
        ("uskličnik", "!"),
        ("upitnik", "?"),
        ("zarez", ","),
    ]

    static func render(_ text: String, context: CleanupContext) -> String {
        var out = text

        // Sentence punctuation is prose behavior. A terminal may safely render
        // flags, paths and identifiers below, but must not gain prose marks.
        if context.category != .terminal {
            for command in punctuationCommands {
                out = replaceCommand(command.name, with: command.mark, in: out)
            }
            out = normalizeCroatianQuotes(out)
        }

        // Collapse multi-word Croatian names to private tokens understood by
        // the shared, conservative SpokenSymbols neighbor rules.
        let phrases: [(String, String)] = [
            ("donja crta", "donja_crta"),
            ("kosa crta", "kosa_crta"),
            ("znak at", "znak_at"),
            ("otvori oblu zagradu", "otvori obla"),
            ("zatvori oblu zagradu", "zatvori obla"),
            ("otvori uglatu zagradu", "otvori uglata"),
            ("zatvori uglatu zagradu", "zatvori uglata"),
            ("točka džej es", "točka js"),
            ("točka ti es", "točka ts"),
        ]
        for (phrase, token) in phrases {
            out = replacePhrase(phrase, with: token, in: out)
        }
        return SpokenSymbols.render(out, category: context.category,
                                    vocabulary: vocabulary)
    }

    static func restoreBreaks(_ text: String) -> String {
        var out = replace(text,
                          pattern: "\\s*\(NSRegularExpression.escapedPattern(for: paragraphBreak))\\s*",
                          template: "\n\n")
        out = replace(out,
                      pattern: "\\s*\(NSRegularExpression.escapedPattern(for: lineBreak))\\s*",
                      template: "\n")
        return out
    }

    private static func replaceCommand(_ name: String, with mark: String,
                                       in text: String) -> String {
        let escapedName = NSRegularExpression.escapedPattern(for: name)
        let escapedMark = NSRegularExpression.escapedPattern(for: mark)
        // Absorb the same mark if the speech engine already emitted it next
        // to the literal command word: "Dobro? upitnik" remains one question.
        let pattern = "(?:\(escapedMark)\\s*)?(?<![\\p{L}\\p{N}_])\(escapedName)(?![\\p{L}\\p{N}_])(?:\\s*\(escapedMark))?"
        return replace(text, pattern: pattern,
                       template: NSRegularExpression.escapedTemplate(for: mark),
                       options: [.caseInsensitive])
    }

    private static func replacePhrase(_ phrase: String, with token: String,
                                      in text: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: phrase)
        return replace(text,
                       pattern: "(?<![\\p{L}\\p{N}_])\(escaped)(?![\\p{L}\\p{N}_])",
                       template: NSRegularExpression.escapedTemplate(for: token),
                       options: [.caseInsensitive])
    }

    private static func normalizeCroatianQuotes(_ text: String) -> String {
        var out = text.replacingOccurrences(of: "“", with: "„")
        // Quotes attach to the text inside them and are separated from
        // surrounding prose. The shared punctuation pass then tidies any comma
        // or period following the closing quote.
        out = replace(out, pattern: "\\s*„\\s*", template: " „")
        out = replace(out, pattern: "\\s*”\\s*", template: "” ")
        return out.trimmingCharacters(in: .whitespaces)
    }

    private static func replace(_ text: String, pattern: String,
                                template: String,
                                options: NSRegularExpression.Options = []) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text, range: NSRange(text.startIndex..., in: text),
            withTemplate: template)
    }
}

enum CroatianRules {
    private static let decimalComma = "\u{E000}"
    private static let abbreviationPeriod = "\u{E001}"
    private static let datePeriod = "\u{E004}"

    static let all: [CleanupRule] = [
        CleanupRule(
            name: "Croatian dictation commands and contextual symbols",
            stage: .early,
            runsInTerminal: true
        ) { text, context in
            CroatianDictation.render(text, context: context)
        },
        .regex(
            name: "protect Croatian decimal commas",
            stage: .early,
            runsInTerminal: true,
            pattern: "(?<=\\d),(?=\\d)",
            template: decimalComma
        ),
        CleanupRule(
            name: "protect Croatian abbreviation periods",
            stage: .early
        ) { text, _ in
            maskAbbreviationPeriods(text)
        },
        CleanupRule(
            name: "protect Croatian numeric date periods",
            stage: .early
        ) { text, context in
            guard context.category == .general || context.category == .messaging else {
                return text
            }
            return maskDatePeriods(text)
        },
        .regex(
            name: "restore Croatian decimal commas",
            stage: .afterPunctuation,
            runsInTerminal: true,
            pattern: NSRegularExpression.escapedPattern(for: decimalComma),
            template: ","
        ),
        .regex(
            name: "restore Croatian numeric date periods",
            stage: .final,
            pattern: NSRegularExpression.escapedPattern(for: datePeriod) + "\\.?",
            template: "."
        ),
        CleanupRule(
            name: "Croatian numeric date and unit spacing",
            stage: .afterPunctuation
        ) { text, context in
            guard context.category == .general || context.category == .messaging else {
                return text
            }
            return normalizeNumbers(text)
        },
        .regex(
            name: "restore Croatian abbreviation periods",
            stage: .final,
            pattern: NSRegularExpression.escapedPattern(for: abbreviationPeriod),
            template: "."
        ),
        CleanupRule(
            name: "Croatian direct questions with li",
            stage: .final
        ) { text, _ in
            repairLiQuestions(text)
        },
        CleanupRule(
            name: "restore Croatian dictated line breaks",
            stage: .final
        ) { text, _ in
            CroatianDictation.restoreBreaks(text)
        },
    ]

    private static func maskAbbreviationPeriods(_ text: String) -> String {
        var out = text
        let escaped = NSRegularExpression.escapedTemplate(for: abbreviationPeriod)
        // Connective abbreviations normally continue the same sentence.
        out = replace(out,
                      pattern: #"(?i)\b(npr|tj|tzv|odn|usp)\.(?=\s+\p{Ll})"#,
                      template: "$1\(escaped)")
        // Titles before a name and labels before a number cannot terminate the
        // sentence at this point.
        out = replace(out,
                      pattern: #"(?i)\b(dr|mr|prof|doc|akad|gosp|vlč|ing|dipl|mag)\.(?=\s+\p{Lu})"#,
                      template: "$1\(escaped)")
        out = replace(out,
                      pattern: #"(?i)\b(br|str|čl|god|st)\.(?=\s+\d)"#,
                      template: "$1\(escaped)")
        return out
    }

    private static func normalizeNumbers(_ text: String) -> String {
        var out = text
        // Croatian typography separates percent/promille and the euro sign
        // from the number. Code-editor and terminal contexts sit this out.
        out = replace(out, pattern: #"(?<=\d)\s*([%‰€])"#, template: " $1")
        return out
    }

    private static func maskDatePeriods(_ text: String) -> String {
        let escaped = NSRegularExpression.escapedTemplate(for: datePeriod)
        // Normalize at masking time so none of the three ordinal dots can
        // trigger the shared sentence-capitalization pass. Tight boundaries
        // exclude versions, IPs, paths and hyphenated release identifiers.
        return replace(
            text,
            pattern: #"(?<![\w.-])(0?[1-9]|[12]\d|3[01])\.\s*(0?[1-9]|1[0-2])\.\s*((?:19|20)\d{2})\.?(?![\w.-])"#,
            template: "$1\(escaped) $2\(escaped) $3\(escaped)")
    }

    private static func repairLiQuestions(_ text: String) -> String {
        // The shared first-token heuristic cannot express Croatian's two-word
        // auxiliary + li frame. Convert only a final period, only when no comma
        // or other clause punctuation makes an indirect/dependent reading
        // plausible. This also repairs later already-delimited sentences.
        let auxiliaries = [
            "je", "jesam", "jesi", "jesmo", "jeste", "jesu",
            "hoću", "hoćeš", "hoće", "hoćemo", "hoćete",
            "mogu", "možeš", "može", "možemo", "možete",
            "moram", "moraš", "mora", "moramo", "morate", "moraju",
            "trebam", "trebaš", "treba", "trebamo", "trebate", "trebaju",
        ].joined(separator: "|")
        let pattern = "(?i)(^|(?<=[.!?])\\s+)((?:\(auxiliaries))\\s+li\\b[^.!?,;:]*?)\\."
        return replace(text, pattern: pattern, template: "$1$2?")
    }

    private static func replace(_ text: String, pattern: String,
                                template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text, range: NSRange(text.startIndex..., in: text),
            withTemplate: template)
    }
}
