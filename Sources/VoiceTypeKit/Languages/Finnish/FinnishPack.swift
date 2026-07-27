import Foundation

extension LanguagePack {
    /// Finnish (yleiskieli, while preserving the speaker's chosen colloquial
    /// register).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `tota` / `tuota`, `niinku` / `niin kuin`, `siis`, `no`, `jaa`, and
    ///   `mhm` can all contribute meaning, stance, or an answer. Only clearly
    ///   nonlexical hesitation noises are deterministic fillers; the model may
    ///   remove the ambiguous items when context proves they are disposable.
    /// - `eiku` / `ei kun` commonly introduces a self-correction, but it is
    ///   also used deliberately for irony and quoted speech. Resolving the
    ///   repair therefore belongs to the model, never a blind deletion rule.
    /// - Bare `piste`, `pilkku`, and `viiva` are real nouns. They are not flat
    ///   spoken-punctuation replacements. The contextual symbol rule renders
    ///   them only inside a recognized file name, identifier, path, or flag.
    /// - Colloquial forms (`mä`, `sä`, dialectal variants), compounds,
    ///   inflection, names, and English technical terms are not normalized.
    ///   Finnish ASR is especially exposed to variation in exactly these
    ///   areas, and cleanup must not guess at the speaker's intended wording.
    static let finnish = LanguagePack(
        code: "fi",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: [
            "öö", "ööö", "öööö", "ää", "äää", "ääää", "hmm", "hm",
        ],
        // Compounds whose only ordinary reading names a mark are safe. Short
        // everyday nouns such as piste/pilkku/viiva stay out (see above).
        spokenPunctuation: [
            "kysymysmerkki": "?",
            "huutomerkki": "!",
            "kaksoispiste": ":",
            "puolipiste": ";",
            "vasen hakasulku": "[",
            "oikea hakasulku": "]",
            "avaa kaarisulku": "(",
            "sulje kaarisulku": ")",
            "avaa aaltosulku": "{",
            "sulje aaltosulku": "}",
            "avaa kulmasulku": "<",
            "sulje kulmasulku": ">",
            "ellipsi": "…",
        ],
        // Finnish polar questions normally carry -ko/-kö on the focused first
        // constituent. A blind suffix test would misclassify ordinary words
        // such as pakko, ukko, and koko, so list interrogatives and common
        // finite question forms instead.
        questionPrefixWords: [
            "kuka", "ketä", "kenet", "kenen", "kenelle", "keneltä", "kenellä",
            "mikä", "mitä", "minkä", "millä", "miltä", "mille", "missä",
            "mistä", "mihin", "miksi", "miten", "milloin", "kuinka", "kumpi",
            "kumpaa", "kumman", "kummalla", "kummalta", "kummalle", "mones",
            "onko", "ovatko", "oliko", "olivatko", "oletko", "oletteko",
            "olenko", "olemmeko", "eikö", "etkö", "enkö", "emmekö", "ettekö",
            "eivätkö", "voiko", "voitko", "voinko", "voimmeko", "voitteko",
            "saako", "saatko", "saanko", "saammeko", "saatteko", "pitääkö",
            "pitäisikö", "tuleeko", "tuletko", "tuliko", "haluatko",
            "haluaako", "tehdäänkö", "löytyykö", "sopiiko", "onnistuuko",
        ],
        questionSuffixParticles: [],
        stopwords: LanguagePack.finnishStopwords,
        prompt: .finnish,
        rules: FinnishCleanupRules.all,
        spokenSymbolWords: [
            "piste", "alaviiva", "viiva", "tavuviiva", "yhdysmerkki",
            "kauttaviiva", "tilde", "pilkku", "ät", "at-merkki", "avaa",
            "sulje", "kaarisulku", "hakasulku",
        ],
        guardPolicy: CleanupGuardPolicy(
            minimumContentWords: 6,
            minimumRetainedRatio: 0.45,
            maximumGrowthRatio: 1.6),
        modelLeadInPatterns: [
            #"(?i)^\s*(?:toki|selvä|tietysti)[,!.]+\s*(?:tässä (?:on|tulee)\b)?[^\n:]{0,80}:\s+"#,
            #"(?i)^\s*(?:tässä (?:on|tulee)\s+)?[^\n:]{0,50}(?:siistitty|korjattu|puhdistettu)\s+(?:teksti|sanelu|litterointi)[^\n:]{0,20}:\s+"#,
        ])

    /// Function words are weak evidence that model cleanup preserved the
    /// opening, and unsafe neighbors for a dictated identifier join.
    static let finnishStopwords: Set<String> = [
        "ja", "tai", "mutta", "vaan", "sekä", "että", "jotta", "kun",
        "jos", "vaikka", "kuin", "koska", "niin", "myös", "vielä", "jo",
        "nyt", "sitten", "vain", "ihan", "kai", "ehkä",
        "on", "oli", "ovat", "olivat", "olla", "olen", "olet", "olemme",
        "olette", "ole", "ei", "en", "et", "emme", "ette", "eivät",
        "se", "sen", "sitä", "siinä", "siitä", "tämä", "tämän", "tätä",
        "tässä", "tästä", "tuo", "tuon", "tuota", "nämä", "ne", "niiden",
        "minä", "mä", "sinä", "sä", "hän", "me", "te", "he",
        "joka", "jotka", "mikä", "mitä", "kuka",
        "no", "siis", "tota", "niinku", "eiku", "korjaan", "tarkoitan",
    ]
}

/// Finnish orthography that is mechanical enough to guarantee in both the
/// rules floor and the repair pass over model output.
///
/// Private-use sentinels hide Finnish punctuation from shared Latin passes
/// that would otherwise split a decimal comma or mistake the period inside an
/// abbreviation/date/time for a sentence or file-extension boundary. Every
/// mask has a same-scope final restore, including the terminal-safe pair.
private enum FinnishCleanupRules {
    private static let decimalComma = "\u{F0000}"
    // U+2027 is punctuation, so the shared capitalization pass can still see
    // `esim‧` as a plain word at the beginning of a sentence, but it does not
    // mistake the marker for a sentence-ending full stop.
    private static let abbreviationPeriod = "\u{2027}"
    private static let numericPeriod = "\u{F0002}"
    private static let lineBreak = "\u{F0003}"
    private static let paragraphBreak = "\u{F0004}"

    static let all: [CleanupRule] = [
        CleanupRule(
            name: "render contextual Finnish spoken symbols",
            stage: .early,
            runsInTerminal: true
        ) { text, context in
            SpokenSymbols.render(
                text,
                category: context.category,
                vocabulary: .finnish)
        },
        .regex(
            name: "protect Finnish decimal commas",
            stage: .early,
            runsInTerminal: true,
            pattern: #"(?<=\d),(?=\d)"#,
            template: decimalComma),
        CleanupRule(
            name: "protect Finnish abbreviation periods",
            stage: .early
        ) { text, _ in
            replace(
                text,
                pattern: #"\b(esim|mm|ns|nk|jne|ym|tms|vrt|no|puh|synt|kuol)\."#,
                template: "$1\(abbreviationPeriod)",
                options: [.caseInsensitive])
        },
        CleanupRule(
            name: "protect Finnish date and clock periods",
            stage: .early
        ) { text, _ in
            var out = replace(
                text,
                pattern: #"\b([0-3]?\d)\.([01]?\d)\.(\d{2,4})\b"#,
                template: "$1\(numericPeriod)$2\(numericPeriod)$3")
            out = replace(
                out,
                pattern: #"\b((?:klo|kello)\s+)([0-2]?\d)\.([0-5]\d)\b"#,
                template: "$1$2\(numericPeriod)$3",
                options: [.caseInsensitive])
            return out
        },
        CleanupRule(
            name: "protect dictated Finnish line breaks",
            stage: .early
        ) { text, _ in
            var out = text
                .replacingOccurrences(of: "\r\n", with: lineBreak)
                .replacingOccurrences(of: "\n", with: lineBreak)
            out = replace(
                out,
                pattern: #"\buusi\s+kappale\b"#,
                template: paragraphBreak,
                options: [.caseInsensitive])
            return replace(
                out,
                pattern: #"\buusi\s+rivi\b"#,
                template: lineBreak,
                options: [.caseInsensitive])
        },
        CleanupRule(
            name: "render Finnish paired quotation commands",
            stage: .afterPunctuation
        ) { text, _ in
            var out = replace(
                text,
                pattern: #"\baloita\s+lainaus\b"#,
                template: "”",
                options: [.caseInsensitive])
            return replace(
                out,
                pattern: #"\blopeta\s+lainaus\b"#,
                template: "”",
                options: [.caseInsensitive])
        },
        CleanupRule(
            name: "apply Finnish prose punctuation spacing",
            stage: .afterPunctuation
        ) { text, context in
            guard context.category != .codeEditor else { return text }
            var out = replace(
                text,
                pattern: #"([\(\[\{])\s+"#,
                template: "$1")
            out = replace(
                out,
                pattern: #"\s+([\)\]\}])"#,
                template: "$1")
            out = replace(
                out,
                pattern: #"”\s*([^”\n]+?)\s*”"#,
                template: "”$1”")
            out = replace(
                out,
                pattern: #"([.!?])\s+\1"#,
                template: "$1")
            return replace(
                out,
                pattern: #"([:;])\1+"#,
                template: "$1")
        },
        CleanupRule(
            name: "space Finnish quantities",
            stage: .afterPunctuation
        ) { text, context in
            guard context.category != .codeEditor else { return text }
            var out = replace(
                text,
                pattern: #"(?<=\d)\s*([€$£¥%‰])"#,
                template: " $1")
            return replace(
                out,
                pattern: #"(?<=\d)\s*(°[CF]|km|cm|mm|kg|mg|dl|ml|kW|kWh|kHz|MHz|GHz|GB|MB|KB|m|g|l|s|min|h|W|V|A|Hz)\b"#,
                template: " $1",
                options: [.caseInsensitive])
        },
        CleanupRule(
            name: "use Finnish typographic apostrophe in prose",
            stage: .final
        ) { text, context in
            guard context.category != .codeEditor else { return text }
            return replace(
                text,
                pattern: #"(?<=\p{L})'(?=\p{L})"#,
                template: "’")
        },
        CleanupRule(
            name: "restore Finnish decimal commas",
            stage: .final,
            runsInTerminal: true
        ) { text, _ in
            text.replacingOccurrences(of: decimalComma, with: ",")
        },
        CleanupRule(
            name: "restore Finnish abbreviation periods",
            stage: .final
        ) { text, _ in
            text
                .replacingOccurrences(
                    of: abbreviationPeriod + ".",
                    with: ".")
                .replacingOccurrences(
                    of: abbreviationPeriod,
                    with: ".")
        },
        CleanupRule(
            name: "restore Finnish date and clock periods",
            stage: .final
        ) { text, _ in
            text.replacingOccurrences(of: numericPeriod, with: ".")
        },
        CleanupRule(
            name: "restore dictated Finnish line breaks",
            stage: .final
        ) { text, _ in
            var out = replace(
                text,
                pattern: #"\s*\#(paragraphBreak)\s*"#,
                template: paragraphBreak)
            out = replace(
                out,
                pattern: #"\s*\#(lineBreak)\s*"#,
                template: lineBreak)
            return out
                .replacingOccurrences(of: paragraphBreak, with: "\n\n")
                .replacingOccurrences(of: lineBreak, with: "\n")
        },
        .regex(
            name: "remove redundant period after Finnish quoted question or exclamation",
            stage: .final,
            pattern: #"([.!?…])”\.$"#,
            template: "$1”"),
    ]

    private static func replace(
        _ text: String,
        pattern: String,
        template: String,
        options: NSRegularExpression.Options = []
    ) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: options
        ) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: template)
    }
}
