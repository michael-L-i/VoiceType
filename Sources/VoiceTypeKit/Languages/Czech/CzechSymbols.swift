import Foundation

extension SpokenSymbolVocabulary {
    /// Conservative Czech vocabulary for ordinary dictation. Only joins whose
    /// neighbors strongly signal an identifier are enabled: a known extension
    /// after `tečka`, `podtržítko` between identifier parts, and an address
    /// anchored by `zavináč` plus a known TLD.
    static let czechProse = SpokenSymbolVocabulary(
        dot: ["tečka"],
        underscore: ["podtržítko"],
        dash: [],
        slash: [],
        tilde: [],
        comma: [],
        emailAt: ["zavináč"],
        openers: [],
        closers: [],
        parenNouns: [],
        bracketNouns: [],
        fileExtensions: CzechSymbols.fileExtensions,
        extensionHomophones: CzechSymbols.extensionHomophones,
        emailTLDs: CzechSymbols.emailTLDs,
        joinGuards: LanguagePack.czechStopwords,
        emailLocalGuards: LanguagePack.czechStopwords.union([
            "napiš", "pošli", "poslat", "mail", "email", "kontakt",
            "kontaktuj", "adresa", "adrese", "najdi", "hledej",
        ]))

    /// Wider vocabulary for a code editor or terminal, where punctuation nouns
    /// overwhelmingly mean syntax. This also enables shell flags and paths.
    static let czechTechnical = SpokenSymbolVocabulary(
        dot: ["tečka"],
        underscore: ["podtržítko"],
        dash: ["pomlčka", "spojovník", "mínus"],
        slash: ["lomítko"],
        tilde: ["tilda"],
        comma: ["čárka"],
        emailAt: ["zavináč"],
        openers: ["otevřená", "levá", "otevři"],
        closers: ["uzavřená", "pravá", "zavři"],
        parenNouns: ["závorka", "závorku"],
        bracketNouns: [],
        fileExtensions: CzechSymbols.fileExtensions,
        extensionHomophones: CzechSymbols.extensionHomophones,
        emailTLDs: CzechSymbols.emailTLDs,
        joinGuards: LanguagePack.czechStopwords,
        emailLocalGuards: LanguagePack.czechStopwords)
}

enum CzechSymbols {
    static let fileExtensions: Set<String> = [
        "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
        "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
        "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
        "pdf", "docx", "xlsx",
    ]

    /// Common one-token Czech ASR renderings of a spoken extension. Multi-token
    /// spellings such as "pé ypsilon" remain model territory because the shared
    /// renderer only joins literal one-letter tokens or a single homophone.
    static let extensionHomophones: [String: String] = [
        "pí": "py",
        "pý": "py",
        "džej-es": "js",
        "té-es": "ts",
    ]

    static let emailTLDs: Set<String> = [
        "cz", "sk", "eu", "com", "net", "org", "io", "co", "dev", "app",
        "ai", "edu", "gov", "me",
    ]

    static func render(_ text: String, context: CleanupContext) -> String {
        let vocabulary: SpokenSymbolVocabulary =
            context.category == .terminal || context.category == .codeEditor
            ? .czechTechnical
            : .czechProse
        return SpokenSymbols.render(text, category: context.category,
                                    vocabulary: vocabulary)
    }
}
