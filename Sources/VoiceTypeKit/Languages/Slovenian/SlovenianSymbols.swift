import Foundation

/// Slovenian's spoken-symbol vocabulary is intentionally applied from a
/// Slovenian-owned `CleanupRule`, not `LanguagePack.symbols`: repository policy
/// reserves that pack field for English today, while the rule also repairs
/// model output and can handle Slovenian multi-word bracket names.
enum SlovenianSymbols {
    static let closingBraceMarker = "\u{E200}"

    static let spokenWords: Set<String> = [
        "pika", "podčrtaj", "vezaj", "poševnica", "slash", "tilda", "vejica",
        "afna", "odpri", "zapri", "oklepaj", "oglati", "zaviti",
        "dvopičje", "podpičje", "vprašaj", "klicaj", "enačaj", "plus", "minus",
        "zvezdica", "ključnik", "lojtra", "presledek", "vrstica",
    ]

    private static let vocabulary = SpokenSymbolVocabulary(
        dot: ["pika"],
        underscore: ["podčrtaj"],
        dash: ["vezaj"],
        slash: ["poševnica", "slash"],
        tilde: ["tilda"],
        comma: ["vejica"],
        emailAt: ["afna"],
        openers: ["odpri"],
        closers: ["zapri"],
        parenNouns: ["oklepaj"],
        // Multi-word oglati/zaviti oklepaj forms are handled just below.
        bracketNouns: [],
        fileExtensions: [
            "c", "cpp", "css", "csv", "env", "go", "h", "html", "java", "js",
            "json", "jsx", "log", "md", "pdf", "php", "py", "rb", "rs", "sh",
            "sql", "swift", "toml", "ts", "tsx", "txt", "xml", "yaml", "yml",
        ],
        extensionHomophones: [
            "pi": "py",
        ],
        emailTLDs: [
            "ai", "app", "com", "dev", "eu", "io", "net", "org", "si",
        ],
        joinGuards: LanguagePack.slovenianStopwords,
        emailLocalGuards: LanguagePack.slovenianStopwords.union([
            "glej", "poglej", "pojdi", "pridi", "ostani", "srečaj", "dobimo",
        ]))

    static func render(_ text: String, context: CleanupContext) -> String {
        var out = text
        let bracketPhrases: [(String, String)] = [
            (#"\bodpri\s+oglati\s+oklepaj\b"#, "["),
            (#"\bzapri\s+oglati\s+oklepaj\b"#, "]"),
            (#"\bodpri\s+zaviti\s+oklepaj\b"#, "{"),
            (#"\bzapri\s+zaviti\s+oklepaj\b"#, closingBraceMarker),
        ]
        for (pattern, mark) in bracketPhrases {
            out = replacing(out, pattern: pattern, template: mark)
        }

        out = SpokenSymbols.render(
            out,
            category: context.category,
            vocabulary: vocabulary
        )

        // Braces are not part of the shared assembler's paren token set.
        // They only exist here after an explicit "zaviti oklepaj" phrase.
        out = replacing(out, pattern: #"\s*\{\s*"#, template: "{")
        out = replacing(
            out,
            pattern: #"\s*"# + closingBraceMarker,
            template: closingBraceMarker
        )
        return out
    }

    private static func replacing(
        _ text: String,
        pattern: String,
        template: String
    ) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else { return text }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: template
        )
    }
}
