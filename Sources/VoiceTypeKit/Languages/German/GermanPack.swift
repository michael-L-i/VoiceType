import Foundation

extension LanguagePack {
    /// German (de; Germany/Austria/Switzerland all key on "de").
    ///
    /// The pack's split of labour: `GermanRules` owns everything that is
    /// *always* right in German — spacing, typography, closed-class capitals —
    /// and `GermanPrompt` owns everything that needs meaning. The line between
    /// them is the whole design, so the judgment calls are worth spelling out.
    ///
    /// **Ambiguity policy — what this pack deliberately does NOT do:**
    ///
    /// - **No modal particle is a filler.** "doch", "ja", "mal", "halt",
    ///   "eben", "denn", "wohl", "schon", "bloß", "eh", "gell", "ne" all look
    ///   like verbal tics and are not: they carry the speaker's attitude
    ///   ("Komm doch mal her" is not "Komm her"). Only the pure hesitation
    ///   vowels below are removed. The rest is named in the prompt as
    ///   keep-words, because a model told to strip fillers will eat them.
    ///   "eh" in particular is a real word in Austrian and southern German
    ///   ("das ist eh gut" = "that's fine anyway"), so it stays even though
    ///   English's cognate "er"/"uh" is a filler.
    /// - **"Punkt" and "Komma" are never rendered as marks unconditionally.**
    ///   Both are everyday nouns — *auf den Punkt*, *Punkt zwölf*, *der
    ///   springende Punkt*, *ein Komma setzen*, *drei Komma eins*. They reach
    ///   the symbol renderer and the decimal rule instead, where both
    ///   neighbours must look like code or digits before anything happens.
    ///   This is why German ships no `spokenPunctuation` table: that table
    ///   replaces unconditionally, which is right for Chinese 句号 and wrong
    ///   for a German noun.
    /// - **No noun capitalization in code.** German capitalizes every noun, and
    ///   no regex can find them — that is the model's job. The one closed class
    ///   that *is* safe (weekdays, months, feast days) is a rule; everything
    ///   else is prompt guidance. Attempting more deterministically would
    ///   capitalize verbs and adjectives, which is worse than leaving them.
    /// - **No ss → ß repair.** The rule depends on vowel length ("Straße" vs.
    ///   "dass"), which needs a lexicon; and Swiss German writes ss throughout,
    ///   so a blind conversion would be wrong for a whole country.
    /// - **No das/dass, seit/seid or compound re-joining.** German ASR's most
    ///   frequent errors, and every one of them needs syntax. Stated in the
    ///   prompt; never guessed at deterministically.
    /// - **No thousands separator or number-range dash.** "1.000" and "10–20"
    ///   are correct German, but a rule cannot tell them from a version string,
    ///   an IP address or a phone number.
    static let german = LanguagePack(
        code: "de",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Pure hesitation sounds only — no word on this list has a meaning in
        // any register of German. See the ambiguity policy above for the long
        // list of lookalikes that are deliberately absent.
        fillers: [
            "äh", "ähh", "ähm", "ähmm", "ähem", "öh", "öhm",
            "hm", "hmm", "hmmm", "mhm", "mh", "mmh", "ehm",
        ],
        // Empty by design: see the note on "Punkt"/"Komma" above. German's
        // spoken marks are rendered by `GermanRules.spokenPunctuation`, which
        // is word-bounded and restricted to names that only ever name a mark.
        spokenPunctuation: [:],
        // German main clauses are verb-second, so a finite verb in first
        // position is a question (or an imperative — and the imperative forms
        // "mach", "geh", "sei", "gib" are deliberately absent). Second-person
        // forms are the strongest signal of all: "hast", "kannst", "willst"
        // cannot open a statement.
        questionPrefixWords: [
            // Interrogatives.
            "was", "wer", "wen", "wem", "wessen", "wann", "wo", "wohin",
            "woher", "warum", "wieso", "weshalb", "weswegen", "wie", "wieviel",
            "welche", "welcher", "welches", "welchen", "welchem",
            "womit", "wofür", "worum", "worüber", "wodurch", "wovon", "wozu",
            "worauf", "worin", "wonach", "wobei", "inwiefern", "inwieweit",
            // sein / haben / werden.
            "ist", "sind", "war", "waren", "warst", "wart", "bin", "bist", "seid",
            "hat", "haben", "hast", "habt", "hatte", "hatten", "hattest",
            "wird", "werden", "wirst", "werdet", "wurde", "wurden",
            // Modals.
            "kann", "kannst", "können", "könnt", "könnte", "könnten",
            "soll", "sollst", "sollen", "sollt", "sollte", "sollten",
            "muss", "musst", "müssen", "müsst", "müsste", "müssten",
            "darf", "darfst", "dürfen", "dürft", "dürfte", "dürften",
            "will", "willst", "wollen", "wollt",
            "magst", "mögen", "möchtest", "möchten", "möchtet",
            // Subjunctive openers, which are almost always questions.
            "wäre", "wären", "hätte", "hätten", "würde", "würden", "würdest",
            // High-frequency finite verbs that open yes/no questions.
            "gibt", "geht", "weißt", "wisst", "kennst", "kennt", "siehst",
            "brauchst", "braucht", "denkst", "meinst", "glaubst", "findest",
            "funktioniert", "stimmt", "passt", "klappt",
        ],
        // German tag questions. Matched with `hasSuffix` on the whole text, not
        // on a word boundary, so only tags with no common word-final homograph
        // qualify: "ne" would fire on "keine"/"Sonne" and "gell" on any word
        // ending in -gell, so both are left out. "richtig" is left out for a
        // different reason — "das ist richtig" is a statement at least as often
        // as "…, richtig?" is a tag.
        questionSuffixParticles: ["oder", "nicht wahr", "stimmt's", "stimmt’s"],
        stopwords: LanguagePack.germanStopwords,
        // `symbols` stays nil on purpose. German's spoken-symbol vocabulary
        // lives in `SpokenSymbolVocabulary.german` and is driven from
        // `GermanRules.spokenSymbols`, because the pack field would also claim
        // the paren path — and German says "Klammer auf", the noun before the
        // direction, which the shared renderer cannot express.
        symbols: nil,
        // German's "ich" is lowercase, unlike English "I".
        capitalizedStandalonePronoun: nil,
        rules: GermanRules.all,
        spokenSymbolWords: LanguagePack.germanSpokenSymbolWords,
        // Compounding means German packs more meaning into fewer words than
        // English, but cleanup removes the same *kind* of words (hesitations,
        // retracted attempts), so the retention ratios still hold. Default.
        guardPolicy: .default,
        modelLeadInPatterns: [
            #"(?i)^\s*(klar|natürlich|gerne|sicher|selbstverständlich)[,!.]+\s*hier ist[^\n:]{0,80}:\s+"#,
            #"(?i)^\s*hier ist (der|die|das)[^\n:]{0,80}:\s+"#,
            #"(?i)^\s*(bereinigter|korrigierter|überarbeiteter|aufgeräumter) text:\s+"#,
        ])

    /// German function words: the faithfulness guard skips them when probing
    /// whether a dictation's opening survived, and the symbol renderer refuses
    /// to join them into an identifier ("ich will das unterstreichen" must
    /// never become "will_unterstreichen").
    ///
    /// Declared separately because `SpokenSymbolVocabulary.german` builds on it
    /// before `LanguagePack.german` itself finishes initializing.
    static let germanStopwords: Set<String> = [
        "der", "die", "das", "den", "dem", "des",
        "ein", "eine", "einen", "einem", "einer", "eines",
        "und", "oder", "aber", "denn", "sondern", "sowie", "als", "wie",
        "wenn", "weil", "dass", "ob", "damit",
        "ich", "du", "er", "sie", "es", "wir", "ihr", "man",
        "mich", "dich", "sich", "uns", "euch", "mir", "dir", "ihm", "ihnen",
        "mein", "meine", "dein", "deine", "sein", "seine", "unser", "unsere",
        "ist", "sind", "war", "waren", "bin", "bist", "seid", "sei",
        "hat", "haben", "hast", "habt", "hatte", "hatten",
        "wird", "werden", "wurde", "wurden",
        "kann", "können", "muss", "müssen", "soll", "sollen",
        "will", "wollen", "darf", "dürfen",
        "in", "im", "an", "am", "auf", "aus", "bei", "mit", "nach", "von",
        "vom", "vor", "zu", "zum", "zur", "über", "unter", "für", "um",
        "durch", "ohne", "gegen", "bis", "seit",
        "nicht", "kein", "keine", "nur", "noch", "schon", "auch", "sehr",
        "so", "dann", "da", "hier", "dort", "mehr", "ganz", "etwas",
        "ja", "nein", "okay", "ok", "genau", "eben", "halt", "doch", "mal",
        // Self-correction markers: legitimately removed along with the words
        // they retract, so they prove nothing about the opening.
        "quatsch", "moment", "warte", "also", "eigentlich", "entschuldigung",
    ]

    /// The words German uses to name a symbol out loud. The faithfulness guard
    /// discounts them when counting content, so a heavily dictated identifier
    /// ("max Unterstrich retries") does not read as a summary. Replaces the
    /// inherited English default, which named none of German's words.
    static let germanSpokenSymbolWords: Set<String> = [
        "punkt", "komma", "strich", "bindestrich", "gedankenstrich",
        "unterstrich", "schrägstrich", "backslash", "tilde", "doppelpunkt",
        "semikolon", "strichpunkt", "klammer", "klammern", "auf", "zu",
        "runde", "eckige", "geschweifte", "spitze", "anführungszeichen",
        "zitat", "at", "ätt", "prozent", "raute", "stern", "sternchen",
        "dollar", "euro", "minus", "plus", "gleich", "gleichheitszeichen",
        "fragezeichen", "ausrufezeichen", "rufzeichen", "groß", "klein",
        "großbuchstabe", "kleinbuchstabe", "neue", "neuer", "nächste",
        "zeile", "absatz", "zeilenumbruch", "leerzeichen", "tabulator",
        "kaufmännisches", "und", "zeichen",
    ]
}
