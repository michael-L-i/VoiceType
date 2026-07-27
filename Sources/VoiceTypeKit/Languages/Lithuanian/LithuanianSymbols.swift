import Foundation

extension SpokenSymbolVocabulary {
    /// Lithuanian technical dictation vocabulary. It is invoked by a local
    /// CleanupRule rather than `LanguagePack.symbols`, so shared integrity
    /// policy remains intact and the same rendering repairs model output.
    public static let lithuanian = SpokenSymbolVocabulary(
        dot: ["taškas", "tašką"],
        underscore: ["voicetypeltpabraukimas", "voicetypeltapatinis"],
        dash: ["brūkšnelis", "minusas"],
        slash: ["voicetypeltpasvirasis"],
        tilde: ["tildė"],
        comma: ["kablelis", "kablelį"],
        emailAt: ["eta", "voicetypelteta"],
        openers: ["atidaromasis", "atvirasis", "kairysis"],
        closers: ["uždaromasis", "uždarasis", "dešinysis"],
        parenNouns: ["skliaustas", "skliaustai"],
        bracketNouns: ["voicetypeltlaužtinis", "voicetypeltlaužtiniai"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
            "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
            "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
            "pdf", "docx", "xlsx", "pptx", "zip",
        ],
        extensionHomophones: [
            "pi": "py",
        ],
        emailTLDs: [
            "lt", "eu", "com", "net", "org", "io", "dev", "app", "ai", "edu",
        ],
        joinGuards: LanguagePack.lithuanianStopwords,
        emailLocalGuards: LanguagePack.lithuanianStopwords.union([
            "žiūrėk", "žiūrėti", "eik", "eiti", "grįžk", "grįžti",
            "susitik", "susitikti", "lik", "likti", "pradėk", "pradėti",
        ]))
}

enum LithuanianSpokenSymbols {
    private static let phraseTokens: [(phrase: String, token: String)] = [
        ("pabraukimo brūkšnys", "voicetypeltpabraukimas"),
        ("apatinis brūkšnys", "voicetypeltapatinis"),
        ("pasvirasis dešininis brūkšnys", "voicetypeltpasvirasis"),
        ("pasvirasis brūkšnys", "voicetypeltpasvirasis"),
        ("laužtiniai skliaustai", "voicetypeltlaužtiniai"),
        ("laužtinis skliaustas", "voicetypeltlaužtinis"),
        ("ženklas eta", "voicetypelteta"),
    ]

    static func render(_ text: String, category: AppCategory) -> String {
        var prepared = text
        for entry in phraseTokens {
            prepared = prepared.replacingOccurrences(
                of: entry.phrase,
                with: entry.token,
                options: [.caseInsensitive])
        }
        var rendered = SpokenSymbols.render(
            prepared,
            category: category,
            vocabulary: .lithuanian)

        // A phrase that did not meet the conservative neighbor guards is prose,
        // not a half-rendered identifier. Restore it exactly as Lithuanian words.
        for entry in phraseTokens {
            rendered = rendered.replacingOccurrences(
                of: entry.token,
                with: entry.phrase,
                options: [.caseInsensitive])
        }
        return rendered
    }
}
