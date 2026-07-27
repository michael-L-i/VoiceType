import Foundation

extension LanguagePack {
    /// Czech (cs-CZ).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `no`, `jako`, `prostě`, `vlastně`, `tedy`, `takže`, `jakoby`, `víš`
    ///   and `řekněme` can all organize real meaning. They are never blind
    ///   fillers; the model may remove one only when context proves it is
    ///   throwaway. `hm`, `mhm`, `aha` and `jo` are also kept because they can
    ///   express doubt, realization, or agreement rather than hesitation.
    /// - `tečka` and `čárka` are ordinary nouns, and `čárka` is spoken inside
    ///   every Czech decimal number. `spokenPunctuation` is therefore empty.
    ///   A guarded rule renders `tečka` only before a known file extension and
    ///   uses a technical vocabulary for identifiers, e-mail, flags, and paths.
    /// - Digit grouping, dates, currency, units, and percentages have
    ///   context-sensitive alternatives. `1 234` is a number but `1234` may be
    ///   a year or identifier; `5. 6. 2026`, `05.06.2026`, and `2026-06-05`
    ///   are all legitimate in their respective contexts; `100 Kč` is an
    ///   amount while `100Kč` is adjectival; `10 %` and `10%` likewise differ
    ///   in meaning. The rules preserve the speaker/transcriber's choice.
    /// - Apostrophes are rare in Czech, are wrong in enclitic forms such as
    ///   `žes`, but are valid in foreign names and occasional poetic elision.
    ///   No blind apostrophe or elision rewrite ships.
    /// - A hyphen, an en dash, and a mathematical minus are different marks,
    ///   but a raw ASCII `-` does not reveal which one the speaker meant.
    ///   Outside a terminal/code context this judgment stays with the model.
    /// - Colloquial Czech is not "bad ASR" to formalize away. The model prompt
    ///   explicitly preserves forms such as `bysme` when they are what the
    ///   speaker said, while allowing only contextually certain recognition
    ///   repairs. Research on Czech ASR identifies the formal/colloquial gap
    ///   itself as a major source of recognition error.
    ///
    /// Deterministic rules are in `CzechRules.swift`; prompt-only judgments are
    /// in `CzechPrompt.swift`. Orthographic sources are the Czech Language
    /// Institute's Internetová jazyková příručka (ÚJČ AV ČR): Uvozovky, Tři
    /// tečky, Členění čísel…, Zkratky čistě grafické, Značky…, Peněžní částky,
    /// Kalendářní datum, Apostrof, Spojovník, and Pomlčka.
    static let czech = LanguagePack(
        code: "cs",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Czech broadcast-conversation corpora distinguish vowel-like EE and
        // mumble-like MM pauses. Only unmistakable written EE/EHM hesitation
        // runs go here. Short `ee`, `em`, `hm`, and `mhm` can be a spelled
        // letter, acronym, or meaningful response and are deliberately absent.
        fillers: [
            "eee", "eeee", "ééé", "éééé", "ehm", "ehmm", "ehmmm", "eehm",
        ],
        spokenPunctuation: [:],
        // Czech has no general yes/no question particle or obligatory
        // inversion. Restrict the heuristic to interrogative pronouns and
        // adverbs; ordinary finite verbs ("je", "může", "chce") also open
        // statements and must not be listed.
        questionPrefixWords: CzechOrthography.questionPrefixWords,
        // Sentence-final `viď` and explicit `že ano/ne` are question tags.
        // Bare `ne` and `že` are much too common to use as suffix heuristics.
        questionSuffixParticles: ["viď", "že ano", "že ne"],
        stopwords: LanguagePack.czechStopwords,
        prompt: .czech,
        rules: LanguagePack.czechRules,
        // A masked abbreviation dot is still a real terminal period. This
        // prevents "… atd." from gaining a second dot before restoration.
        terminalMarks: LanguagePack.defaultTerminalMarks.union([
            CzechOrthography.abbreviationDot,
        ]),
        spokenSymbolWords: LanguagePack.czechSpokenSymbolWords,
        guardPolicy: .default,
        modelLeadInPatterns: LanguagePack.czechModelLeadInPatterns)

    /// Function words ignored by the faithfulness probe and refused as the
    /// neighbors of a dictated identifier join.
    static let czechStopwords: Set<String> = [
        // Conjunctions, particles, and common adverbs
        "a", "i", "ani", "ale", "avšak", "nebo", "anebo", "či", "protože",
        "že", "aby", "když", "jestli", "zda", "pokud", "tak", "tedy", "teda",
        "takže", "taky", "také", "jen", "jenom", "už", "ještě", "právě",
        "asi", "snad", "možná", "prostě", "vlastně", "jako", "jakoby", "no",
        "ano", "ne", "jo", "dobře", "teď", "pak", "potom", "tady", "tam",
        // Prepositions
        "v", "ve", "na", "do", "od", "z", "ze", "s", "se", "k", "ke", "u",
        "o", "po", "pro", "při", "před", "za", "nad", "pod", "mezi", "bez",
        "přes", "skrze", "kvůli", "díky",
        // Pronouns and determiners
        "já", "ty", "on", "ona", "ono", "my", "vy", "oni", "ony",
        "mě", "mně", "mi", "tebe", "tě", "ti", "ho", "jeho", "mu", "jej",
        "ji", "jí", "nás", "nám", "vás", "vám", "je", "jim", "se", "si",
        "svůj", "můj", "tvůj", "náš", "váš", "jejich",
        "ten", "ta", "to", "ti", "ty", "tento", "tahle", "toto", "nějaký",
        // Auxiliaries and high-frequency verbs
        "jsem", "jsi", "je", "jsme", "jste", "jsou", "byl", "byla", "bylo",
        "byli", "byly", "být", "budu", "budeš", "bude", "budeme", "budete",
        "budou", "by", "bych", "bys", "bychom", "byste",
        "mám", "máš", "má", "máme", "máte", "mají",
        // Self-correction markers can legitimately disappear with a repair.
        "oprava", "promiň", "promiňte", "pardon", "myslím", "totiž",
    ]

    /// Czech symbol names discounted by the faithfulness guard. Everyday
    /// punctuation nouns are included here because the guard only discounts
    /// them; actual rendering remains context- and neighbor-guarded.
    static let czechSpokenSymbolWords: Set<String> = [
        "tečka", "čárka", "dvojtečka", "středník", "trojtečka",
        "otazník", "vykřičník", "pomlčka", "spojovník", "mínus",
        "podtržítko", "lomítko", "zpětné", "tilda", "zavináč",
        "apostrof", "uvozovka", "uvozovky", "závorka", "závorku",
        "kulatá", "hranatá", "složená", "otevřená", "uzavřená",
        "levá", "pravá", "hvězdička", "křížek", "mřížka", "procento",
        "ampersand", "roura", "svislítko", "stříška", "dolar",
        "mezera", "tabulátor", "řádek", "odstavec", "velké", "malé",
    ]

    /// Czech conversational wrappers the small model may prepend despite the
    /// output-only contract. A bare "text" or "přepis" is not enough to match:
    /// both are ordinary dictation content.
    static let czechModelLeadInPatterns: [String] = [
        #"(?i)^\s*(?:jasně|samozřejmě|jistě|dobře|fajn|okej|ok|není problém)[,!.]+\s*(?:tady|zde)?[^\n:]{0,80}:\s+"#,
        #"(?i)^\s*(?:tady|zde)?[^\n:]{0,60}(?:vyčištěn\w*|upraven\w*|opraven\w*|přepis\w*|transkrip\w*)[^\n:]{0,30}:\s+"#,
    ]
}
