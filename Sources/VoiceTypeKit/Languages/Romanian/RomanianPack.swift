import Foundation

extension LanguagePack {
    /// Romanian.
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `deci`, `păi`, `adică`, `gen`, `mă rog`, `știi`, `bun`, `așa`, and
    ///   `eh` can organize discourse, qualify an answer, reformulate content,
    ///   or carry their ordinary lexical meaning. The deterministic pass never
    ///   removes them; the LLM may remove one only when context proves it is
    ///   empty hesitation.
    /// - `mhm`, `hm`, and `mmm` can express agreement, doubt, or appreciation.
    ///   Only non-lexical central-vowel hesitations (`ăăă`, `îîî`, `ăm`) are
    ///   deterministic fillers.
    /// - Bare `punct`, `virgulă`, and `două puncte` are real nouns/phrases.
    ///   They are not unconditional punctuation. `punct` renders only in the
    ///   constrained spoken-symbol rule (a known file extension or terminal
    ///   path); the prompt handles the remaining context-sensitive cases.
    /// - Missing diacritics and the homophones `sa/s-a`, `sau/s-au`, `ia/i-a`,
    ///   `la/l-a`, `mai/m-ai`, `nea/ne-a`, and `va/v-a` require grammatical
    ///   context. Blind repair would change meaning, so they are LLM-only.
    /// - Thousands grouping is not rewritten. CLDR's Romanian locale data uses
    ///   a period while the EU institutional style guide mandates a fixed
    ///   space; both occur in well-edited Romanian text. Decimal commas are
    ///   protected because that convention is shared and unambiguous.
    /// - Straight ASCII quotes, apostrophes, and hyphens inside code stay
    ///   ASCII. Prose typography rules sit out terminals and explicitly avoid
    ///   code-editor contexts where those characters are syntax.
    static let romanian = LanguagePack(
        code: "ro",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: [
            "ă", "ăă", "ăăă",
            "î", "îî", "îîî",
            "â", "ââ", "âââ",
            "ăm", "ăhm", "îhm",
        ],
        // These multi-word names are explicit enough for iOS-style direct
        // rendering. Bare punct/virgulă/două puncte remain untouched.
        spokenPunctuation: [
            "semnul întrebării": "?",
            "semnul exclamării": "!",
            "punct și virgulă": ";",
            "puncte de suspensie": "…",
        ],
        // Romanian yes/no questions are normally marked by intonation rather
        // than inversion, so only lexical interrogatives are safe openers.
        // Multi-word openers such as "de ce" cannot use the shared first-token
        // heuristic without treating every sentence beginning with "de" as a
        // question; the LLM handles those.
        questionPrefixWords: [
            "cine", "cui", "unde", "când", "cum",
            "care", "cât", "câtă", "câți", "câte",
        ],
        questionSuffixParticles: [],
        stopwords: LanguagePack.romanianStopwords,
        prompt: .romanian,
        rules: RomanianCleanup.rules,
        spokenSymbolWords: RomanianSymbols.spokenWords,
        modelLeadInPatterns: [
            #"(?i)^\s*(?:sigur|desigur|bine)[,!.]+\s*(?:iată|aici (?:este|e))[^\n:]{0,80}:\s+"#,
            #"(?i)^\s*(?:iată|aici (?:este|e)|textul|transcrierea)[^\n:]{0,60}(?:curățat(?:ă)?|corectat(?:ă)?|revizuit(?:ă)?|dictare|transcriere)[^\n:]{0,30}:\s+"#,
        ])

    /// Function words that neither prove an opening survived model cleanup nor
    /// make safe neighbors for a dictated identifier join.
    static let romanianStopwords: Set<String> = [
        "un", "o", "niște", "unui", "unei", "unor",
        "și", "sau", "dar", "iar", "ci", "că", "ca", "dacă", "deci",
        "de", "din", "dintre", "la", "pe", "cu", "fără", "pentru", "prin",
        "spre", "sub", "peste", "între", "în", "într", "către", "despre",
        "eu", "tu", "el", "ea", "noi", "voi", "ei", "ele",
        "mă", "te", "se", "ne", "vă", "îl", "îi", "le", "mi", "ți",
        "meu", "mea", "tău", "ta", "său", "sa", "nostru", "voastră",
        "este", "e", "sunt", "era", "erau", "fi", "fie", "fost",
        "am", "ai", "a", "avem", "aveți", "au", "ar", "va", "vor",
        "acest", "această", "acești", "aceste", "acela", "aceea",
        "aici", "acolo", "acum", "atunci", "tot", "mai", "foarte",
        // Ambiguous discourse markers stay in the transcript unless the model
        // can prove they are empty, but they are poor faithfulness probes and
        // unsafe identifier neighbors.
        "deci", "păi", "adică", "gen", "știi", "bine", "așa",
        // Self-correction cues can legitimately disappear with retracted text.
        "nu", "ba", "scuze", "corect", "de fapt",
    ]
}

/// Romanian fixes that do not fit the pack's declarative fields.
enum RomanianCleanup {
    private static let decimalCommaMarker = "VTRoDecimalComma"
    private static let abbreviationDotMarker = "VTRoAbbreviationDot"

    static let rules: [CleanupRule] = [
        CleanupRule(name: "normalize Romanian comma-below diacritics",
                    stage: .early) { text, _ in
            text
                .replacingOccurrences(of: "Ş", with: "Ș")
                .replacingOccurrences(of: "ş", with: "ș")
                .replacingOccurrences(of: "Ţ", with: "Ț")
                .replacingOccurrences(of: "ţ", with: "ț")
                .precomposedStringWithCanonicalMapping
        },

        // The shared Latin spacing pass would turn 13,6 into "13, 6".
        // Mask digit-bound commas until every shared punctuation pass is done.
        CleanupRule.regex(
            name: "mask Romanian decimal commas",
            stage: .early,
            runsInTerminal: true,
            pattern: "(?<=\\d),(?=\\d)",
            template: decimalCommaMarker),

        // A period in "nr. trei" is not a sentence boundary. Hiding only a
        // curated abbreviation followed by a lowercase word prevents the
        // shared capitalization pass from producing "nr. Trei".
        CleanupRule.regex(
            name: "mask Romanian abbreviation periods",
            stage: .early,
            pattern: #"(?i)\b(dl|dna|dr|prof|conf|ing|arh|av|nr|str|bd|bl|sc|ap|et|jud|mun|loc|vol|pag|fig|art|alin|lit|pct|aprox|cca|etc)\.(?=\s+\p{Ll})"#,
            template: "$1" + abbreviationDotMarker),

        CleanupRule(name: "normalize Romanian prose ellipsis",
                    stage: .early) { text, context in
            guard context.category != .codeEditor else { return text }
            return text.replacingOccurrences(of: "...", with: "…")
        },

        CleanupRule(name: "normalize Romanian opening quotation marks",
                    stage: .early) { text, context in
            guard context.category != .codeEditor else { return text }
            return text.replacingOccurrences(of: "“", with: "„")
        },

        RomanianSymbols.renderingRule,

        // These spaced forms cannot be grammatical as separate Romanian words;
        // unlike homophones such as sa/s-a, joining them cannot change meaning.
        CleanupRule.regex(
            name: "join Romanian unstressed pronoun auxiliaries",
            stage: .afterPunctuation,
            pattern: #"\b(m|te|l|ne|v|mi|ți)\s+(am|ai|a|ați|au)\b"#,
            template: "$1-$2",
            options: [.caseInsensitive]),
        CleanupRule.regex(
            name: "join Romanian negative auxiliaries",
            stage: .afterPunctuation,
            pattern: #"\bn\s+(am|ai|a|avem|aveți|au|ar)\b"#,
            template: "n-$1",
            options: [.caseInsensitive]),
        CleanupRule.regex(
            name: "join Romanian reflexive auxiliaries",
            stage: .afterPunctuation,
            pattern: #"\bs\s+(a|au|ar)\b"#,
            template: "s-$1",
            options: [.caseInsensitive]),
        CleanupRule.regex(
            name: "join Romanian prepositional compounds",
            stage: .afterPunctuation,
            pattern: #"\b(într|dintr|printr)\s+(un|o)\b"#,
            template: "$1-$2",
            options: [.caseInsensitive]),

        // Romanian currency notation puts the amount before the symbol/code.
        // Use NBSP so the amount and unit cannot split across lines.
        CleanupRule.regex(
            name: "keep Romanian currency with its amount",
            stage: .afterPunctuation,
            pattern: #"(\d)[ \t]*(€|(?:RON|EUR|lei)\b)"#,
            template: "$1\u{00A0}$2",
            options: [.caseInsensitive]),

        CleanupRule.regex(
            name: "restore Romanian abbreviation periods",
            stage: .final,
            pattern: abbreviationDotMarker,
            template: "."),

        CleanupRule.regex(
            name: "restore Romanian decimal commas",
            stage: .final,
            runsInTerminal: true,
            pattern: decimalCommaMarker,
            template: ","),

        CleanupRule(name: "use typographic apostrophes in Romanian prose",
                    stage: .final) { text, context in
            guard context.category != .codeEditor else { return text }
            guard let regex = try? NSRegularExpression(
                pattern: #"(?<=\p{L})'(?=\p{L})|(?<![\p{L}\d])'(?=\d{2}\b)"#)
            else { return text }
            return regex.stringByReplacingMatches(
                in: text,
                range: NSRange(text.startIndex..., in: text),
                withTemplate: "’")
        },
    ]
}
