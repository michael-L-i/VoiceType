import Foundation

/// Romanian spoken-code vocabulary is deliberately applied from a pack-owned
/// rule instead of `LanguagePack.symbols`: repository policy reserves that
/// field for English. The rule reaches both raw transcripts and model output,
/// while the shared renderer still supplies its conservative neighbor checks.
enum RomanianSymbols {
    static let spokenWords: Set<String> = [
        "punct", "virgulă", "minus", "cratimă", "underscore", "slash",
        "bară", "oblică", "inversă", "tildă", "arond",
        "deschide", "închide", "paranteză", "acoladă", "croșetă",
        "egal", "plus", "procent", "diez", "hash", "apostrof",
        "semnul", "întrebării", "exclamării", "puncte", "suspensie",
    ]

    private static let vocabulary = SpokenSymbolVocabulary(
        // Each trigger is constrained by SpokenSymbols: punct joins only a
        // known extension/domain or a terminal "./" path; it never rewrites
        // ordinary Romanian "un punct important".
        dot: ["punct"],
        underscore: ["underscore"],
        dash: ["minus", "cratimă"],
        slash: ["slash"],
        tilde: ["tildă"],
        comma: ["virgulă"],
        emailAt: ["arond"],
        openers: ["deschide"],
        closers: ["închide"],
        parenNouns: ["paranteză"],
        // Multi-word "paranteză pătrată" cannot be represented safely by the
        // shared token renderer; the prompt owns it instead.
        bracketNouns: [],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h",
            "cpp", "hpp", "java", "rb", "php", "sh", "md", "txt", "json",
            "yaml", "yml", "toml", "html", "css", "xml", "sql", "csv",
            "log", "lock", "env",
        ],
        extensionHomophones: [
            // Likely Romanian recognizer spellings of English extension names.
            "pai": "py",
            "geison": "json",
        ],
        emailTLDs: [
            "ro", "com", "net", "org", "io", "co", "dev", "app", "ai",
            "edu", "gov", "eu", "md",
        ],
        joinGuards: LanguagePack.romanianStopwords,
        emailLocalGuards: LanguagePack.romanianStopwords.union([
            "uită", "uite", "merg", "merge", "ajung", "ajunge",
            "scriu", "scrie", "trimite", "trimitem", "rămân", "rămâne",
        ]))

    static let renderingRule = CleanupRule(
        name: "render constrained Romanian spoken symbols",
        stage: .early,
        runsInTerminal: true
    ) { text, context in
        SpokenSymbols.render(text, category: context.category,
                             vocabulary: vocabulary)
    }
}
