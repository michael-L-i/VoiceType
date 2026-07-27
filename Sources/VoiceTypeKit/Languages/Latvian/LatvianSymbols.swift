import Foundation

extension SpokenSymbolVocabulary {
    /// Latvian spoken tech symbols. This vocabulary is intentionally invoked
    /// from a Latvian-owned `CleanupRule`, not `LanguagePack.symbols`: the
    /// language-integrity contract reserves that pack field for English, while
    /// a rule also repairs model output and can opt into terminal handling.
    ///
    /// `punkts` is safe here despite being an ordinary noun because the shared
    /// renderer consumes it only before a known extension (or in a terminal
    /// `./` prefix). `et` is the terminology commission's accepted spoken form
    /// of @; `eta` is deliberately absent because it names Greek η.
    static let latvian = SpokenSymbolVocabulary(
        dot: ["punkts"],
        underscore: ["pasvītra"],
        dash: ["defise"],
        slash: ["slīpsvītra"],
        tilde: ["tilde"],
        comma: ["komats"],
        emailAt: ["et"],
        openers: ["atverošā"],
        closers: ["aizverošā"],
        parenNouns: ["iekava"],
        bracketNouns: ["kvadrātiekava"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h",
            "cpp", "hpp", "java", "rb", "php", "sh", "md", "txt", "json",
            "yaml", "yml", "toml", "html", "css", "xml", "sql", "csv", "log",
            "lock", "env",
        ],
        extensionHomophones: [:],
        emailTLDs: [
            "lv", "com", "net", "org", "io", "eu", "dev", "app", "ai", "edu",
            "gov", "me",
        ],
        joinGuards: LanguagePack.latvianStopwords,
        emailLocalGuards: LanguagePack.latvianStopwords.union([
            "skaties", "skatīties", "raksti", "rakstīt", "sūti", "sūtīt",
            "ej", "iet", "būt",
        ]))
}
