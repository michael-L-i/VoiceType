import Foundation

extension LanguagePack {
    /// Maltese (Malti).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `mela`, `allura`, `jiġifieri`, `taf`, `sewwa`, and `tajjeb` can
    ///   organize discourse or carry ordinary lexical meaning. `eħe` and
    ///   `mhm` can answer or confirm. None is a deterministic filler.
    /// - `mm` is documented as a Maltese filled pause, but it is also the
    ///   standard unit symbol for millimetres. Only the model may remove it
    ///   after using context. Code and terminal contexts protect even the
    ///   never-lexical fillers below because they may be literal identifiers.
    /// - Bare `punt` is a point, score, decimal point, or punctuation name.
    ///   It renders only when the context-aware symbol rule sees a known file
    ///   extension or terminal path; it is never a blind punctuation alias.
    /// - `fejn`, `meta`, `kif`, `kemm`, `għaliex`, and verb-initial yes/no
    ///   questions cannot be classified from the first token alone: the same
    ///   forms open subordinate clauses, statements, or exclamations. The
    ///   prompt handles them from context.
    /// - ASR research reports errors around silent `għ`, aspirated stops,
    ///   connected-word segmentation, and verb morphology. Blind spelling
    ///   substitutions would change meaning, so no guessed lexical repair
    ///   ships here.
    /// - English technical words and identifiers are normal in Maltese text.
    ///   They stay in their original spelling; the code renderer activates
    ///   only around explicit symbol triggers.
    /// - Few-shot examples remain empty. They were not evaluated with the
    ///   shared on-device model, and unevaluated examples risk leaking into
    ///   the user's transcript.
    static let maltese = LanguagePack(
        code: "mt",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // University of Malta spoken-corpus work explicitly annotates ee/em
        // as fillers. Emm is the common lengthened transcription; qq is a
        // corpus hesitation code. `mm` is excluded because it is a unit.
        fillers: ["ee", "em", "emm", "qq"],
        // Kept empty deliberately. The custom rule in MalteseSymbols.swift is
        // context-safe in terminals and also repairs model output, while this
        // flat table would run only in the rules floor and replace blindly.
        spokenPunctuation: [:],
        // Only interrogative pronouns and fixed "what is/are" forms that do
        // not also serve as ordinary subordinators.
        questionPrefixWords: [
            "min", "xiex", "liema",
            "x'inhu", "x’inhu", "x'inhi", "x’inhi",
            "x'inhuma", "x’inhuma",
        ],
        questionSuffixParticles: [],
        stopwords: LanguagePack.malteseStopwords,
        // The shared English-only integrity test requires this field to stay
        // nil. Maltese invokes its own vocabulary from a CleanupRule instead,
        // which also means model output receives the same repair.
        symbols: nil,
        prompt: .maltese,
        rules: MalteseCleanupRules.all,
        casingLocaleIdentifier: "mt_MT",
        spokenSymbolWords: SpokenSymbolVocabulary.malteseSpokenWords,
        modelLeadInPatterns: [
            #"(?i)^\s*(?:żgur|tajjeb|sew|mela)[,!.]+\s*(?:hawn(?:hekk)?\s+(?:hu|hi|huma))?[^\n:]{0,70}:\s+"#,
            #"(?i)^\s*(?:hawn(?:hekk)?\s+(?:hu|hi|huma)\s+)?[^\n:]{0,50}(?:traskrizzjoni|dettatura|test)\s+(?:imnaddaf|ikkoreġut|irranġat)[^\n:]{0,20}:\s+"#,
        ])

    /// Function words that neither prove content survived the model nor make
    /// safe identifier components. Discourse and correction markers belong
    /// here without being deleted from the transcript.
    static let malteseStopwords: Set<String> = [
        "il", "l", "iċ", "id", "in", "ir", "is", "it", "ix", "iż",
        "u", "jew", "imma", "li", "xi", "kull", "ebda",
        "ta", "ta’", "ma", "ma’", "bi", "fi", "sa", "fuq", "għal", "minn",
        "lejn", "bejn", "bħal", "bħala", "mal", "tal", "bil", "fil",
        "għall", "mill", "lill",
        "jien", "inti", "int", "hu", "hi", "aħna", "intom", "huma",
        "dan", "din", "dawn", "dak", "dik", "dawk", "hemm", "hawn",
        "huwa", "hija", "kien", "kienet", "kienu", "tkun", "jkun",
        "iva", "le", "mela", "allura", "jiġifieri", "taf", "sewwa", "tajjeb",
        // Self-correction markers can disappear with the retracted phrase, so
        // the faithfulness guard must not treat them as missing content.
        "mhux", "stenna", "anzi", "skużi",
    ]
}
