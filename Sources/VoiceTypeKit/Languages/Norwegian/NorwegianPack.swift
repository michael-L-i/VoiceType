import Foundation

extension LanguagePack {
    /// Norwegian Bokmål (`nb`).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - "altså", "liksom", "bare", "egentlig", "sånn", "vel", "jo",
    ///   "ikke sant", "du vet" and "på en måte" can all be discourse markers,
    ///   but every one also carries ordinary meaning. They are never removed
    ///   deterministically; the model may remove one only when context proves
    ///   that it is empty.
    /// - "hm", "hmm", "mm" and "mhm" can be meaningful answers, agreement,
    ///   doubt or appreciation. Only the non-lexical hesitation spellings
    ///   `eh`/`øh` and their lengthened forms belong in `fillers`.
    /// - "punktum", "komma", "kolon", "strek" and "ny linje" are not flat
    ///   `spokenPunctuation` entries. The table replaces words everywhere:
    ///   it would corrupt decimal dictation ("tre komma fem"), ordinary prose
    ///   ("sette punktum") and instructions about punctuation. Local rules
    ///   render only the safe code-shaped subset.
    /// - Norwegian commonly uses outward guillemets («…»), but Språkrådet
    ///   explicitly accepts several quotation-mark forms. Blindly changing
    ///   straight quotes would also damage code, so quote selection stays in
    ///   the prompt.
    /// - Large numbers use spaces, not periods, for digit grouping. We preserve
    ///   correct spaces and tell the model the convention, but never rewrite
    ///   `1.250`: it may be a version, identifier or non-Norwegian number.
    /// - Genitives normally take no apostrophe, with important exceptions for
    ///   words ending in s/x/z and some abbreviations. That is grammatical
    ///   judgment and therefore model-only.
    /// - Norwegian compounds are normally closed, but deciding whether two
    ///   adjacent words form a compound is lexical. The model gets the rule;
    ///   deterministic cleanup never glues ordinary prose together.
    /// - `symbols` remains nil because the shared integrity contract reserves
    ///   that field for English. `norwegianRules` applies a narrower,
    ///   context-guarded spoken-code vocabulary to both rules and model output.
    ///
    /// Sources consulted (2026-07): Språkrådet's pages on spacing, numbers,
    /// dates, capitalization, punctuation, quotation marks, apostrophes and
    /// abbreviations; NTNU LearnNoW's question grammar; the National Library's
    /// Norwegian speech/ASR corpus documentation; and Svennevig et al. on
    /// informal Norwegian speech. Individual rules cite these sources in the
    /// commits that introduced them.
    static let norwegian = LanguagePack(
        code: "nb",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Non-lexical hesitation sounds documented in Norwegian speech
        // resources. Meaningful backchannels (hm/mm/mhm) stay out.
        fillers: [
            "eh", "ehh", "ehhh", "ehm", "ehmm", "eeh", "eeeh",
            "øh", "øhh", "øhhh", "øhm", "øhmm", "øøh",
        ],
        // Empty by design — see the ambiguity policy above.
        spokenPunctuation: [:],
        // Norwegian content questions begin with an interrogative. Yes/no
        // questions are handled by a local two-token rule that requires both
        // a finite auxiliary and an explicit pronoun subject. Putting bare
        // "er"/"kan"/"vil" here would mispunctuate common subject-omitted
        // messages such as "er på vei" and "kan møte i morgen".
        questionPrefixWords: [
            "hva", "hvem", "hvilken", "hvilket", "hvilke",
            "hvor", "hvorfra", "hvorhen", "hvordan", "hvorfor", "hvorledes",
            "når",
        ],
        // A reliable tag. Bare "vel", "eller" and "jo" are too often content.
        questionSuffixParticles: ["ikke sant"],
        stopwords: LanguagePack.norwegianStopwords,
        prompt: .norwegian,
        rules: LanguagePack.norwegianRules,
        // A sentence ending in a masked abbreviation already has its period.
        terminalMarks: LanguagePack.defaultTerminalMarks.union([
            NorwegianOrthography.abbreviationDot,
        ]),
        spokenSymbolWords: LanguagePack.norwegianSpokenSymbolWords,
        guardPolicy: .default,
        modelLeadInPatterns: LanguagePack.norwegianModelLeadInPatterns)

    /// Function words that do not prove a transcript opening survived, and
    /// that the local spoken-identifier renderer refuses to join.
    static let norwegianStopwords: Set<String> = [
        "en", "ei", "et", "den", "det", "de", "og", "eller", "men", "for",
        "så", "å", "av", "i", "på", "til", "fra", "med", "om", "over",
        "under", "ved", "mot", "etter", "før", "gjennom", "som", "at", "da",
        "når", "hvis", "fordi", "derfor", "her", "der", "dette", "disse",
        "ikke", "ingen", "noe", "noen", "alle", "alt", "også", "bare", "jo",
        "vel", "nok", "nå", "ennå", "fortsatt", "egentlig", "liksom", "sånn",
        "altså", "virkelig", "helt", "litt",
        "jeg", "meg", "min", "mitt", "mine", "vi", "oss", "vår", "vårt",
        "våre", "du", "deg", "din", "ditt", "dine", "dere", "deres", "han",
        "ham", "hans", "hun", "henne", "hennes", "hen", "hens", "dem",
        "er", "var", "være", "blir", "ble", "har", "hadde", "ha", "kan",
        "kunne", "skal", "skulle", "vil", "ville", "må", "måtte", "bør",
        "burde", "får", "fikk", "gjør", "gjorde",
        "ja", "nei", "joda", "neida", "ok", "okei",
        // Self-correction markers can disappear with the retracted phrase.
        "vent", "beklager", "sorry", "mente", "rettere",
    ]

    /// Norwegian symbol names discounted by the faithfulness guard. Everyday
    /// words that only sometimes name a mark ("punkt", "strek", "minus") are
    /// omitted; the narrower renderer still recognizes some in safe contexts.
    static let norwegianSpokenSymbolWords: Set<String> = [
        "punktum", "komma", "semikolon", "kolon", "spørsmålstegn",
        "utropstegn", "anførselstegn", "apostrof", "bindestrek",
        "tankestrek", "understrek", "underscore", "skråstrek", "backslash",
        "krøllalfa", "alfakrøll", "hashtag", "emneknagg", "firkanttegn",
        "stjerne", "asterisk", "prosenttegn", "eurotegn", "dollartegn",
        "ampersand", "ogtegn", "loddrettstrek", "pipe", "bakstrek",
        "backtick", "tilde", "cirkumfleks", "parentes", "parenteser",
        "hakeparentes", "klammeparentes", "krøllparentes", "vinkelparentes",
        "åpne", "lukk", "mellomrom", "linjeskift", "avsnitt", "tabulator",
        "stor", "liten", "bokstav",
    ]

    /// Norwegian conversational lead-ins a small model may add. Bare "tekst"
    /// is intentionally absent because "Teksten i e-posten:" is real prose.
    static let norwegianModelLeadInPatterns: [String] = [
        #"(?i)^\s*(?:selvfølgelig|klart|greit|okei|ok|ingen problem)[,!.]+\s*(?:her (?:er|kommer|følger)\b)?[^\n:]{0,80}:\s+"#,
        #"(?i)^\s*(?:her (?:er|kommer|følger)\b|nedenfor (?:er|følger)\b)[^\n:]{0,60}(?:transkripsjonen|utskriften|dikteringen|renskrivingen|den renskrevne teksten)[^\n:]{0,30}:\s+"#,
    ]
}
