import Foundation

extension LanguagePack {
    /// Swedish (sv).
    ///
    /// Swedish is a V2 language: in a main clause the finite verb sits in
    /// second position, so a sentence that *opens* with a finite verb is
    /// either a yes/no question, an imperative, or a verb-first conditional.
    /// That makes verb inversion a much stronger question signal here than in,
    /// say, Spanish — the pack leans on it, minus the verbs whose imperative
    /// form is identical (see below).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `liksom`, `typ`, `alltså`, `ju`, `väl`, `nog`, `då`, `ba`, `va`: all
    ///   of them are real words at least as often as they are hesitations
    ///   (`liksom hans bror` = "like his brother", `typ 20 personer` = "about
    ///   20", `ju` is a modal particle that changes what a sentence asserts).
    ///   The deterministic pass never removes them; the LLM pass may, when
    ///   context shows they carry no meaning — see `SwedishPrompt`.
    /// - `äh`: a dismissive interjection with real pragmatic content ("Äh, det
    ///   gör inget"), not a hesitation vowel. Kept.
    /// - `mm`: kept, because it is also the unit millimetre. "5 mm" losing its
    ///   unit is a worse failure than an occasional backchannel surviving.
    /// - `komma` as a spoken comma: it is the verb "to come". Only the
    ///   unambiguous compound `kommatecken` renders (`SwedishRules`).
    /// - `punkt` as a spoken period: an everyday noun ("en viktig punkt",
    ///   "punkt 3"), so it is NOT in a flat replacement table. It renders only
    ///   in positions where the noun reading is impossible — that is what
    ///   `SwedishRules.spokenPunctuation` exists for.
    /// - `gör` and `kom` as question openers: their imperative and present
    ///   forms coincide ("Gör det nu!", "Kom hit!"), so a question mark would
    ///   land on a command. `var` is the same problem and gets a narrower,
    ///   positive rule instead (`SwedishRules.whereQuestion`).
    /// - Decimal points (`3.14` → `3,14`) and thousands grouping (`20000` →
    ///   `20 000`): both are correct Swedish, and both are unsafe blind. A
    ///   digit-dot-digit run is just as likely a version number, an IP, or a
    ///   file name, and four-digit runs are years and port numbers. Prompt
    ///   territory, not rule territory.
    /// - The anglicised apostrophe genitive (`Lisa's bok` → `Lisas bok`):
    ///   correct Swedish, but embedded English is so common in Swedish tech
    ///   dictation ("Apple's roadmap") that a blind rule would corrupt it.
    ///
    /// `symbols` stays nil on purpose. Swedish drives the shared
    /// `SpokenSymbols` pipeline from `SwedishRules.spokenSymbols` instead,
    /// which is strictly better here: a rule runs in *both* cleanup paths (the
    /// pack field only feeds the rules floor, never model output), and it can
    /// see the app category, so `streck` can be a flag marker in a terminal
    /// and an everyday noun in prose. It also keeps this pack clear of
    /// `EnglishPackTests`, which asserts English is the only `symbols` opt-in.
    static let swedish = LanguagePack(
        code: "sv",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Pure hesitation vowels only. Everything a Swede might also mean is
        // listed in the ambiguity policy above and left to the LLM.
        fillers: [
            "eh", "ehh", "eeh", "ehm", "öh", "öhh", "öhm", "öhhm",
            "hm", "hmm", "hmmm", "ähm", "mhm",
        ],
        // Empty by design: Swedish punctuation names are handled positionally
        // by `SwedishRules`, because the flat table replaces unconditionally
        // and `punkt` is an everyday noun.
        spokenPunctuation: [:],
        questionPrefixWords: LanguagePack.swedishQuestionOpeners,
        questionSuffixParticles: [],
        stopwords: LanguagePack.swedishStopwords,
        prompt: .swedish,
        rules: SwedishRules.all,
        spokenSymbolWords: LanguagePack.swedishSpokenSymbolWords,
        // Defaults kept deliberately. The one Swedish-specific pressure on the
        // retention ratio is compound rejoining ("kaffe kopp" → "kaffekopp"),
        // which shrinks the word count the model returns; at realistic
        // compound densities that stays well inside the 0.5 floor, and
        // loosening a safety threshold without eval evidence is how bad output
        // starts shipping.
        guardPolicy: .default,
        modelLeadInPatterns: LanguagePack.swedishLeadInPatterns)

    // MARK: - Question openers

    /// Words that open a direct question. Two groups:
    ///
    /// 1. Interrogatives (`vad`, `vem`, `hur` …) — unambiguous.
    /// 2. Finite verbs, which can only stand first in a main clause when the
    ///    clause is a question (Swedish is V2). Excluded from this group are
    ///    the verbs whose imperative is spelled the same — `gör`, `kom`, `se`,
    ///    `gå`, `ta` — and `var`, which is imperative ("Var snäll!"), past
    ///    tense ("Var det bra"), *and* the interrogative "where". `var` gets
    ///    `SwedishRules.whereQuestion` instead, which fires only when a finite
    ///    verb follows it.
    ///
    /// `hade` is included even though a verb-first conditional ("Hade jag
    /// vetat det …") also opens with it; that construction is literary and
    /// rare in dictation, while "Hade du tid igår" is not.
    static let swedishQuestionOpeners: Set<String> = [
        // Interrogatives
        "vad", "vadå", "vem", "vems", "vilka", "vilken", "vilket", "vilkas",
        "vart", "varifrån", "varför", "när", "hur", "hurdan", "hurdant",
        // Inverted finite verbs
        "är", "kan", "kunde", "ska", "skall", "skulle", "har", "hade",
        "vill", "ville", "får", "fick", "blir", "blev", "finns", "fanns",
        "kommer", "måste", "borde", "bör", "behöver", "behövde",
        "tror", "trodde", "tycker", "tyckte", "vet", "visste", "heter",
        "går", "gick", "ser", "såg", "sa", "sade", "gjorde", "verkar",
        "låter", "känns", "stämmer", "funkar", "fungerar", "hinner",
        "orkar", "brukar", "tänker", "gillar",
    ]

    // MARK: - Lexicons

    /// Function words that prove nothing about a dictation's content: the
    /// faithfulness guard skips them when probing whether the opening
    /// survived, and the spoken-symbol renderer refuses to join them into an
    /// identifier ("till understreck" must stay two words).
    ///
    /// Declared separately because `SpokenSymbolVocabulary.swedish` builds on
    /// it before `LanguagePack.swedish` itself finishes initializing.
    static let swedishStopwords: Set<String> = [
        // Articles, determiners, pronouns
        "en", "ett", "den", "det", "de", "dem", "dom", "denna", "detta", "dessa",
        "jag", "du", "han", "hon", "hen", "vi", "ni", "man", "mig", "dig", "sig",
        "oss", "er", "honom", "henne", "min", "mitt", "mina", "din", "ditt",
        "dina", "sin", "sitt", "sina", "vår", "vårt", "våra", "era", "ert",
        // Conjunctions and subordinators
        "och", "eller", "men", "att", "som", "så", "om", "för", "då", "när",
        "medan", "eftersom", "eller",
        // Prepositions
        "i", "på", "av", "med", "till", "från", "vid", "under", "över",
        "efter", "före", "mot", "hos", "genom", "utan", "mellan", "kring",
        "åt", "ur", "per", "hit", "dit",
        // Copulas and high-frequency verbs
        "är", "var", "vara", "blir", "bli", "blev", "har", "hade", "ha",
        "ska", "skall", "skulle", "kan", "kunde", "vill", "ville", "får",
        "fick", "gör", "göra", "kommer", "måste",
        // Adverbs and discourse particles
        "inte", "ej", "här", "där", "nu", "sedan", "sen", "bara", "ju", "väl",
        "nog", "också", "ändå", "redan", "alltid", "aldrig", "mycket", "lite",
        "mer", "ja", "nej", "jo", "okej", "precis", "verkligen", "faktiskt",
        "alltså", "liksom", "typ", "ungefär",
        // Self-correction markers: legitimately removed along with the words
        // they retract, so they prove nothing about the opening.
        "förlåt", "vänta", "menar", "menade", "rättare", "sagt", "förresten",
    ]

    /// Swedish words that name a symbol out loud. The faithfulness guard
    /// discounts them when counting content, so a heavily dictated identifier
    /// doesn't read as a summary. Replaces the English default wholesale —
    /// "dot" and "paren" prove nothing about a Swedish dictation.
    static let swedishSpokenSymbolWords: Set<String> = [
        "punkt", "komma", "kommatecken", "frågetecken", "utropstecken",
        "semikolon", "kolon", "bindestreck", "understreck", "snedstreck",
        "streck", "tankstreck", "tilde", "snabel-a", "snabela", "at",
        "procenttecken", "parentes", "parenteser", "vänsterparentes",
        "högerparentes", "hakparentes", "hakparenteser", "klammer",
        "klammerparentes", "vänster", "höger", "öppen", "öppna", "stäng",
        "slut", "citattecken", "citationstecken", "stjärna", "asterisk",
        "plus", "minus", "likhetstecken", "et-tecken", "lodstreck",
        "nummertecken", "brädgård", "hashtag", "dollar", "ellips",
        "omvänt", "ny", "nytt", "rad", "stycke", "tabb", "blanksteg",
        "mellanslag", "versal", "gemen", "stor", "liten", "bokstav",
    ]

    /// Conversational lead-ins the small model emits *in Swedish* when it
    /// ignores the "output only the transcript" rule. Both patterns demand a
    /// signal that the sentence is talking ABOUT the output — an opener like
    /// "Visst," or a noun naming the text — so ordinary dictation that happens
    /// to contain a colon ("Här är min plan: köp mjölk") is never stripped.
    static let swedishLeadInPatterns: [String] = [
        #"(?i)^\s*(?:visst|okej|absolut|javisst|självklart|klart|inga problem)[,!.]+\s*(?:här (?:är|kommer)\b)?[^\n:]{0,80}:\s+"#,
        #"(?i)^\s*(?:här (?:är|kommer)|detta är|det här är|nedan (?:är|följer))\b[^\n:]{0,60}(?:transkription\w*|diktering\w*|text\w*|version\w*|resultat\w*):\s+"#,
    ]
}
