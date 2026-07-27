import Foundation

extension LanguagePack {
    /// Dutch (nl — Netherlands and Flanders).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - "nou", "dus", "gewoon", "eigenlijk", "even", "toch", "zeg maar",
    ///   "weet je", "ja": every one of them is a real Dutch word at least as
    ///   often as it is a hesitation ("dus" = therefore, "even" = for a moment,
    ///   "toch" = after all). They are never removed deterministically; the LLM
    ///   pass may drop them when context shows they carry no meaning, and the
    ///   prompt addendum says exactly that.
    /// - "er": English's filler list contains "er", and copying it here would
    ///   have been a disaster — "er" is one of the most common words in Dutch
    ///   ("er is", "er zijn", "er staat"). Same story for "mm", which is the
    ///   millimetre abbreviation; only "mmm" (three or more) is a hesitation.
    /// - "punt" / "komma" as `spokenPunctuation`: that table replaces
    ///   unconditionally, and both words are everyday nouns — "een goed punt",
    ///   "op dit punt", and, worse, "drie komma vijf" is how Dutch *reads a
    ///   decimal number out loud*. Rendering them blindly would corrupt prose.
    ///   `dutchRules` renders "punt" only in the one position where it cannot
    ///   be prose: directly before a known file extension or TLD.
    /// - "toch?" as a question particle: sentence-final "toch" is a tag
    ///   question ("Je komt toch") about as often as it means "anyway"
    ///   ("Ik ga toch"). Only "hè", "niet waar" and "of niet" are reliable.
    /// - dt-spelling ("hij word" → "hij wordt"): a genuine Dutch writing
    ///   error, but not one this engine sees — the transcribers spell from a
    ///   language model that already gets it right, and inventing a fix for an
    ///   error we cannot demonstrate would only add risk. Left out on purpose.
    /// - `symbols` (`SpokenSymbolVocabulary`): not adopted. The vocabulary
    ///   requires a language-wide word for "dot", and Dutch's is "punt", which
    ///   fails the pack's own house rule. The narrow, position-guarded joins in
    ///   `dutchRules` cover the safe subset instead.
    ///
    /// Sources for the orthography encoded here: Genootschap Onze Taal and
    /// Taaladvies.net (Nederlandse Taalunie) — cited per rule in `DutchRules`.
    static let dutch = LanguagePack(
        code: "nl",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Pure hesitation sounds only. "uh"/"uhm" are the Corpus Gesproken
        // Nederlands spellings; "eh"/"ehm" are the everyday written ones.
        // Note what is absent: "er", "mm", "ah", "oh", "hè" — all real words.
        fillers: [
            "uh", "uhh", "uhm", "uhmm", "eh", "ehh", "ehm", "eeh", "eehm",
            "hm", "hmm", "hmmm", "mmm", "mhm",
        ],
        // Empty by design — see the ambiguity policy above.
        spokenPunctuation: [:],
        // Interrogative words, plus the finite verbs that can only open a
        // question. Bare stems (ga, kom, doe, laat, zie, weet) are excluded:
        // they double as imperatives, and "Ga naar huis" is not a question.
        // "was" (also the imperative of wassen and the noun "de was"), "zijn"
        // (also the possessive "his") and "wilde" (also the adjective "wild")
        // are excluded for the same reason — half-right beats wrong.
        questionPrefixWords: [
            "wat", "wie", "wiens", "wanneer", "waar", "waarom", "waarheen",
            "waarnaartoe", "waarvandaan", "waarmee", "waarover", "waarvoor",
            "waardoor", "hoe", "hoezo", "hoeveel", "welk", "welke",
            "is", "ben", "bent", "waren", "wordt", "worden", "werd", "werden",
            "heb", "hebt", "heeft", "hebben", "had", "hadden",
            "kan", "kun", "kunt", "kunnen", "kon", "konden",
            "mag", "mogen", "mocht", "mochten",
            "moet", "moeten", "moest", "moesten",
            "zal", "zul", "zult", "zullen", "zou", "zouden",
            "wil", "wilt", "willen", "wou",
            "gaat", "gaan", "ging", "gingen",
            "doet", "doen", "deed", "deden",
            "komt", "komen", "kwam", "kwamen",
            "klopt", "hoeft", "hoeven",
        ],
        // Dutch tag questions. "hè" keeps its grave accent on purpose: bare
        // "he" as a suffix would fire on every word ending in -he ("cache").
        questionSuffixParticles: ["hè", "niet waar", "of niet"],
        stopwords: LanguagePack.dutchStopwords,
        prompt: .dutch,
        rules: LanguagePack.dutchRules,
        // An abbreviation's period doubles as the sentence period in Dutch
        // ("… en ir. Jansen komt ook bijv."), so text ending in a masked
        // abbreviation dot must not gain a second one. See `DutchRules`.
        terminalMarks: LanguagePack.defaultTerminalMarks.union([DutchOrthography.abbreviationDot]),
        spokenSymbolWords: LanguagePack.dutchSpokenSymbolWords,
        // Dutch packs about as much meaning per word as English, so the
        // English-calibrated guard ratios transfer unchanged.
        guardPolicy: .default,
        modelLeadInPatterns: LanguagePack.dutchModelLeadInPatterns)

    /// Function words that prove nothing about whether a dictation's opening
    /// survived, and that the spoken-symbol joins in `DutchRules` refuse to
    /// fuse into an identifier ("de underscore van" must never become
    /// "de_van"). Declared separately because those joins need the set before
    /// `LanguagePack.dutch` finishes initializing.
    static let dutchStopwords: Set<String> = [
        "de", "het", "een", "en", "of", "maar", "want", "dus", "te", "van",
        "in", "op", "aan", "bij", "met", "voor", "naar", "uit", "over", "om",
        "door", "als", "dan", "dat", "die", "dit", "deze", "daar", "hier",
        "er", "ook", "nog", "al", "wel", "niet", "geen", "heel", "erg", "zo",
        "toch", "even", "gewoon", "eigenlijk", "echt", "nou",
        "ik", "je", "jij", "jou", "u", "hij", "zij", "ze", "we", "wij",
        "jullie", "hem", "haar", "hun", "hen", "men", "mijn", "jouw", "uw",
        "zijn", "ons", "onze",
        "is", "ben", "bent", "was", "waren", "wordt", "worden", "werd",
        "heb", "hebt", "heeft", "hebben", "had", "hadden",
        "doe", "doet", "doen", "deed", "kan", "kun", "kunt", "kunnen",
        "moet", "moeten", "zal", "zullen", "zou", "zouden", "wil", "willen",
        "ja", "nee", "oké", "oke", "okay",
        // Self-correction markers: legitimately removed along with the words
        // they retract, so they prove nothing about the opening.
        "wacht", "sorry", "bedoel", "oftewel",
    ]

    /// Dutch words that name a symbol out loud, so the faithfulness guard
    /// discounts them when counting content words. Deliberately excludes the
    /// everyday words that merely *can* name a symbol ("punt", "streep",
    /// "regel", "letter", "min", "open") — widening the discount to those
    /// would blunt the guard on ordinary prose.
    static let dutchSpokenSymbolWords: Set<String> = [
        "puntkomma", "dubbelepunt", "vraagteken", "uitroepteken",
        "aanhalingsteken", "aanhalingstekens", "apostrof", "koppelteken",
        "streepje", "schuine", "underscore", "onderstrepingsteken",
        "liggend", "apenstaartje", "hekje", "hashtag", "sterretje",
        "asterisk", "procentteken", "euroteken", "dollarteken", "ampersand",
        "backslash", "backtick", "tilde", "dakje", "accolade", "accolades",
        "haakje", "haakjes", "vierkante", "openen", "sluiten", "spatie",
        "alinea", "hoofdletter", "kleine", "tab",
    ]

    /// Conversational shells the model emits when it answers in Dutch instead
    /// of obeying. Mirrors the shape of the shared English patterns: an
    /// opener-led preamble, or one that names the transcript. Bare "tekst" is
    /// deliberately absent — "De tekst van de mail:" is real dictation.
    static let dutchModelLeadInPatterns: [String] = [
        #"(?i)^\s*(?:natuurlijk|tuurlijk|zeker|uiteraard|prima|goed|oké|oke|okay|ok|geen probleem)[,!.]+\s*(?:hier (?:is|zijn|volgt|heb je)\b)?[^\n:]{0,80}:\s+"#,
        #"(?i)^\s*(?:hier (?:is|zijn|volgt|heb je)\b|de\b|het\b)?[^\n:]{0,60}(?:transcriptie|dictaat|opgeschoonde|opgeschoond|opgepoetste|gecorrigeerde)[^\n:]{0,30}:\s+"#,
    ]
}
