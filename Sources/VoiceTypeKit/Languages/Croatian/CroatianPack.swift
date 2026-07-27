import Foundation

extension LanguagePack {
    /// Croatian (standard Ijekavian, Latin script).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - ovaj / onaj / ono, znači, pa, dakle, zapravo, mislim: all are common
    ///   hesitation or discourse markers, but every one also has an ordinary
    ///   lexical or discourse use. Only the model may remove one, in context.
    /// - točka ("point/item/dot") and crtica ("dash/stroke"): neither is a
    ///   blind spoken-punctuation replacement. `točka` renders only beside a
    ///   known file extension; dash words render only in identifier/terminal
    ///   shapes. The specialized names zarez, upitnik, uskličnik, dvotočka,
    ///   trotočka and točka sa zarezom retain their dictation-command meaning.
    /// - jeli / je li, jer / jel', č/ć, dž/đ and ije/je: speech frequently
    ///   neutralizes these distinctions, but a global substitution would
    ///   change real words. The prompt may repair an unmistakable question or
    ///   spelling in context; deterministic cleanup never guesses.
    /// - Thousands separators and bare digit strings are not reformatted:
    ///   `10000` might be an identifier, port, postal code or literal. Existing
    ///   Croatian decimal commas and plausible dotted dates are protected.
    /// - Dialectal Čakavian, Kajkavian, Ikavian and informal forms are not
    ///   "standardized". Cleanup preserves the speaker's register and words.
    static let croatian = LanguagePack(
        code: "hr",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Non-lexical hesitation sounds only. Short interjections such as ah,
        // eh, joj, aha and ma can communicate a real reaction and stay.
        fillers: [
            "eee", "eeee", "eeeee",
            "mmm", "mmmm", "mmmmm",
            "uh", "uhm", "hm", "hmm",
        ],
        // Kept empty because CroatianDictation.render runs as an `.early`
        // CleanupRule in both the rules and model-polish paths. It can apply
        // contextual symbol guards and leave ambiguous `točka` alone in prose.
        spokenPunctuation: [:],
        // Conservative direct-question openers. `što`, `kako` and `koji` are
        // excluded because they readily open declarative constructions
        // ("Što se mene tiče…", "Kako bilo…", "Koji god…"). The final pack
        // rule separately recognizes the unambiguous no-comma "… li" frame.
        questionPrefixWords: [
            "tko", "gdje", "kamo", "kuda", "kada", "zašto", "koliko",
            "čiji", "čija", "čije", "čijeg", "čijemu", "čijom", "zar",
        ],
        questionSuffixParticles: [],
        stopwords: LanguagePack.croatianStopwords,
        prompt: .croatian,
        rules: CroatianRules.all,
        spokenSymbolWords: CroatianDictation.spokenSymbolWords,
        modelLeadInPatterns: [
            #"(?i)^\s*(?:naravno|u redu|evo)[,!.]+\s*[^\n:]{0,80}:\s+"#,
            #"(?i)^\s*(?:evo\s+)?[^\n:]{0,50}(?:očišćen[iao]?|uređen[iao]?|ispravljen[iao]?)[^\n:]{0,30}(?:tekst|prijepis|transkript)[^\n:]{0,20}:\s+"#,
        ])

    /// Function words ignored by the faithfulness guard and refused as pieces
    /// of a dictated identifier. This list does not remove anything.
    static let croatianStopwords: Set<String> = [
        "i", "a", "ali", "ili", "pa", "te", "ni", "niti", "no", "nego", "već",
        "da", "ako", "jer", "dok", "čim", "kad", "kada", "što", "kako", "koji",
        "koja", "koje", "tko", "gdje", "za", "od", "do", "iz", "u", "na", "o",
        "po", "pri", "prema", "s", "sa", "bez", "uz", "kroz", "među", "nad", "pod",
        "je", "sam", "si", "smo", "ste", "su", "bio", "bila", "bilo", "biti",
        "ću", "ćeš", "će", "ćemo", "ćete", "bi", "bih", "bismo", "biste",
        "ja", "ti", "on", "ona", "ono", "mi", "vi", "oni", "one", "mene", "tebe",
        "se", "me", "te", "ga", "ju", "ih", "nam", "vam", "im", "moj", "tvoj",
        "ovaj", "taj", "onaj", "ovo", "to", "sve", "nešto", "ništa",
        "ne", "zapravo", "čekaj", "oprosti", "odnosno", "mislim", "znači", "dakle",
    ]
}
