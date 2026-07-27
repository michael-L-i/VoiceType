import Foundation

extension SpokenSymbolVocabulary {
    /// Estonian technical-dictation words. The pack deliberately leaves its
    /// public `symbols` field nil because the shared policy reserves that field
    /// for English; an Estonian-owned CleanupRule invokes this vocabulary in
    /// both the rules floor and model-output polish instead.
    ///
    /// Potentially ordinary words stay constrained by `SpokenSymbols`:
    /// `punkt` joins only a known extension, `kriips` joins only a single
    /// letter outside terminals, and terminal flags/paths receive the explicit
    /// command-line bias.
    static let estonian = SpokenSymbolVocabulary(
        dot: ["punkt"],
        underscore: ["alakriips"],
        dash: ["kriips", "sidekriips"],
        slash: ["kaldkriips"],
        tilde: ["tilde"],
        comma: ["koma"],
        emailAt: ["ätt"],
        openers: ["ava"],
        closers: ["sulge"],
        parenNouns: ["sulg", "sulud"],
        bracketNouns: ["nurksulg", "nurksulud"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h",
            "cpp", "hpp", "java", "rb", "php", "sh", "md", "txt", "json",
            "yaml", "yml", "toml", "html", "css", "xml", "sql", "csv", "log",
            "lock", "env", "pdf",
        ],
        extensionHomophones: [:],
        emailTLDs: [
            "ee", "com", "net", "org", "io", "co", "dev", "app", "ai", "eu",
            "fi", "lv", "lt",
        ],
        joinGuards: LanguagePack.estonianStopwords,
        emailLocalGuards: LanguagePack.estonianStopwords.union([
            "vaata", "saada", "kirjuta", "helista", "mine", "tule", "tagasi",
        ]))
}
