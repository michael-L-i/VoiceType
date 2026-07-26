import Foundation

extension SpokenSymbolVocabulary {
    /// The words a Swedish speaker uses to dictate a symbol, fed to the shared
    /// `SpokenSymbols` token pipeline by `SwedishRules.spokenSymbols`.
    ///
    /// The names are Apple's own Swedish dictation vocabulary (Apple Support,
    /// "Kommandon för textdiktering på datorn"), which is what Swedish users
    /// already have in their fingers: punkt, bindestreck, understreck,
    /// snedstreck, snabel-a, vänsterparentes/högerparentes.
    ///
    /// Why `punkt` is safe *here* but not in a flat replacement table: this
    /// pipeline only joins on a dot when the right-hand side is a known file
    /// extension ("main punkt paj" → main.py) or when the whole run matches
    /// the email pattern, and only when the left-hand side is not a function
    /// word. Ordinary prose ("en viktig punkt") has neither, so it passes
    /// through untouched and reaches the positional period rule instead.
    ///
    /// Deliberately absent: `komma` (the verb "to come") and `slag`/`prick`.
    static let swedish = SpokenSymbolVocabulary(
        dot: ["punkt"],
        underscore: ["understreck", "understrykning"],
        // `streck` is terminal-only — see `swedishTerminal` below.
        dash: ["bindestreck", "minus"],
        slash: ["snedstreck"],
        tilde: ["tilde"],
        comma: ["kommatecken"],
        emailAt: ["snabel-a", "snabela", "at"],
        openers: ["vänster", "öppen", "öppna"],
        closers: ["höger", "stäng", "slut"],
        parenNouns: ["parentes", "parenteser"],
        bracketNouns: ["hakparentes", "hakparenteser", "klammer", "klammerparentes"],
        fileExtensions: SpokenSymbolVocabulary.commonFileExtensions,
        // What a Swedish transcriber writes when it hears an English extension
        // spoken as a word: "paj" is simply how "py" sounds in Swedish.
        extensionHomophones: [
            "paj": "py",
            "pi": "py",
            "pie": "py",
        ],
        emailTLDs: SpokenSymbolVocabulary.commonEmailTLDs,
        joinGuards: LanguagePack.swedishStopwords,
        emailLocalGuards: LanguagePack.swedishStopwords.union([
            "titta", "tittar", "kolla", "kollar", "se", "ser", "mejla",
            "mejlar", "maila", "mailar", "skicka", "skickar", "hör", "hörs",
            "ses", "träffas", "börja", "börjar", "slutar", "jobbar", "bor",
            "sitter", "står", "väntar", "tillbaka", "upp", "ut", "in", "hem",
        ]))

    /// The terminal variant. `streck` ("stroke/line") is how a Swede actually
    /// says a CLI flag — "streck streck verbose" → `--verbose` — but in prose
    /// it is an everyday noun ("ett streck i räkningen"), and the non-terminal
    /// dash rule joins on any single letter to its right, which would turn
    /// "drar streck i sanden" into "drar-i sanden". Splitting the vocabulary
    /// by category keeps the useful half without the corruption.
    static let swedishTerminal = SpokenSymbolVocabulary(
        dot: swedish.dot,
        underscore: swedish.underscore,
        dash: swedish.dash.union(["streck"]),
        slash: swedish.slash,
        tilde: swedish.tilde,
        comma: swedish.comma,
        emailAt: swedish.emailAt,
        openers: swedish.openers,
        closers: swedish.closers,
        parenNouns: swedish.parenNouns,
        bracketNouns: swedish.bracketNouns,
        fileExtensions: swedish.fileExtensions,
        extensionHomophones: swedish.extensionHomophones,
        emailTLDs: swedish.emailTLDs,
        joinGuards: swedish.joinGuards,
        emailLocalGuards: swedish.emailLocalGuards)

    // MARK: - Language-neutral lexicons

    /// File extensions and top-level domains are not Swedish or English; they
    /// are the same strings everywhere. Declared here (rather than reaching
    /// into `.english`) so this pack owns its own data, plus the Nordic TLDs a
    /// Swedish speaker actually dictates.
    static let commonFileExtensions: Set<String> = [
        "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
        "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
        "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
    ]

    /// `nu` is deliberately absent even though `.nu` is a live Swedish TLD:
    /// it is also the adverb "now", which is far more common in dictation.
    static let commonEmailTLDs: Set<String> = [
        "com", "net", "org", "io", "co", "dev", "app", "ai", "edu", "gov",
        "me", "se", "eu", "dk", "no", "fi",
    ]
}
