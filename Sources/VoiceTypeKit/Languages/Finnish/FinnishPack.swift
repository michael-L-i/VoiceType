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
            "aloita lainaus": "”",
            "lopeta lainaus": "”",
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
