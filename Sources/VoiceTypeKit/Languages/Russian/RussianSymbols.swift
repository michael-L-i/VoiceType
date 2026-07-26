import Foundation

/// Russian spoken-code vocabulary is invoked from a Russian-owned cleanup rule
/// rather than `LanguagePack.symbols`: a shared integrity test intentionally
/// reserves that field for English. The rule is also better for this pack
/// because it repairs literal symbol words that survive model cleanup.
enum RussianSpokenSymbols {
    static let spokenWords: Set<String> = [
        "точка", "подчёркивание", "подчеркивание", "нижнее", "дефис", "минус",
        "слэш", "слеш", "тильда", "запятая", "собака", "открывающая",
        "открыть", "закрывающая", "закрыть", "скобка", "круглая",
        "квадратная",
    ]

    private static let vocabulary = SpokenSymbolVocabulary(
        dot: ["точка"],
        underscore: ["подчёркивание", "подчеркивание"],
        dash: ["дефис", "минус"],
        slash: ["слэш", "слеш"],
        tilde: ["тильда"],
        comma: ["запятая"],
        emailAt: ["собака"],
        openers: ["открывающая", "открыть"],
        closers: ["закрывающая", "закрыть"],
        parenNouns: ["скобка", "круглая"],
        bracketNouns: ["квадратная"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h",
            "cpp", "hpp", "java", "rb", "php", "sh", "md", "txt", "json",
            "yaml", "yml", "toml", "html", "css", "xml", "sql", "csv", "log",
            "lock", "env",
        ],
        extensionHomophones: [
            "пай": "py",
            "пи": "py",
            "джейэс": "js",
            "джээс": "js",
            "джей-эс": "js",
            "тиэс": "ts",
            "ти-эс": "ts",
            "джейсон": "json",
            "ява": "java",
            "свифт": "swift",
            "гоу": "go",
        ],
        emailTLDs: [
            "com", "net", "org", "io", "co", "dev", "app", "ai", "edu", "gov",
            "me", "ru", "рф",
        ],
        joinGuards: LanguagePack.russianStopwords,
        emailLocalGuards: LanguagePack.russianStopwords.union([
            "смотреть", "посмотреть", "идти", "зайти", "прийти", "встретить",
            "встреча", "вернуться", "начать",
        ]))

    static func render(_ input: String, category: AppCategory) -> String {
        let prepared = normalizeCompoundNames(input)
        return SpokenSymbols.render(
            prepared,
            category: category,
            vocabulary: vocabulary)
    }

    /// `SpokenSymbols` consumes one token per trigger. Russian speakers often
    /// say compound names, so collapse only the established compounds; the
    /// following renderer still requires identifier neighbors or a paired
    /// bracket command before it emits anything.
    private static func normalizeCompoundNames(_ input: String) -> String {
        var tokens = input.split(separator: " ").map(String.init)
        var index = 1
        while index + 2 < tokens.count {
            let adjective = tokens[index].lowercased()
            let noun = tokens[index + 1].lowercased()
            let left = tokens[index - 1].lowercased()
            let right = tokens[index + 2].lowercased()
            if adjective == "нижнее",
               noun == "подчёркивание" || noun == "подчеркивание",
               isIdentifierPart(left),
               isIdentifierPart(right),
               !LanguagePack.russianStopwords.contains(left),
               !LanguagePack.russianStopwords.contains(right) {
                tokens.remove(at: index)
                continue
            }
            index += 1
        }

        var text = tokens.joined(separator: " ")
        text = replace(
            text,
            pattern: #"(?i)\b(открывающая|открыть|закрывающая|закрыть)\s+круглая\s+скобка\b"#,
            template: "$1 скобка")
        text = replace(
            text,
            pattern: #"(?i)\b(открывающая|открыть|закрывающая|закрыть)\s+квадратная\s+скобка\b"#,
            template: "$1 квадратная")
        return text
    }

    private static func isIdentifierPart(_ token: String) -> Bool {
        !token.isEmpty
            && token.allSatisfy { $0.isLetter || $0.isNumber || "._-".contains($0) }
    }

    private static func replace(_ input: String,
                                pattern: String,
                                template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return input
        }
        return regex.stringByReplacingMatches(
            in: input,
            range: NSRange(input.startIndex..., in: input),
            withTemplate: template)
    }
}

enum RussianSpokenPunctuation {
    private static let replacements: [(spoken: String, mark: String)] = [
        ("открывающая квадратная скобка", "["),
        ("закрывающая квадратная скобка", "]"),
        ("открывающая круглая скобка", "("),
        ("закрывающая круглая скобка", ")"),
        ("восклицательный знак", "!"),
        ("вопросительный знак", "?"),
        ("открывающая кавычка", "«"),
        ("закрывающая кавычка", "»"),
        ("точка с запятой", ";"),
        ("с новой строчки", "\n"),
        ("с новой строки", "\n"),
        ("конец предложения", "."),
        ("новый абзац", "\n\n"),
        ("новая строка", "\n"),
        ("знак вопроса", "?"),
        ("многоточие", "…"),
        ("двоеточие", ":"),
        ("запятая", ","),
        ("тире", "—"),
        ("дефис", "-"),
    ]

    static func render(_ input: String) -> String {
        var text = input
        for item in replacements.sorted(by: { $0.spoken.count > $1.spoken.count }) {
            let escaped = NSRegularExpression.escapedPattern(for: item.spoken)
            text = replace(
                text,
                pattern: #"(?i)(?<![\p{L}\p{N}_])\#(escaped)(?![\p{L}\p{N}_])"#,
                template: item.mark)
        }

        // Attach punctuation without flattening the real newlines commands
        // just inserted. Duplicates cover transcribers that rendered a mark and
        // also left the spoken command as words.
        text = replace(text, pattern: #"[ \t]+([,.!?;:…\]\)])"#, template: "$1")
        text = replace(text, pattern: #"([\[\(«])[ \t]+"#, template: "$1")
        text = replace(text, pattern: #"[ \t]+»"#, template: "»")
        text = replace(text, pattern: #"[ \t]*\n[ \t]*"#, template: "\n")
        text = replace(
            text,
            pattern: #"([,;:])(?:[ \t]*\1)+"#,
            template: "$1")
        text = replace(
            text,
            pattern: #"([.!?…])(?:[ \t]*\1)+"#,
            template: "$1")
        text = replace(
            text,
            pattern: #"([,!?;])(?=[^\s\]\)»])"#,
            template: "$1 ")
        return text
    }

    private static func replace(_ input: String,
                                pattern: String,
                                template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return input
        }
        return regex.stringByReplacingMatches(
            in: input,
            range: NSRange(input.startIndex..., in: input),
            withTemplate: template)
    }
}
