import Foundation

/// Chinese-owned spoken-code rendering invoked from a `CleanupRule`.
///
/// `LanguagePack.symbols` remains nil because the shared contract reserves it
/// for English. More importantly, a rule repairs literal symbol words in both
/// the rules floor and model polish. The shared renderer supplies the safety
/// shape: 点 joins only before a known file extension, while 艾特 joins only
/// inside a Latin address anchored by a known top-level domain.
enum ChineseSpokenSymbols {
    static let spokenWords: Set<String> = [
        "点", "艾特",
        "句号", "逗号", "顿号", "问号", "感叹号", "叹号", "冒号", "分号",
        "左括号", "右括号", "左引号", "右引号", "省略号",
        "另起一行", "新段落", "换行",
    ]

    private static let fileExtensions: Set<String> = [
        "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h",
        "cpp", "hpp", "java", "rb", "php", "sh", "md", "txt", "json",
        "yaml", "yml", "toml", "html", "css", "xml", "sql", "csv", "log",
        "lock", "env",
    ]

    private static let vocabulary = SpokenSymbolVocabulary(
        dot: ["点"],
        underscore: [],
        dash: [],
        slash: [],
        tilde: [],
        comma: [],
        emailAt: ["艾特"],
        openers: [],
        closers: [],
        parenNouns: [],
        bracketNouns: [],
        fileExtensions: fileExtensions,
        extensionHomophones: [:],
        emailTLDs: [
            "cn", "com", "net", "org", "io", "co", "dev", "app", "ai", "edu",
            "gov", "me",
        ],
        joinGuards: [
            "的", "了", "把", "请", "和", "在", "是", "快",
            "a", "an", "the", "to", "of",
        ],
        emailLocalGuards: [
            "a", "an", "the", "to", "at", "from", "email", "send",
        ])

    static let rule = CleanupRule(
        name: "render structurally explicit Chinese spoken symbols",
        stage: .early,
        runsInTerminal: true
    ) { text, context in
        SpokenSymbols.render(
            renderExtensionBeforeChineseBoundary(in: text),
            category: context.category,
            vocabulary: vocabulary)
    }

    /// The shared renderer recognizes ASCII punctuation attached to an
    /// extension, while Chinese model output naturally attaches a full-width
    /// mark (`main 点 py，`). Join that one CJK-specific shape before handing
    /// the remaining text to the shared guarded renderer.
    private static func renderExtensionBeforeChineseBoundary(in text: String) -> String {
        let extensions = fileExtensions
            .sorted { $0.count > $1.count }
            .map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
        let pattern = #"(?i)([\p{Latin}\p{N}._-]+)[ \t]+点[ \t]+("#
            + extensions
            + #")(?=[\p{Han}。，、！？：；]|$)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: "$1.$2")
    }
}

extension CleanupRule {
    static let renderChineseSpokenSymbols = ChineseSpokenSymbols.rule
}
