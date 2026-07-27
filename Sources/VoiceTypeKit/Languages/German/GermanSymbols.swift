import Foundation

extension SpokenSymbolVocabulary {
    /// German spoken symbols — the words a German speaker uses to dictate a file
    /// name, an identifier, a flag or an address.
    ///
    /// This vocabulary is **not** wired into `LanguagePack.symbols`. It is
    /// driven from a `CleanupRule` inside the German pack instead
    /// (`GermanRules.spokenSymbols`), which lets German opt into the shared
    /// `SpokenSymbols` token pipeline without claiming the pack field. The
    /// pipeline's neighbor guards are language-neutral; only the trigger words
    /// below are German's.
    ///
    /// Why the guards matter more here than in English: every one of these
    /// triggers is an everyday German noun. "Punkt" is the most common
    /// (*auf den Punkt*, *Punkt zwölf*, *der springende Punkt*), "Strich" and
    /// "Klammer" not far behind. `SpokenSymbols` only joins when the *left*
    /// neighbor is a non-stopword identifier part **and** the *right* neighbor
    /// is a known file extension / single letter / flag name, so ordinary prose
    /// never fires. That is the whole reason this is safe to run at all.
    ///
    /// Deliberately NOT covered here:
    /// - **Parentheses.** German says the noun first — "Klammer auf" — while
    ///   the shared renderer expects opener-then-noun ("open paren"). It cannot
    ///   express the German order, so parens are a regex rule in `GermanRules`.
    /// - **Spelled-out letters.** German letter names transcribe as whole words
    ///   ("jott", "ypsilon", "fau", "iks", "zett"), not the single characters
    ///   the renderer's spelled-letter path needs. The LLM prompt teaches
    ///   "Punkt jott es" → .js; the deterministic path only takes whole-word
    ///   extensions.
    public static let german = SpokenSymbolVocabulary(
        dot: ["punkt"],
        underscore: ["unterstrich", "underscore"],
        // "minus" is included for the terminal, where "minus v" is a flag.
        // Outside a terminal the renderer needs a single letter on the right,
        // so arithmetic ("fünf minus drei") can never join.
        dash: ["strich", "bindestrich", "minus"],
        slash: ["schrägstrich", "slash"],
        tilde: ["tilde"],
        comma: ["komma"],
        // "ätt" / "att" are how transcribers usually render the spoken @.
        emailAt: ["at", "ätt", "att"],
        openers: [],
        closers: [],
        parenNouns: [],
        bracketNouns: [],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
            "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
            "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
        ],
        extensionHomophones: [
            // German renderings of the extensions whose spoken form is a word
            // rather than spelled letters.
            "pie": "py",
            "pi": "py",
            "pü": "py",
            "jason": "json",
            "jott": "js",
        ],
        // The German-speaking TLDs alongside the international ones.
        emailTLDs: [
            "de", "at", "ch", "eu",
            "com", "net", "org", "io", "co", "dev", "app", "ai", "info", "me",
        ],
        joinGuards: LanguagePack.germanStopwords,
        // Verbs that make "… at <domain>" read as a sentence rather than an
        // address ("schau at gmail punkt com" is prose, not an email).
        emailLocalGuards: LanguagePack.germanStopwords.union([
            "schau", "schaut", "guck", "guckt", "sieh", "seht", "treffen",
            "treffe", "trifft", "arbeite", "arbeitet", "warte", "wartet",
            "bleib", "bleibt", "komm", "kommt", "geh", "geht", "fang", "fängt",
            "start", "startet", "beginnt", "endet", "zurück", "vorbei",
        ]))
}
