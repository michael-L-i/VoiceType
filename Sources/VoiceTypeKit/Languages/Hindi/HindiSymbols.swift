import Foundation

extension SpokenSymbolVocabulary {
    /// Guarded technical vocabulary used from Hindi's own CleanupRule. It is
    /// intentionally not assigned to `LanguagePack.symbols`: non-English packs
    /// must keep that shared field nil, and a language-owned rule also runs on
    /// model output.
    static let hindiRuleVocabulary = SpokenSymbolVocabulary(
        dot: ["डॉट"],
        underscore: ["अंडरस्कोर"],
        dash: ["डैश", "हाइफ़न", "हाइफन"],
        slash: ["स्लैश"],
        tilde: ["टिल्ड", "टिल्डा"],
        comma: ["कॉमा"],
        emailAt: ["ऐट", "एट"],
        openers: ["खुला", "ओपन"],
        closers: ["बंद", "क्लोज़", "क्लोज"],
        parenNouns: ["कोष्ठक", "पैरन", "पैरेंथेसिस"],
        bracketNouns: ["ब्रैकेट"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h",
            "cpp", "hpp", "java", "rb", "php", "sh", "md", "txt", "json",
            "yaml", "yml", "toml", "html", "css", "xml", "sql", "csv", "log",
            "lock", "env",
        ],
        // Common Devanagari renderings produced when a Hindi recognizer hears
        // an ASCII extension. These are only consumed after explicit डॉट.
        extensionHomophones: [
            "पाई": "py",
            "पीवाई": "py",
            "जेएस": "js",
            "टीएस": "ts",
            "जेसन": "json",
            "जेएसओएन": "json",
            "स्विफ्ट": "swift",
            "एमडी": "md",
            "एचटीएमएल": "html",
            "सीएसएस": "css",
            "एक्सएमएल": "xml",
            "एसक्यूएल": "sql",
            "सीएसवी": "csv",
            "यैमल": "yaml",
            "वाईएएमएल": "yaml",
        ],
        emailTLDs: [
            "com", "net", "org", "io", "co", "dev", "app", "ai", "in", "edu",
            "gov", "me",
        ],
        joinGuards: LanguagePack.hindiStopwords,
        emailLocalGuards: LanguagePack.hindiStopwords.union([
            "देखो", "देखना", "जाओ", "जाना", "मिलो", "मिलना", "आओ", "आना",
            "रुको", "रहना", "शुरू", "करो",
        ]))
}
