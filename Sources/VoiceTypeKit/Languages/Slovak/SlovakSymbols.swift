import Foundation

/// Context-anchored spoken technical symbols for Slovak.
///
/// This vocabulary is deliberately invoked from a Slovak `CleanupRule` rather
/// than `LanguagePack.symbols`: the repository's integrity contract currently
/// reserves that field for English. The rule also has the useful property of
/// running over model output, not only over the rules floor.
enum SlovakSymbols {
    static let spokenWords: Set<String> = [
        "bodka", "podčiarkovník", "pomlčka", "spojovník", "mínus",
        "lomka", "tilda", "vlnovka", "čiarka", "zavináč",
        "otvorená", "otváracia", "ľavá", "zatvorená", "zatváracia", "pravá",
        "zátvorka",
    ]

    private static let vocabulary = SpokenSymbolVocabulary(
        dot: ["bodka"],
        underscore: ["podčiarkovník"],
        dash: ["pomlčka", "spojovník", "mínus"],
        slash: ["lomka"],
        tilde: ["tilda", "vlnovka"],
        comma: ["čiarka"],
        emailAt: ["zavináč"],
        openers: ["otvorená", "otváracia", "ľavá"],
        closers: ["zatvorená", "zatváracia", "pravá"],
        parenNouns: ["zátvorka"],
        // Slovaks normally say the three-word phrase `hranatá zátvorka`.
        // The shared two-token parser cannot represent that safely, so square
        // brackets stay prompt-only.
        bracketNouns: [],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h",
            "cpp", "hpp", "java", "rb", "php", "sh", "md", "txt", "json",
            "yaml", "yml", "toml", "html", "css", "xml", "sql", "csv", "log",
            "lock", "env",
        ],
        extensionHomophones: [
            "paj": "py",
        ],
        emailTLDs: [
            "sk", "cz", "eu", "com", "net", "org", "io", "dev", "app", "ai",
            "edu", "gov", "me",
        ],
        joinGuards: LanguagePack.slovakStopwords,
        emailLocalGuards: LanguagePack.slovakStopwords.union([
            "pozri", "pozrite", "napíš", "napíšte", "pošli", "pošlite",
            "choď", "choďte", "stretneme", "stretnúť", "príď", "príďte",
        ]))

    static func render(_ text: String, _ context: CleanupContext) -> String {
        let containsTrigger = text.split(whereSeparator: \.isWhitespace).contains { token in
            let core = token.trimmingCharacters(in: .punctuationCharacters).lowercased()
            return spokenWords.contains(core)
        }
        guard containsTrigger else { return text }
        return SpokenSymbols.render(
            text,
            category: context.category,
            vocabulary: vocabulary)
    }
}
