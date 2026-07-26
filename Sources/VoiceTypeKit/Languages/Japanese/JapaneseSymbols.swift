import Foundation

extension SpokenSymbolVocabulary {
    /// Guarded Japanese code-dictation vocabulary. It is intentionally invoked
    /// from a Japanese-owned CleanupRule rather than `LanguagePack.symbols`:
    /// the shared integrity contract reserves that field for English, and a
    /// CleanupRule also repairs symbols the model leaves behind.
    static let japanese = SpokenSymbolVocabulary(
        dot: ["ドット"],
        underscore: ["アンダースコア", "アンダーバー"],
        dash: ["ハイフン"],
        slash: ["スラッシュ"],
        tilde: ["チルダ"],
        comma: ["カンマ"],
        emailAt: ["アットマーク"],
        openers: ["開き"],
        closers: ["閉じ"],
        parenNouns: ["丸括弧", "丸かっこ"],
        bracketNouns: ["角括弧", "角かっこ"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
            "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
            "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
        ],
        extensionHomophones: [
            "パイ": "py",
            "ジェイエス": "js",
            "ティーエス": "ts",
            "ジェイソン": "json",
        ],
        emailTLDs: [
            "com", "net", "org", "io", "co", "dev", "app", "ai", "edu", "gov", "jp",
        ],
        joinGuards: JapanesePackData.stopwords,
        emailLocalGuards: JapanesePackData.stopwords)
}

extension CleanupRule {
    /// Runs in terminals because its terminal-only branches are exactly the
    /// command-safe behavior Japanese speakers need: flags and paths become
    /// ASCII, while capitalization and terminal punctuation remain disabled.
    static let renderJapaneseSpokenSymbols = CleanupRule(
        name: "Japanese guarded spoken symbols",
        stage: .early,
        runsInTerminal: true
    ) { text, context in
        JapaneseSpokenSymbolRenderer.render(text, category: context.category)
    }
}

private enum JapaneseSpokenSymbolRenderer {
    /// Japanese particles attach directly to the preceding token, so a
    /// transcriber commonly emits `main ドット パイを開く`: the shared
    /// whitespace-token renderer sees `パイを開く`, not the extension `パイ`.
    /// Repair that Japanese-specific shape first, then let the shared guarded
    /// renderer handle ordinary extension, identifier, flag, and path cases.
    static func render(_ text: String, category: AppCategory) -> String {
        let withAttachedExtensions = renderExtensionsBeforeJapaneseSuffix(in: text)
        return SpokenSymbols.render(
            withAttachedExtensions,
            category: category,
            vocabulary: .japanese)
    }

    private static let extensionSpellings: [String: String] = [
        "パイ": "py",
        "ジェイエス": "js",
        "ティーエス": "ts",
        "ジェイソン": "json",
    ]

    private static let literalExtensions: Set<String> = [
        "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
        "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
        "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
    ]

    private static func renderExtensionsBeforeJapaneseSuffix(in text: String) -> String {
        let names = (Array(extensionSpellings.keys) + Array(literalExtensions))
            .sorted { $0.count > $1.count }
            .map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
        let pattern = #"([\p{L}\p{N}._-]+)[ \t]+ドット[ \t]+("#
            + names
            + #")(?=[\p{Han}\p{Hiragana}\p{Katakana}]|$)"#
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]) else { return text }

        var out = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let whole = Range(match.range, in: out),
                  let stemRange = Range(match.range(at: 1), in: out),
                  let extensionRange = Range(match.range(at: 2), in: out) else { continue }
            let stem = String(out[stemRange])
            let spokenExtension = String(out[extensionRange])
            let lowered = spokenExtension.lowercased()
            let renderedExtension = extensionSpellings[spokenExtension]
                ?? (literalExtensions.contains(lowered) ? lowered : spokenExtension)
            out.replaceSubrange(whole, with: stem + "." + renderedExtension)
        }
        return out
    }
}
