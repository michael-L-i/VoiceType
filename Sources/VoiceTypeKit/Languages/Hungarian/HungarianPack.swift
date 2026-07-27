import Foundation

extension LanguagePack {
    /// Hungarian (Magyar).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `hát`, `izé`, `szóval`, `ugye`, `amúgy`, `tulajdonképpen`, `aha`:
    ///   all can organize discourse or carry ordinary lexical meaning. The
    ///   deterministic pass keeps them; the LLM may remove one only when
    ///   context makes it a throwaway hesitation.
    /// - A single `ö` or `ő`: either can be the dictated name of a Hungarian
    ///   letter. Only repeated hesitation spellings are blind-safe fillers.
    /// - `pont` and `vessző`: both are ordinary nouns as well as dictation
    ///   commands (`pont` also occurs in decimals, times, and technical prose).
    ///   Explicit names such as `kérdőjel` render deterministically; these two
    ///   ambiguous words need the prompt's context.
    /// - Yes/no questions have no mandatory written particle, and Hungarian
    ///   word order is flexible. Only strongly interrogative opening words
    ///   feed the question heuristic; the LLM handles intonation-dependent and
    ///   embedded questions.
    /// - Compound-word, suffix, accent, and proper-name repair is never done
    ///   by a lexical replacement table. Hungarian morphology makes a plausible
    ///   blind rewrite especially likely to change meaning.
    /// - Thousands separators, fully numeric date styles, dashes, and quote
    ///   punctuation have valid context-dependent variants. The rules preserve
    ///   valid input rather than forcing one house style.
    ///
    /// The shared integrity suite reserves `symbols` for English. Hungarian's
    /// context-guarded vocabulary therefore runs from a pack-local CleanupRule;
    /// this also repairs model output and is safer than unconditional symbols.
    static let hungarian = LanguagePack(
        code: "hu",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Repeated non-lexical hesitation sounds only. Spellings seen from
        // recognizers vary between short/long ö and an added m/h sound.
        fillers: [
            "öö", "ööö", "öööö", "őő", "őőő", "őőőő",
            "öhm", "ööhm", "őhm", "őőhm", "hmm", "mmm",
        ],
        // Empty by design. Hungarian uses a whole-token CleanupRule below so
        // inflected content such as "kérdőjelet" is not corrupted by the
        // shared renderer's substring replacement.
        spokenPunctuation: [:],
        questionPrefixWords: [
            "miért", "hogyan", "melyik", "milyen", "mennyi", "hány",
            "hányadik", "hová", "hova", "honnan", "merre", "meddig",
            "mettől", "vajon",
        ],
        questionSuffixParticles: [],
        stopwords: LanguagePack.hungarianStopwords,
        prompt: .hungarian,
        rules: HungarianCleanupRules.all,
        spokenSymbolWords: HungarianSpokenSymbols.spokenWords,
        modelLeadInPatterns: [
            #"(?i)^\s*(?:rendben|persze|természetesen)[,!.]+\s*(?:itt (?:van|a)\b)?[^\n:]{0,80}:\s+"#,
            #"(?i)^\s*(?:itt (?:van|a)\s+)?[^\n:]{0,60}(?:átirat|diktálás|megtisztított|javított|kijavított)[^\n:]{0,30}:\s+"#,
        ])

    /// Function words are weak evidence that a model preserved the opening,
    /// and unsafe neighbors for identifier joins.
    static let hungarianStopwords: Set<String> = [
        "a", "az", "egy", "és", "vagy", "de", "hogy", "ha", "mert", "mint",
        "is", "sem", "se", "nem", "igen", "meg", "el", "fel", "le", "ki", "be",
        "át", "rá", "ide", "oda", "itt", "ott", "majd", "már", "még", "csak",
        "ez", "azt", "ezt", "ami", "aki", "amely", "minden", "valami",
        "én", "te", "ő", "mi", "ti", "ők", "nekem", "neked", "neki", "nekünk",
        "van", "volt", "lesz", "lenne", "kell", "lehet", "tud", "fog",
        "hát", "izé", "szóval", "ugye", "amúgy", "tulajdonképpen", "aha",
        // Self-correction markers may legitimately disappear with a retraction.
        "pontosabban", "illetve", "bocsánat", "vagyis", "inkább",
    ]
}
