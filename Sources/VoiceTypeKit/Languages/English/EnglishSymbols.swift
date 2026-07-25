import Foundation

extension SpokenSymbolVocabulary {
    /// English spoken symbols — the reference vocabulary, moved here verbatim
    /// from `SpokenSymbols`' hardcoded literals. Every value is what shipped
    /// before packs owned this data; nothing here is new.
    ///
    /// A language adding its own should copy this shape and stay just as
    /// conservative: a trigger word that is also an everyday noun (German
    /// "Punkt", Chinese 点) will fire on ordinary prose, so leave it out and
    /// let the LLM pass handle it.
    public static let english = SpokenSymbolVocabulary(
        dot: ["dot"],
        underscore: ["underscore"],
        dash: ["dash"],
        slash: ["slash"],
        tilde: ["tilde"],
        comma: ["comma"],
        emailAt: ["at"],
        openers: ["open"],
        closers: ["close"],
        parenNouns: ["paren", "parens", "parenthesis"],
        bracketNouns: ["bracket", "brackets"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
            "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
            "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
        ],
        extensionHomophones: [
            "pie": "py",
            "pi": "py",
        ],
        emailTLDs: [
            "com", "net", "org", "io", "co", "dev", "app", "ai", "edu", "gov", "me",
        ],
        joinGuards: LanguagePack.englishStopwords,
        emailLocalGuards: LanguagePack.englishStopwords.union([
            "look", "looking", "looked", "go", "going", "meet", "meeting",
            "back", "up", "over", "out", "stay", "arrive", "start", "starts",
        ]))
}
