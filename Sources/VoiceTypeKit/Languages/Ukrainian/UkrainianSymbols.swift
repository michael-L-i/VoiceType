import Foundation

/// A Ukrainian-owned entry into the shared conservative symbol renderer.
///
/// `LanguagePack.ukrainian.symbols` deliberately remains nil because the
/// repository's shared integrity contract reserves that pack field for
/// English. Calling this vocabulary from a language-owned `CleanupRule` also
/// repairs model output, which the pack field cannot do.
enum UkrainianSpokenSymbols {
    static let words: Set<String> = [
        "крапка", "підкреслення", "андерскор", "мінус", "дефіс", "слеш",
        "тильда", "кома", "ет", "равлик", "відкрита", "закрита", "дужка",
        "джей", "ес", "ті", "ем", "ве", "ель", "аш",
    ]

    static let vocabulary = SpokenSymbolVocabulary(
        dot: ["крапка"],
        underscore: ["підкреслення", "андерскор"],
        dash: ["мінус", "дефіс"],
        slash: ["слеш"],
        tilde: ["тильда"],
        comma: ["кома"],
        emailAt: ["ет", "равлик"],
        openers: ["відкрита"],
        closers: ["закрита"],
        parenNouns: ["дужка"],
        bracketNouns: [],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h",
            "cpp", "hpp", "java", "rb", "php", "sh", "md", "txt", "json",
            "yaml", "yml", "toml", "html", "css", "xml", "sql", "csv", "log",
            "lock", "env",
        ],
        extensionHomophones: [
            "пі": "py",
            "пайтон": "py",
            "свіфт": "swift",
            "джейсон": "json",
            "маркдаун": "md",
        ],
        emailTLDs: [
            "ua", "com", "net", "org", "io", "co", "dev", "app", "ai", "me",
        ],
        joinGuards: LanguagePack.ukrainianStopwords,
        emailLocalGuards: LanguagePack.ukrainianStopwords.union([
            "пиши", "напиши", "подивись", "глянь", "зайди", "перейди",
        ]))

    static let rule = CleanupRule(
        name: "render structurally explicit Ukrainian spoken symbols",
        stage: .early,
        runsInTerminal: true
    ) { text, context in
        var normalized = text
        // Ukrainian ASR commonly spells English extensions as separate letter
        // names. The preceding крапка anchors these rewrites to a file suffix.
        let extensions = [
            " крапка джей ес": " крапка js",
            " крапка ті ес": " крапка ts",
        ]
        for (spoken, rendered) in extensions {
            normalized = normalized.replacingOccurrences(
                of: spoken,
                with: rendered,
                options: [.caseInsensitive])
        }

        // Short shell flags are normally spoken by the Ukrainian name of the
        // Latin letter. Restrict the conversion to terminal context and an
        // explicit мінус marker.
        if context.category == .terminal {
            let flagLetters = [
                "мінус ем": "мінус m",
                "мінус ве": "мінус v",
                "мінус ель": "мінус l",
                "мінус аш": "мінус h",
            ]
            for (spoken, rendered) in flagLetters {
                normalized = normalized.replacingOccurrences(
                    of: spoken,
                    with: rendered,
                    options: [.caseInsensitive])
            }
        }

        return SpokenSymbols.render(
            normalized,
            category: context.category,
            vocabulary: vocabulary)
    }
}
