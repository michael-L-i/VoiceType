import Foundation

/// Greek speakers commonly mix Greek symbol names with the English tokens used
/// in source code. This vocabulary stays local to a CleanupRule rather than
/// `LanguagePack.symbols`, preserving the shared English-only pack invariant
/// while applying the renderer to both raw and model-produced text.
enum GreekSpokenSymbols {
    static let guardWords: Set<String> = [
        "τελεία", "κουκκίδα", "κάτω", "παύλα", "κάτω_παύλα",
        "ενωτικό", "κάθετος", "περισπωμένη", "κόμμα", "παπάκι",
        "άνοιγμα", "κλείσιμο", "ανοιχτή", "κλειστή",
        "παρένθεση", "παρενθέσεις", "αγκύλη", "αγκύλες",
        "dot", "underscore", "dash", "hyphen", "slash", "tilde",
        "comma", "at", "open", "close", "paren", "parenthesis", "bracket",
    ]

    private static let vocabulary = SpokenSymbolVocabulary(
        dot: ["τελεία", "κουκκίδα", "dot"],
        underscore: ["κάτω_παύλα", "underscore"],
        dash: ["παύλα", "ενωτικό", "dash", "hyphen"],
        slash: ["κάθετος", "slash"],
        tilde: ["περισπωμένη", "tilde"],
        comma: ["κόμμα", "comma"],
        emailAt: ["παπάκι", "at"],
        openers: ["άνοιγμα", "ανοιχτή", "ανοιχτές", "open"],
        closers: ["κλείσιμο", "κλειστή", "κλειστές", "close"],
        parenNouns: ["παρένθεση", "παρενθέσεις", "paren", "parenthesis"],
        bracketNouns: ["αγκύλη", "αγκύλες", "bracket"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
            "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
            "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
        ],
        extensionHomophones: [:],
        emailTLDs: [
            "com", "net", "org", "io", "co", "dev", "app", "ai", "edu", "gov", "gr", "eu",
        ],
        joinGuards: LanguagePack.greekStopwords,
        emailLocalGuards: LanguagePack.greekStopwords.union([
            "δες", "κοίτα", "πήγαινε", "στείλε", "γράψε", "βρες",
            "look", "go", "send", "write", "find",
        ]))

    static func render(_ text: String, category: AppCategory) -> String {
        var normalized = text.replacingOccurrences(
            of: "κάτω παύλα",
            with: "κάτω_παύλα",
            options: [.caseInsensitive])
        // A second common form uses "πλάγια κάθετος"; the extra adjective is
        // descriptive, not part of the path token.
        normalized = normalized.replacingOccurrences(
            of: "πλάγια κάθετος",
            with: "κάθετος",
            options: [.caseInsensitive])
        let rendered = SpokenSymbols.render(
            normalized,
            category: category,
            vocabulary: vocabulary)
        // The multi-word trigger is hidden in one token only so the shared
        // renderer can recognize it. If its neighbor guards reject the join,
        // put the ordinary Greek phrase back exactly as spoken.
        return rendered.replacingOccurrences(
            of: "κάτω_παύλα",
            with: "κάτω παύλα",
            options: [.caseInsensitive])
    }
}
