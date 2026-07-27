import Foundation

extension SpokenSymbolVocabulary {
    /// Spanish spoken symbols.
    ///
    /// Everything here is a single token, because that is all `SpokenSymbols`
    /// matches. Spanish's two-word symbol names ("guion bajo", "punto y coma",
    /// "abrir comillas") are handled by rules in `SpanishOrthography` instead.
    ///
    /// Two triggers deserve their justification up front, because both are
    /// everyday Spanish nouns:
    ///
    /// - **"punto"** (punto de vista, punto clave, a punto de). It is safe
    ///   *only* because the dot pipeline additionally demands a joinable
    ///   non-stopword on the left and a known file extension — or spelled
    ///   letters forming one — on the right. "el punto de partida" fails both
    ///   tests; "main punto pi" passes both.
    /// - **"barra"** (a bar, a counter) and **"tilde"** (in Spanish, the
    ///   *accent mark*, not `~`). Both are consulted only by the terminal path,
    ///   where a shell command is the expected register. "virgulilla" is the
    ///   correct Spanish name for `~` and is listed first for that reason.
    ///
    /// Deliberately absent: **"coma"** outside a spoken paren pair (it is a
    /// noun and a verb form: "en coma", "que coma"), **"menos"** for `-`
    /// (comparative), and Spanish letter names ("ese", "te", "de") for spelled
    /// extensions — mapping those to letters would shred ordinary prose.
    public static let spanish = SpokenSymbolVocabulary(
        dot: ["punto"],
        // "guion bajo" is joined by SpanishOrthography before this runs; the
        // English loan is what Spanish-speaking developers say just as often.
        underscore: ["underscore"],
        dash: ["guion", "guión"],
        slash: ["barra"],
        tilde: ["virgulilla", "tilde"],
        comma: ["coma"],
        emailAt: ["arroba"],
        openers: ["abrir", "abre"],
        closers: ["cerrar", "cierra"],
        parenNouns: ["paréntesis", "parentesis"],
        bracketNouns: ["corchete", "corchetes"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
            "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
            "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
        ],
        // How ".py" comes out of a Spanish transcriber: the letters are read
        // as the Spanish word for the sound, not spelled out.
        extensionHomophones: [
            "pi": "py",
            "pai": "py",
        ],
        emailTLDs: [
            "com", "net", "org", "io", "co", "dev", "app", "ai", "edu", "gov",
            "me", "es", "mx", "ar", "cl", "pe", "uy", "ve",
        ],
        joinGuards: LanguagePack.spanishStopwords,
        // Verbs that read as prose immediately before a spoken address. Short,
        // because "arroba" — unlike English "at" — is never a preposition, so
        // the false-positive pressure this guards against barely exists.
        emailLocalGuards: LanguagePack.spanishStopwords.union([
            "mira", "mirar", "ve", "ver", "vamos", "quedamos", "escribe",
            "escribir", "manda", "mandar", "envía", "enviar", "responde",
        ]))
}
