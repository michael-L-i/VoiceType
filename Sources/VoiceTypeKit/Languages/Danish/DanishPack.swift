import Foundation

extension LanguagePack {
    /// Danish (da-DK).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - altså, ligesom, sådan, jo, nå, ikke, okay, hm/hmm and mm/mhm can all
    ///   carry discourse meaning. Only the LLM may remove them, and only in
    ///   context; the deterministic filler set is limited to hesitation noise.
    /// - i is normally the preposition "in", while I is the second-person
    ///   plural pronoun. Blind capitalization would corrupt ordinary Danish,
    ///   so that distinction belongs to the LLM.
    /// - punktum, punkt, prik, komma and kolon can be words *about*
    ///   punctuation. The flat replacement table is therefore empty; a local
    ///   rule renders Apple's spoken commands while protecting obvious
    ///   metalinguistic uses.
    /// - Decimal and grouping marks are preserved, never guessed. A dot between
    ///   digits may be a thousands separator, version, date, time, or address;
    ///   only an existing Danish decimal comma is mechanically protected.
    /// - Danish compounds, genitives, dates, currency, quotation style, and
    ///   optional start commas require lexical or contextual judgment. The
    ///   prompt covers them; deterministic rewrites would change valid text.
    /// - The shared question heuristic sees only the first token of the whole
    ///   dictation. We do not add a rule for later questions because a rule
    ///   cannot observe `addPunctuation` and must not add marks when that option
    ///   is off.
    static let danish = LanguagePack(
        code: "da",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: [
            "øh", "øhh", "øhhh", "øhm", "øhmm",
            "æh", "æhh", "æhm",
        ],
        // Danish punctuation nouns are not safe for unconditional substring
        // replacement. `DanishCleanupRules` handles command-shaped uses and
        // also repairs model output.
        spokenPunctuation: [:],
        questionPrefixWords: [
            "hvad", "hvem", "hvornår", "hvor", "hvorfor", "hvordan",
            "hvilken", "hvilket", "hvilke", "hvorledes", "mon",
            "er", "var", "bliver", "blev",
            "har", "havde", "får", "fik",
            "kan", "kunne", "skal", "skulle", "vil", "ville",
            "må", "måtte", "bør", "burde",
            "kommer", "findes",
        ],
        questionSuffixParticles: [],
        stopwords: LanguagePack.danishStopwords,
        prompt: .none,
        rules: DanishCleanupRules.all,
        spokenSymbolWords: DanishCleanupRules.spokenSymbolWords,
        modelLeadInPatterns: [
            #"(?i)^\s*(?:selvfølgelig|klart|okay|ok)[,!.]+\s*(?:her er|her kommer)[^\n:]{0,80}:\s+"#,
            #"(?i)^\s*(?:her er|her kommer)?[^\n:]{0,60}(?:den )?(?:rensede|rettede|korrigerede) (?:tekst|transskription|diktering)[^\n:]{0,30}:\s+"#,
        ])

    /// Function words are weak evidence for the faithfulness guard and unsafe
    /// neighbors for a dictated identifier. Ambiguous fillers and correction
    /// markers belong here too: the model may legitimately remove them.
    static let danishStopwords: Set<String> = [
        "af", "al", "alle", "at", "de", "dem", "den", "der", "deres", "det",
        "dig", "din", "dine", "dit", "du", "efter", "eller", "en", "end", "er",
        "et", "for", "fra", "før", "han", "hans", "har", "havde", "hen", "hende",
        "hendes", "her", "hos", "hun", "hvad", "hvem", "hvor", "hvordan", "hvorfor",
        "i", "ikke", "ind", "jeg", "jer", "jeres", "jo", "kan", "kunne", "man",
        "med", "men", "mig", "min", "mine", "mit", "mod", "må", "ned", "noget",
        "nogen", "nogle", "nu", "når", "og", "om", "op", "os", "over", "på",
        "samme", "sig", "sin", "sine", "sit", "skal", "skulle", "som", "så",
        "til", "ud", "under", "var", "ved", "vi", "vil", "ville", "vor", "vores",
        "være", "været", "yderligere",
        "altså", "faktisk", "hmm", "ligesom", "mhm", "mm", "nå", "okay", "sådan",
        "nej", "vent", "rettere", "mener",
    ]
}
