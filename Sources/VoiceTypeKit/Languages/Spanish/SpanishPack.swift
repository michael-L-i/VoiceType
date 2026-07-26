import Foundation

extension LanguagePack {
    /// Spanish (es) — Peninsular and Latin American, one pack.
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - **"este" / "esto"**: the canonical Spanish hesitation *and* the
    ///   demonstrative ("este informe"). Never a deterministic filler; the
    ///   prompt asks the model to judge it in context.
    /// - **"pues" / "bueno" / "o sea" / "vale" / "claro" / "en plan" /
    ///   "digamos" / "¿no?" / "¿sabes?"**: discourse markers that carry
    ///   meaning at least as often as they fill a pause. Same treatment.
    /// - **"punto" and "coma" as standalone spoken punctuation**: "punto" is
    ///   an everyday noun (punto de vista, punto clave, a punto de) and "coma"
    ///   is also a noun and a verb form (que coma, en coma). They are NOT in
    ///   `spokenPunctuation`, which replaces unconditionally. "punto" survives
    ///   as a `SpokenSymbols` dot trigger only because that pipeline additionally
    ///   requires a joinable left neighbour and a known file extension on the
    ///   right.
    /// - **Spelled-out letters** ("punto jota ese" → .js): Spanish letter
    ///   names are ordinary words ("ese", "te", "de", "ce"), so mapping them
    ///   to letters would shred prose. Left to the LLM pass.
    static let spanish = LanguagePack(
        code: "es",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Pure hesitation vowels and nasals only — see the ambiguity policy
        // above for the discourse markers that are deliberately absent.
        // "mm" is excluded on purpose: it is also the millimetre symbol
        // ("5 mm"), and the filler pass is a blind whole-word removal.
        fillers: ["eh", "ehh", "eeh", "em", "emm", "ehm", "mmm", "hmm"],
        spokenPunctuation: [:],
        // Interrogative words ONLY. Spanish yes/no questions don't invert
        // ("¿es bueno?" reads exactly like "es bueno"), so listing verbs would
        // turn plain statements into questions.
        questionPrefixWords: [
            "qué", "quién", "quiénes", "cuándo", "cuánto", "cuánta",
            "cuántos", "cuántas", "dónde", "adónde", "cómo", "cuál", "cuáles",
        ],
        questionSuffixParticles: [],
        stopwords: LanguagePack.spanishStopwords,
        // NOTE: the spoken-symbol vocabulary is `SpokenSymbolVocabulary.spanish`
        // and is applied by a rule (`SpanishOrthography`), not by the `symbols`
        // field. `EnglishPackTests.englishIsTheOnlyOptIn` asserts that no
        // non-English pack sets it, and relaxing that would mean editing
        // another language's test file. Going through the rules hook keeps this
        // change inside `Languages/Spanish/`, and it earns something too: the
        // renderer then also repairs model output, which `symbols` never reaches.
        prompt: .addendumOnly("""
        - Spanish questions and exclamations use opening marks too: write \
        ¿…? and ¡…! around them.
        """),
        rules: SpanishOrthography.rules,
        spokenSymbolWords: LanguagePack.spanishSpokenSymbolWords)

    /// Spanish function words: too common to prove that a dictation's opening
    /// survived (the faithfulness guard skips them) and never safe to fuse into
    /// a dictated identifier (`SpokenSymbols` refuses to join them). Declared
    /// separately because `SpokenSymbolVocabulary.spanish` builds on it before
    /// `LanguagePack.spanish` itself finishes initializing.
    static let spanishStopwords: Set<String> = [
        // Articles, prepositions, conjunctions.
        "el", "la", "los", "las", "lo", "un", "una", "unos", "unas",
        "de", "del", "al", "a", "y", "e", "o", "u", "que", "en", "con",
        "por", "para", "sin", "sobre", "entre", "hasta", "desde", "según",
        "como", "pero", "aunque", "si", "porque", "cuando", "donde", "mientras",
        // Pronouns and possessives.
        "yo", "tú", "él", "ella", "ellos", "ellas", "usted", "ustedes",
        "nosotros", "nosotras", "vosotros", "me", "te", "se", "nos", "os",
        "le", "les", "mi", "mis", "tu", "tus", "su", "sus", "nuestro", "nuestra",
        // Common verb forms that carry no topical content.
        "es", "son", "era", "eran", "fue", "fueron", "ser", "está", "están",
        "estar", "hay", "he", "ha", "han", "había", "hemos", "haber",
        "tiene", "tienen", "tener", "va", "van", "ir",
        // Deictics and high-frequency adverbs.
        "este", "esta", "esto", "estos", "estas", "ese", "esa", "eso",
        "aquel", "aquella", "aquí", "ahí", "allí", "allá",
        "muy", "más", "menos", "ya", "también", "tampoco", "solo", "sólo",
        "ahora", "luego", "entonces", "así", "todo", "toda", "todos", "todas",
        // Discourse markers: legitimately dropped by the LLM pass, so their
        // absence from the output proves nothing about faithfulness.
        "bueno", "vale", "pues", "claro", "sí", "no", "ok", "okay",
        // Self-correction markers: removed along with what they retract.
        "perdón", "perdona", "digo", "mejor", "dicho", "espera", "bueno",
    ]

    /// Spanish words that *name* a symbol out loud. The faithfulness guard
    /// discounts them when counting content, so a heavily-dictated identifier
    /// ("test guion bajo cliente punto pi") doesn't read as a summary.
    static let spanishSpokenSymbolWords: Set<String> = [
        "punto", "puntos", "coma", "comas", "guion", "guión", "bajo",
        "barra", "arroba", "paréntesis", "parentesis", "corchete", "corchetes",
        "llave", "llaves", "comillas", "abrir", "abre", "cerrar", "cierra",
        "virgulilla", "tilde", "almohadilla", "numeral", "asterisco",
        "porcentaje", "dólar", "signo", "símbolo", "mayúscula", "minúscula",
        "espacio", "nueva", "nuevo", "línea", "linea", "salto", "párrafo",
        "parrafo", "aparte", "seguido", "interrogación", "exclamación",
        "igual", "más", "menos", "vertical", "invertida", "inclinada",
    ]
}

// MARK: - Spanish orthography

/// Spanish's own deterministic fixes. Everything the pack's declarative fields
/// cannot express lives here as a named `CleanupRule`, so both cleanup paths —
/// the zero-latency rules floor and the repair of model output — produce the
/// same orthography.
enum SpanishOrthography {
    static let rules: [CleanupRule] = [
        // Before the symbol renderer below: it matches one token per trigger,
        // so it would read the "guion" of "guion bajo" as a dash and, in a
        // terminal, turn "guion bajo" into the flag "-bajo".
        CleanupRule(
            name: "es: spoken «guion bajo» joins an identifier",
            stage: .early,
            runsInTerminal: true,
            transform: { text, _ in joinSpokenUnderscore(text) }),
        // Spanish's spoken-symbol vocabulary, applied through the rules hook
        // rather than `LanguagePack.symbols` — see the note on the pack. Opted
        // into the terminal because that is where the renderer does its most
        // valuable work (flags and paths), and where its guards are strictest.
        CleanupRule(
            name: "es: spoken symbols render file names, identifiers and paths",
            stage: .early,
            runsInTerminal: true,
            transform: { text, context in
                SpokenSymbols.render(text, category: context.category, vocabulary: .spanish)
            }),
    ]

    // MARK: - Multi-word symbol names

    /// "max guion bajo reintentos" → max_reintentos.
    ///
    /// `SpokenSymbols` matches one token per trigger, and every Spanish symbol
    /// name for `_` is two words. The join guards are the same ones that
    /// pipeline uses — both neighbours must look like identifier parts and
    /// neither may be a function word — so "el guion bajo del documento" stays
    /// prose.
    static func joinSpokenUnderscore(_ text: String) -> String {
        guard text.range(of: #"(?i)gui[oó]n bajo"#, options: .regularExpression) != nil else {
            return text
        }
        let tokens = text.split(separator: " ").map(String.init)
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            let isTrigger = i + 1 < tokens.count
                && ["guion", "guión"].contains(tokens[i].lowercased())
                && tokens[i + 1].lowercased() == "bajo"
            if isTrigger, let left = out.last, isJoinable(left), i + 2 < tokens.count {
                let right = tokens[i + 2]
                if isJoinable(right) {
                    out[out.count - 1] = left + "_" + right
                    i += 3
                    continue
                }
            }
            out.append(tokens[i])
            i += 1
        }
        return out.joined(separator: " ")
    }

    private static func isJoinable(_ token: String) -> Bool {
        !token.isEmpty
            && token.allSatisfy { $0.isLetter || $0.isNumber || "._-".contains($0) }
            && !LanguagePack.spanishStopwords.contains(token.lowercased())
    }
}
