import Foundation

extension SpokenSymbolVocabulary {
    /// Finnish spoken symbols used through a pack-owned CleanupRule rather
    /// than `LanguagePack.symbols`. The contextual renderer protects ordinary
    /// prose: piste joins only before a known extension, alaviiva only between
    /// identifier-like neighbors, and viiva becomes a flag only in a terminal.
    static let finnish = SpokenSymbolVocabulary(
        dot: ["piste"],
        underscore: ["alaviiva"],
        dash: ["viiva", "tavuviiva", "yhdysmerkki"],
        slash: ["kauttaviiva"],
        tilde: ["tilde"],
        comma: ["pilkku"],
        emailAt: ["ät", "at-merkki", "at merkki"],
        openers: ["avaa"],
        closers: ["sulje"],
        parenNouns: ["kaarisulku"],
        bracketNouns: ["hakasulku"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h",
            "cpp", "hpp", "java", "rb", "php", "sh", "md", "txt", "json",
            "yaml", "yml", "toml", "html", "css", "xml", "sql", "csv", "log",
            "lock", "env",
        ],
        // Finnish letter names are frequent ASR renderings of short English
        // extensions. Restrict them to the known-extension position.
        extensionHomophones: [
            "pyy": "py",
            "pee-yy": "py",
            "jiiäs": "js",
            "jiies": "js",
            "teeäs": "ts",
            "tee-äs": "ts",
        ],
        emailTLDs: [
            "fi", "com", "net", "org", "io", "co", "dev", "app", "ai", "edu",
        ],
        joinGuards: LanguagePack.finnishStopwords,
        emailLocalGuards: LanguagePack.finnishStopwords.union([
            "katso", "katson", "katsoin", "mene", "menen", "mennään",
            "tule", "tulen", "tavataan", "takaisin", "perillä",
        ]))
}
