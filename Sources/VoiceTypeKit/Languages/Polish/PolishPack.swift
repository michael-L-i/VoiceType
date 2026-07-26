import Foundation

extension LanguagePack {
    /// Polish (pl-PL).
    ///
    /// Polish punctuation is *grammatical*, not prosodic: a missing comma
    /// before `że` or `który` reads as an error to every native reader, and no
    /// transcriber puts them in. That is where most of this pack's effort goes
    /// (see `PolishRules.swift`), alongside the typographic conventions that
    /// are always right — „…” quotation marks, the spaced dash `–`, the single
    /// `…` character.
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - **`no`** — the most common Polish discourse particle, and content far
    ///   more often than not: it means "yeah", "well", "go on", "right?"
    ///   (`no dobra`, `no i co`, `no nie?`). Never a deterministic filler.
    ///   Same for `wiesz`, `znaczy`, `jakby`, `w sumie`, `po prostu`,
    ///   `prawda` — all real words. The prompt asks the model to drop them
    ///   only when context shows they carry no meaning.
    /// - **`ee` / `aaa`** — look like hesitation vowels but are interjections
    ///   with meaning (`ee, nie ma mowy` = "nah, no way"; `aaa, rozumiem` =
    ///   "ah, I see"). Only `yyy`/`eee`/`mmm`-style runs are pure disfluency.
    /// - **`yhy` / `mhm` / `aha`** — these are *agreement*, not hesitation.
    ///   Removing them deletes the speaker's "yes".
    /// - **`prawda?` as a question tag** — real ("…, prawda?"), but `to
    ///   prawda` is a plain statement, so `hasSuffix` cannot tell them apart.
    ///   No question suffix particles ship.
    /// - **Decimal comma and the space thousands separator** (`12 345,67`) —
    ///   correct Polish, but rewriting digits blind would break version
    ///   numbers, ports, and IDs (`Swift 5.9`, `3.14` in embedded English).
    ///   Left to the LLM, which can see the surrounding words.
    /// - **`%` spacing** — PWN's orthotypographic tradition writes `50%`, the
    ///   post-2020 European metrology norm (and GUM) writes `50 %`. A rule
    ///   with two live standards is not "always right", so neither is applied.
    /// - **The single-letter-conjunction non-breaking space** (`i`, `a`, `w`,
    ///   `z` must not end a printed line) — genuinely always right in Polish
    ///   typesetting, and deliberately skipped: VoiceType pastes into arbitrary
    ///   apps, where a U+00A0 the user never asked for breaks search, grep, and
    ///   code. Typesetting is not dictation.
    ///
    /// Both spoken-punctuation and spoken-symbol rendering are `CleanupRule`s
    /// here rather than the declarative `spokenPunctuation` /
    /// `SpokenSymbolVocabulary` fields, and for the same reason: those fields
    /// answer "which words name a mark?", while Polish needs "which words name
    /// a mark *here*?". `kropka` and `przecinek` are everyday nouns (`kropka
    /// nad i`, `i kropka`, `trzy przecinek czternaście` = 3,14), and the
    /// spoken-punctuation table replaces unconditionally — and, for a Latin
    /// pack, only in the rules path, never over model output. The rules check
    /// their neighbors and run in both paths. See `PolishRules.swift` and
    /// `PolishSymbols.swift`.
    static let polish = LanguagePack(
        code: "pl",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Pure hesitation runs only. Longer variants ("yyyy", "eeee") are
        // caught by the elongation rule, which the fixed-string matcher here
        // cannot express.
        fillers: ["yyy", "yy", "eee", "mmm", "hmm", "hm", "ym", "eem"],
        spokenPunctuation: [:],
        // Interrogative words, fully inflected — Polish questions are marked by
        // the opener, not by inversion. "czy" is the explicit yes/no particle
        // and is unambiguous sentence-initially (mid-sentence it means "or",
        // which the first-token-only probe never sees).
        questionPrefixWords: [
            "co", "czego", "czemu", "czym", "kto", "kogo", "komu", "kim",
            "kiedy", "odkąd", "dokąd", "skąd", "gdzie", "którędy",
            "dlaczego", "czyj", "czyja", "czyje", "czyim", "czyich",
            "jak", "jaki", "jaka", "jakie", "jacy", "jakiego", "jakiej",
            "jakim", "jakich", "jaką", "jakimi",
            "który", "która", "które", "którzy", "którego", "której",
            "któremu", "którym", "którą", "których", "którymi",
            "ile", "ilu", "iloma", "czy",
        ],
        questionSuffixParticles: [],
        stopwords: LanguagePack.polishStopwords,
        prompt: .polish,
        rules: LanguagePack.polishRules,
        spokenSymbolWords: LanguagePack.polishSpokenSymbolWords,
        // The guard's English-calibrated ratios are kept. Polish is pro-drop
        // and inflectional, so a clause carries fewer tokens than its English
        // equivalent — but the guard compares cleaned against *raw Polish*, so
        // the ratio transfers and there is nothing to recalibrate.
        modelLeadInPatterns: [
            // "Jasne, oto oczyszczony tekst:" — the Polish shape of the
            // conversational wrapper the shared English patterns catch.
            #"(?i)^\s*(?:jasne|oczywiście|dobrze|dobra|okej|ok|proszę bardzo|pewnie)[,!.]+\s*(?:oto\b)?[^\n:]{0,80}:\s+"#,
            // "Oto poprawiona wersja:", "Uporządkowana transkrypcja:".
            #"(?i)^\s*(?:oto\b|to\b)?[^\n:]{0,60}(?:transkryp\w*|dyktand\w*|oczyszczon\w*|poprawion\w*|uporządkowan\w*|popraw\w*\s+wersj\w*)[^\n:]{0,30}:\s+"#,
        ])

    /// Polish function words. They feed two conservative checks: the
    /// faithfulness guard skips them when probing whether a dictation's
    /// opening survived, and the spoken-symbol renderer refuses to join them
    /// into an identifier ("chcę to podkreślnik" must never fuse).
    ///
    /// Polish is pro-drop and heavily inflected, so this list carries the
    /// inflected forms that actually appear in speech rather than dictionary
    /// headwords — `mnie`/`mi`/`mną` all show up where English has one "me".
    static let polishStopwords: Set<String> = [
        // Conjunctions and particles
        "i", "a", "ale", "lecz", "oraz", "lub", "albo", "ani", "bądź", "czy",
        "że", "iż", "bo", "gdyż", "ponieważ", "więc", "też", "także", "również",
        "jednak", "natomiast", "zaś", "aby", "żeby", "by", "jeśli", "jeżeli",
        "gdy", "kiedy", "jak", "niż", "niech", "nie", "tak", "no", "już",
        "jeszcze", "tylko", "właśnie", "nawet", "chyba", "może", "bardzo",
        "trochę", "też", "znowu", "przecież", "wreszcie", "raczej",
        // Prepositions
        "w", "we", "z", "ze", "na", "do", "od", "ode", "po", "za", "przy",
        "przez", "dla", "o", "u", "ku", "nad", "nade", "pod", "pode", "przed",
        "przede", "między", "bez", "wobec", "wśród", "obok", "koło", "około",
        // Pronouns and determiners
        "ja", "ty", "on", "ona", "ono", "my", "wy", "oni", "one",
        "mnie", "mi", "mną", "ciebie", "cię", "tobie", "tobą",
        "go", "jego", "jemu", "mu", "nim", "niego", "jej", "ją", "nią", "niej",
        "nas", "nam", "nami", "was", "wam", "wami", "ich", "im", "nimi", "nich",
        "się", "sobie", "sobą", "swój", "swoje", "swoją", "mój", "moja", "moje",
        "twój", "twoja", "twoje", "nasz", "nasza", "nasze", "wasz",
        "ten", "ta", "to", "te", "ci", "tego", "tej", "tym", "temu", "tych",
        "tamten", "tamta", "tamto", "taki", "taka", "takie",
        "tu", "tutaj", "tam", "wtedy", "teraz", "potem",
        // Copulas and high-frequency verbs
        "jest", "są", "był", "była", "było", "byli", "były", "będzie", "będą",
        "być", "jestem", "jesteś", "jesteśmy", "jesteście",
        "mam", "masz", "ma", "mamy", "macie", "mają", "miał", "miała",
        // Self-correction markers: legitimately removed along with the words
        // they retract, so they prove nothing about the opening.
        "znaczy", "przepraszam", "czekaj", "właściwie", "sorry",
    ]

    /// Words that name a symbol out loud in Polish. The faithfulness guard
    /// discounts them when counting content, so a heavily-dictated identifier
    /// ("maks podkreślnik prób") doesn't read as a summary. Replaces the
    /// English default wholesale — "dot" and "paren" mean nothing here.
    static let polishSpokenSymbolWords: Set<String> = [
        "kropka", "przecinek", "myślnik", "łącznik", "podkreślnik",
        "podkreślenie", "ukośnik", "tylda", "dwukropek", "średnik",
        "wielokropek", "gwiazdka", "małpa", "małpka", "nawias", "nawiasy",
        "kwadratowy", "kwadratowe", "klamrowy", "cudzysłów", "wykrzyknik",
        "pytajnik", "apostrof", "krzyżyk", "płotek", "daszek", "dolar",
        "otwórz", "zamknij", "otwierający", "zamykający", "lewy", "prawy",
        "akapit", "spacja", "enter", "wiersz",
    ]
}
