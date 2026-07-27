import Foundation

enum ArabicSpokenPunctuation {
    static let mapping: [String: String] = [
        "علامة استفهام": "؟",
        "علامة تعجب": "!",
        "فاصلة منقوطة": "؛",
        "نقطتان رأسيتان": ":",
        "علامة شرطة": "-",
        "علامة ناقص": "-",
        "شرطة فصل": "–",
        "قوس مفتوح": "(",
        "قوس مقفول": ")",
        "قوس يمين": "(",
        "قوس شمال": ")",
        "بدء التنصيص": "\"",
        "نهاية التنصيص": "\"",
        "علامة تنصيص مفتوحة": "\"",
        "علامة تنصيص مقفولة": "\"",
        "علامة المربع": "#",
        "علامة رقم": "#",
        "علامة النجمة": "*",
        "إشارة آت": "@",
        "علامة آت": "@",
        "نسبة مئوية": "%",
        "علامة زائد": "+",
        "علامة يساوي": "=",
    ]

    /// `CleanupPolish` invokes a pack's rules but, for non-CJK languages, does
    /// not invoke the declarative spoken-punctuation table. Reuse the shared
    /// renderer here so explicit Arabic commands are repaired after either
    /// cleanup engine.
    static let rule = CleanupRule(
        name: "render explicit Arabic punctuation commands",
        stage: .early
    ) { text, _ in
        var out = text
        // The shared renderer absorbs an adjacent already-rendered mark. Arabic
        // ASR also commonly leaves a space before the spoken command, so
        // normalize that idempotent form first.
        for (name, mark) in mapping {
            let pattern = NSRegularExpression.escapedPattern(for: mark)
                + #"\s+"#
                + NSRegularExpression.escapedPattern(for: name)
            out = out.replacingMatches(pattern: pattern, with: mark)
        }
        return RuleBasedCleanup.renderSpokenPunctuation(out, pack: .arabic)
    }
}

/// Arabic spoken-symbol rendering and mechanical orthography. These are rules
/// rather than `LanguagePack.symbols` so the same repairs also run over model
/// output and the pack remains compatible with the non-English symbol policy.
enum ArabicSpokenSymbols {
    /// Words that legitimately disappear into a rendered symbol. The model
    /// faithfulness guard discounts them rather than mistaking `main دوت py`
    /// → `main.py` for content loss.
    static let spokenWords: Set<String> = [
        "دوت", "نقطة", "أندرسكور", "اندرسكور", "داش", "سلاش", "تيلدا",
        "فاصلة", "آت", "ات", "افتح", "أغلق", "اغلق", "قوس",
        "علامة", "شرطة", "سفلية", "مائلة",
    ]

    static let rule = CleanupRule(
        name: "render guarded Arabic spoken symbols",
        stage: .early,
        runsInTerminal: true
    ) { text, context in
        let prepared = prepareTechnicalPhrases(text)
        return SpokenSymbols.render(
            prepared,
            category: context.category,
            vocabulary: vocabulary)
    }

    private static let vocabulary = SpokenSymbolVocabulary(
        // نقطة is safe here (unlike flat spoken punctuation) because the shared
        // renderer requires a known extension on its right and an identifier
        // part on its left.
        dot: ["دوت", "نقطة"],
        underscore: ["أندرسكور", "اندرسكور"],
        dash: ["داش"],
        slash: ["سلاش"],
        tilde: ["تيلدا"],
        comma: ["فاصلة"],
        // The email renderer additionally requires Latin local/domain parts
        // and a known TLD, protecting the lexical reading of آت.
        emailAt: ["آت", "ات"],
        openers: ["افتح"],
        closers: ["أغلق", "اغلق"],
        parenNouns: ["قوس"],
        bracketNouns: [],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
            "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml", "toml",
            "html", "css", "xml", "sql", "csv", "log", "env",
        ],
        extensionHomophones: [
            "باي": "py",
        ],
        emailTLDs: [
            "com", "net", "org", "io", "co", "dev", "app", "ai", "edu", "gov",
            "me", "sa", "ae", "eg",
        ],
        joinGuards: LanguagePack.arabicStopwords,
        emailLocalGuards: LanguagePack.arabicStopwords)

    /// Turn explicit multi-word Arabic technical names into the single-token
    /// triggers understood by `SpokenSymbols`. Replacements stay narrow and
    /// evidence-bearing: bare شرطة is never treated as a dash.
    private static func prepareTechnicalPhrases(_ text: String) -> String {
        var out = text
        let phrases: [(String, String)] = [
            ("شرطة سفلية", "أندرسكور"),
            ("علامة شرطة", "داش"),
            ("شرطة مائلة", "سلاش"),
            ("علامة آت", "آت"),
            ("إشارة آت", "آت"),
            ("قوس مفتوح", "افتح قوس"),
            ("قوس مقفول", "أغلق قوس"),
            ("قوس يمين", "افتح قوس"),
            ("قوس شمال", "أغلق قوس"),
            ("دوت بي واي", "دوت py"),
            ("نقطة بي واي", "نقطة py"),
            ("دوت جي إس", "دوت js"),
            ("نقطة جي إس", "نقطة js"),
            ("دوت تي إس", "دوت ts"),
            ("نقطة تي إس", "نقطة ts"),
            ("دوت سي إس إس", "دوت css"),
            ("نقطة سي إس إس", "نقطة css"),
        ]
        for (spoken, token) in phrases {
            out = replaceWholePhrase(spoken, with: token, in: out)
        }
        return out
    }

    private static func replaceWholePhrase(_ phrase: String,
                                           with replacement: String,
                                           in text: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: phrase)
        guard let regex = try? NSRegularExpression(
            pattern: #"(?<![\p{L}\p{N}_])"# + escaped + #"(?![\p{L}\p{N}_])"#
        ) else { return text }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: NSRegularExpression.escapedTemplate(for: replacement))
    }
}

enum ArabicCleanupRules {
    /// Private-use sentinels are paired at identical terminal scope and never
    /// escape the final stage. They protect exact user data from shared passes:
    /// numeric commas from space insertion, and Latin token case from the
    /// sentence-capitalization pass that Arabic itself does not need.
    private static let europeanNumericComma = "\u{F0000}"
    private static let arabicNumericComma = "\u{F0001}"
    private static let latinCaseGuard = "\u{F0002}"
    private static let spokenLineBreak = "\u{F0003}"
    private static let latinInternalQuestion = "\u{F0004}"

    static let all: [CleanupRule] = [
        protectNumericCommas,
        protectLatinInternalPunctuation,
        protectSpokenLineBreaks,
        ArabicSpokenPunctuation.rule,
        ArabicSpokenSymbols.rule,
        protectLatinTokenCase,
        normalizeArabicPunctuationShapes,
        normalizeArabicPunctuationSpacing,
        restoreNumericCommas,
        restoreLatinInternalPunctuation,
        restoreSpokenLineBreaks,
        restoreLatinTokenCase,
    ]

    private static let protectNumericCommas = CleanupRule(
        name: "protect Arabic numeric separators",
        stage: .early,
        runsInTerminal: true
    ) { text, _ in
        text
            .replacingMatches(
                pattern: #"(?<=\p{N}),(?=\p{N})"#,
                with: europeanNumericComma)
            .replacingMatches(
                pattern: #"(?<=\p{N})،(?=\p{N})"#,
                with: arabicNumericComma)
    }

    private static let restoreNumericCommas = CleanupRule(
        name: "restore Arabic numeric separators",
        stage: .final,
        runsInTerminal: true
    ) { text, _ in
        text
            .replacingOccurrences(of: europeanNumericComma, with: ",")
            .replacingOccurrences(of: arabicNumericComma, with: "،")
    }

    private static let protectLatinInternalPunctuation = CleanupRule(
        name: "protect punctuation inside Latin tokens",
        stage: .early,
        runsInTerminal: true
    ) { text, _ in
        text.replacingMatches(
            pattern: #"(?<=[A-Za-z0-9])\?(?=[A-Za-z0-9])"#,
            with: latinInternalQuestion)
    }

    private static let restoreLatinInternalPunctuation = CleanupRule(
        name: "restore punctuation inside Latin tokens",
        stage: .final,
        runsInTerminal: true
    ) { text, _ in
        text.replacingOccurrences(of: latinInternalQuestion, with: "?")
    }

    /// The shared whitespace collapse would otherwise erase a dictated line
    /// break. Mask Microsoft Word's documented Arabic commands until `.final`.
    private static let protectSpokenLineBreaks = CleanupRule(
        name: "protect Arabic spoken line breaks",
        stage: .early
    ) { text, _ in
        text.replacingMatches(
            pattern: #"\s*(?:أول السطر|أول الخط)\s*"#,
            with: spokenLineBreak)
    }

    private static let restoreSpokenLineBreaks = CleanupRule(
        name: "restore Arabic spoken line breaks",
        stage: .final
    ) { text, _ in
        text.replacingOccurrences(of: spokenLineBreak, with: "\n")
    }

    private static let protectLatinTokenCase = CleanupRule(
        name: "protect Latin token case in Arabic",
        stage: .early
    ) { text, _ in
        text.replacingMatches(
            pattern: #"(?<!\S)(?=[a-z])"#,
            with: latinCaseGuard)
    }

    private static let restoreLatinTokenCase = CleanupRule(
        name: "restore Latin token case in Arabic",
        stage: .final
    ) { text, _ in
        text.replacingOccurrences(of: latinCaseGuard, with: "")
    }

    /// Convert ASCII lookalikes only where Arabic-script context establishes
    /// that they punctuate Arabic prose. ASCII punctuation inside an embedded
    /// identifier or expression remains byte-for-byte unchanged.
    private static let normalizeArabicPunctuationShapes = CleanupRule(
        name: "normalize Arabic punctuation shapes",
        stage: .afterPunctuation
    ) { text, _ in
        var out = text
        out = out.replacingMatches(
            pattern: #"(?<=\p{Arabic}),|,(?=\s*\p{Arabic})"#,
            with: "،")
        out = out.replacingMatches(
            pattern: #"(?<=\p{Arabic});|;(?=\s*\p{Arabic})"#,
            with: "؛")
        out = out.replacingMatches(
            pattern: #"(?<=\p{Arabic})\?"#,
            with: "؟")
        if out.last == "?", out.range(of: #"\p{Arabic}"#, options: .regularExpression) != nil {
            out.removeLast()
            out.append("؟")
        }
        return out
    }

    /// King Salman Global Academy's rule: punctuation touches the preceding
    /// word and is followed by a space. Arabic-only marks can be normalized
    /// directly; shared-shape marks are changed only next to Arabic letters so
    /// `main.py`, `12:30`, and code keep their syntax.
    private static let normalizeArabicPunctuationSpacing = CleanupRule(
        name: "normalize Arabic punctuation spacing",
        stage: .afterPunctuation
    ) { text, _ in
        var out = text
        out = out.replacingMatches(
            pattern: #"\A[،؛]\s*"#,
            with: "")
        out = out.replacingMatches(
            pattern: #"([،؛])\s*[،؛]"#,
            with: "$1")
        out = out.replacingMatches(
            pattern: #"\s+([،؛؟])"#,
            with: "$1")
        out = out.replacingMatches(
            pattern: #"([،؛؟])(?=[^\s\p{P}])"#,
            with: "$1 ")
        out = out.replacingMatches(
            pattern: #"(?<=\p{Arabic})\s+([.!:])"#,
            with: "$1")
        out = out.replacingMatches(
            pattern: #"([.!:])(?=\p{Arabic})"#,
            with: "$1 ")
        return out
    }
}

private extension String {
    func replacingMatches(pattern: String, with replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return self }
        return regex.stringByReplacingMatches(
            in: self,
            range: NSRange(startIndex..., in: self),
            withTemplate: replacement)
    }
}
