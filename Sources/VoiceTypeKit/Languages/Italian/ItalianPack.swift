import Foundation

extension LanguagePack {
    /// Italian (it).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `eh`, `beh`/`be'`, `boh`, `mah`, `ah`: they look like hesitations but
    ///   every one of them is a meaningful interjection in Italian ("eh sì",
    ///   "boh" = "no idea", "mah" = "who knows"). Only breath-noises with no
    ///   lexical reading are removed deterministically.
    /// - `allora`, `cioè`, `diciamo`, `tipo`, `praticamente`, `insomma`,
    ///   `niente`, `quindi`, `vabbè`: the classic Italian *segnali discorsivi*.
    ///   They are filler about as often as they are content ("allora partiamo",
    ///   "cioè, il punto è questo" vs. "un discorso, cioè, lungo"). Judging that
    ///   needs meaning, so it lives in the prompt, not in a blind rule.
    /// - Bare `punto` and `virgola` as spoken punctuation. Both are everyday
    ///   nouns ("il punto è che…", "sposta la virgola"), so unlike Chinese 句号
    ///   they cannot be replaced unconditionally. Only the *compound* names
    ///   ("punto interrogativo", "punto e virgola", …) are rendered — see
    ///   `ItalianSymbols.swift` — and the ordinary noun survives untouched.
    /// - `due punti` for `:`. Apple's Italian dictation renders it, but "ha
    ///   segnato due punti" is ordinary prose and the rule cannot tell. Left to
    ///   the LLM, which can.
    /// - `e commerciale` for `&`: "il settore industriale e commerciale" is a
    ///   real Italian phrase. Same reasoning.
    /// - Unaccented forms that are also words: `pero` (pear tree), `meta`
    ///   (goal), `papa` (pope), `sara` (a name), `li`, `la`, `si`, `ne`, `se`,
    ///   `da`, `te`, `e`. Only spellings that exist *solely* as the accented
    ///   word are restored — see `italianAccentFixes`.
    /// - Lowercasing nationality/language adjectives (`francese`, `inglese`,
    ///   `tedesco`), even though Italian writes them lowercase: each is also a
    ///   common Italian surname. The prompt says it; the rules don't guess.
    ///
    /// Trade-off accepted (documented, not accidental): the question heuristic
    /// keeps `come`, `quando` and `dove`, which also open subordinate clauses
    /// ("Quando arrivo ti chiamo"). Italian yes/no questions don't invert, so
    /// dropping them would cost the three commonest spoken questions ("Come
    /// stai", "Quando parti", "Dove sei"). The heuristic only fires when the
    /// text carries no terminal punctuation at all, which bounds the damage.
    static let italian = LanguagePack(
        code: "it",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Breath noises only. Every one of these is unpronounceable as an
        // Italian word, so removing them can never delete content.
        fillers: ["ehm", "ehmm", "ehem", "uhm", "uhmm", "hmm", "mmm", "mmh"],
        // Empty by design: "punto"/"virgola" are everyday nouns, so the flat
        // unconditional table is the wrong tool. `italianRules` renders the
        // compound names in positions where they cannot be prose.
        spokenPunctuation: [:],
        // Interrogative openers. Verbs are absent on purpose: Italian yes/no
        // questions are marked by intonation alone ("Vieni domani?"), so a
        // verb-initial probe would fire on every imperative and inversion-free
        // statement. "che" is excluded too — as a first word it opens
        // exclamations ("Che bello!") as often as questions.
        questionPrefixWords: [
            "cosa", "cos'è", "cos'era", "chi", "perché",
            "quando", "quand'è", "dove", "dov'è", "dov'era",
            "come", "com'è", "com'era",
            "quale", "quali", "qual",
            "quanto", "quanta", "quanti", "quante", "quant'è",
        ],
        questionSuffixParticles: [],
        stopwords: LanguagePack.italianStopwords,
        rules: LanguagePack.italianRules,
        spokenSymbolWords: LanguagePack.italianSpokenSymbolWords,
        // Italian is not more compact than English — if anything the article +
        // preposition machinery makes it wordier — so the English-calibrated
        // guard ratios transfer unchanged.
        modelLeadInPatterns: LanguagePack.italianLeadInPatterns)

    /// Italian's deterministic fixes, in the order they run. Declared here
    /// rather than next to the rules themselves because ordering *is* the
    /// pack's decision: `ItalianRules.swift` explains why this sequence and no
    /// other.
    static let italianRules: [CleanupRule] = [
        italianAccentRule,
        italianApostropheRule,
        italianEllipsisRule,
        italianLeadingLineBreakRule,
    ] + italianSymbolRules + [
        italianDecimalCommaRule,
        italianInnerSpacingRule,
        italianDateCaseRule,
        italianLineBreakRule,
        italianFinalSpacingRule,
    ]

    /// Function words that prove nothing about whether a dictation's opening
    /// survived. Italian packs a lot of grammar into short words (articulated
    /// prepositions, clitics), so this list is longer than English's by
    /// necessity rather than by ambition.
    static let italianStopwords: Set<String> = [
        // Articles and articulated prepositions.
        "il", "lo", "la", "i", "gli", "le", "un", "uno", "una",
        "di", "del", "dello", "della", "dei", "degli", "delle",
        "a", "al", "allo", "alla", "ai", "agli", "alle",
        "da", "dal", "dallo", "dalla", "dai", "dagli", "dalle",
        "in", "nel", "nello", "nella", "nei", "negli", "nelle",
        "con", "col", "su", "sul", "sullo", "sulla", "sui", "sugli", "sulle",
        "per", "tra", "fra",
        // Conjunctions and connectives.
        "e", "ed", "o", "od", "oppure", "ma", "però", "anche", "pure",
        "se", "che", "come", "quando", "mentre", "perché", "poi", "quindi",
        "allora", "così", "ecco", "cioè", "insomma", "invece", "anzi",
        // Pronouns and determiners.
        "io", "tu", "lui", "lei", "noi", "voi", "loro",
        "mi", "ti", "si", "ci", "vi", "ne", "me", "te", "sé",
        "questo", "questa", "questi", "queste",
        "quello", "quella", "quelli", "quelle", "ciò",
        // The auxiliaries and the handful of verbs that carry no topic.
        "è", "sono", "sei", "siamo", "siete", "era", "erano", "essere",
        "ho", "hai", "ha", "abbiamo", "avete", "hanno", "aveva", "avere",
        "fa", "fare", "va", "andare",
        // Adverbs and discourse particles.
        "non", "sì", "no", "più", "meno", "molto", "poco", "già", "ancora",
        "sempre", "mai", "solo", "proprio", "davvero", "bene", "ok", "okay",
        // Self-correction markers: legitimately removed along with the words
        // they retract, so they prove nothing about the opening.
        "scusa", "scusate", "aspetta", "volevo", "dire",
    ]

    /// Words that name a character out loud and legitimately collapse into one
    /// symbol during cleanup, so the faithfulness guard doesn't read a dictated
    /// identifier as a summary. Deliberately excludes the everyday words that
    /// appear *inside* those names — "aperta", "chiusa", "basso", "nuova",
    /// "capo", "spazio", "due" — because discounting them would blunt the guard
    /// on ordinary prose.
    static let italianSpokenSymbolWords: Set<String> = [
        "punto", "punti", "puntini", "sospensivi", "virgola", "virgolette",
        "interrogativo", "esclamativo", "trattino", "barra", "rovesciata",
        "verticale", "chiocciola", "parentesi", "quadra", "graffa", "tonda",
        "asterisco", "cancelletto", "apostrofo", "commerciale", "maiuscolo",
        "minuscolo", "tabulazione",
        // The English symbol words Italian speakers borrow wholesale when
        // dictating code.
        "underscore", "slash", "dot", "backslash", "hashtag",
    ]

    /// Conversational lead-ins the model emits *in Italian* when it ignores the
    /// "output only the transcript" instruction. Added to the shared English
    /// patterns; both must end in a colon on the first line, which is what
    /// keeps ordinary dictated prose ("Ecco il piano: comprare il latte") safe.
    static let italianLeadInPatterns: [String] = [
        // Opener-led: "Certo, ecco il testo:", "Va bene, ecco qui:".
        #"(?i)^\s*(?:certo|certamente|va bene|perfetto|d['’]accordo|ok|okay)[,!.]+\s*(?:ecco\b)?[^\n:]{0,80}:\s+"#,
        // Named-output: "Ecco la trascrizione ripulita:", "Il testo corretto:".
        #"(?i)^\s*(?:ecco\b|il\b|la\b)?[^\n:]{0,60}(?:trascrizione|dettatura|testo (?:pulito|ripulito|corretto|sistemato)|versione (?:pulita|ripulita|corretta))[^\n:]{0,30}:\s+"#,
    ]
}
