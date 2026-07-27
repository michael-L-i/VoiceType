import Foundation

extension SpokenSymbolVocabulary {
    /// How French speakers say a symbol out loud, for the zero-latency
    /// `SpokenSymbols` renderer.
    ///
    /// The pack does **not** put this in its `symbols` field; it hands it to
    /// the renderer from `frenchSpokenSymbolRule` instead, so the ordering
    /// against the pack's own phrase rules is explicit and so model output gets
    /// the same treatment as the deterministic floor.
    ///
    /// The uncomfortable entry is `dot: ["point"]`, which docs/LOCALIZATION.md
    /// warns about by name (German "Punkt", Chinese 点). It earns its place
    /// here because the renderer's neighbour rules, not the trigger word, do the
    /// deciding: a spoken "point" only joins when the token on its left is not
    /// a function word *and* the token on its right is a known file extension
    /// or the tail of an e-mail address. Every ordinary use of the noun fails
    /// one of those tests — « le point de vue » ("le" is a join guard), « un bon
    /// point pour toi » ("pour" is not an extension), « à quel point » (both).
    /// What survives is exactly the case we want: « ouvre main point py ».
    ///
    /// Deliberately absent:
    /// - **Single-letter extensions.** English joins "dot c" and "dot h";
    ///   French drops them, because a bare letter after « point » is far more
    ///   likely to be a spelled-out word than a C header. Two-letter spellings
    ///   ("point j s" → `.js`) still work.
    /// - **openers / closers / paren nouns.** French says « ouvrez *la*
    ///   parenthèse » — an article the renderer's adjacent-token rule cannot
    ///   see. The pack handles the whole phrase as a `CleanupRule` instead.
    /// - **"souligné"** for the underscore: it is also the past participle of
    ///   *souligner*, and « le mot souligné rouge » would weld into an
    ///   identifier. « tiret bas » covers the same need as a guarded phrase.
    /// - **"barre" / "barre oblique"** for the slash: "barre" alone is a common
    ///   noun and the two-word form is out of the renderer's reach. French
    ///   developers say "slash" anyway.
    public static let french = SpokenSymbolVocabulary(
        dot: ["point"],
        underscore: ["underscore"],
        dash: ["tiret"],
        slash: ["slash"],
        tilde: ["tilde"],
        comma: ["virgule"],
        emailAt: ["arobase", "at"],
        openers: [],
        closers: [],
        parenNouns: [],
        bracketNouns: [],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "cpp",
            "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
            "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
        ],
        // ".py" is read « point pi » in French; transcribers spell that "pi"
        // or "pie".
        extensionHomophones: [
            "pi": "py",
            "pie": "py",
        ],
        emailTLDs: [
            "com", "net", "org", "io", "co", "dev", "app", "ai", "me",
            "fr", "eu", "be", "ch", "ca", "gouv",
        ],
        joinGuards: LanguagePack.frenchStopwords,
        emailLocalGuards: LanguagePack.frenchStopwords.union([
            "regarde", "regardez", "regarder", "écris", "écrivez", "écrire",
            "envoie", "envoyez", "envoyer", "contacte", "contactez",
            "va", "aller", "vas", "arrive", "commence", "reste", "travaille",
            "rendez", "parle", "réponds", "répondez",
        ]))
}
