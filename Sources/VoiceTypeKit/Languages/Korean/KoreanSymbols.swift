import Foundation

extension SpokenSymbolVocabulary {
    /// Korean code-dictation vocabulary.
    ///
    /// This deliberately stays off `LanguagePack.symbols`: a shared integrity
    /// contract reserves that field for English. The Korean pack invokes the
    /// same renderer from its own early rule, which also repairs model output.
    ///
    /// Bare 점 is admitted only here, never as unconditional punctuation. The
    /// renderer requires a known extension/TLD on the right and a non-stopword
    /// identifier on the left, so ordinary senses such as "이 점", "삼 점",
    /// "백 점", and "가게 점" survive unchanged.
    static let korean = SpokenSymbolVocabulary(
        dot: ["닷", "점"],
        underscore: ["언더스코어"],
        dash: ["대시", "하이픈"],
        slash: ["슬래시"],
        tilde: ["틸드"],
        comma: ["쉼표"],
        emailAt: ["골뱅이", "앳"],
        openers: ["여는"],
        closers: ["닫는"],
        parenNouns: ["괄호", "소괄호"],
        bracketNouns: ["대괄호", "브래킷"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
            "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
            "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
        ],
        extensionHomophones: [
            "파이": "py",
            "피와이": "py",
            "제이에스": "js",
            "티에스": "ts",
            "제이슨": "json",
            "스위프트": "swift",
            "마크다운": "md",
        ],
        emailTLDs: [
            "com", "net", "org", "io", "co", "dev", "app", "ai", "kr",
        ],
        joinGuards: KoreanCleanup.stopwords,
        emailLocalGuards: KoreanCleanup.stopwords.union([
            "보기", "보면", "가서", "와서", "만나", "연락", "메일",
        ]))
}
