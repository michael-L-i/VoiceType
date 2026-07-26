import Foundation

extension LanguagePack {
    /// Turkish (Türkiye Turkish; keyed on `tr`).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `şey`, `yani`, `işte`, `falan` / `filan`, `eee`, `hımm`, and `ee`
    ///   can all carry discourse meaning. Only the non-lexical closed-vowel
    ///   pauses `ıı…` are removed blindly; the prompt removes the others only
    ///   when context proves they are hesitation.
    /// - Bare `nokta`, `virgül`, `tire`, and `et` are ordinary words or names
    ///   as well as symbol names. They are not unconditional punctuation.
    ///   Turkish's own spoken-symbol rule consumes them only inside a known
    ///   file extension, identifier, email address, path, flag, or bracketed
    ///   expression.
    /// - Proper-name and abbreviation suffixes need vowel harmony and lexical
    ///   knowledge (`Ankara’ya`, `TDK’ye`, but `Türk Dil Kurumuna`). The model
    ///   gets the rule; deterministic cleanup never guesses an apostrophe.
    /// - `1,234` is a valid Turkish decimal as well as an English-formatted
    ///   thousand. Existing separators are preserved instead of guessing the
    ///   speaker's number; the prompt chooses from context.
    /// - Interrogative words can introduce indirect clauses, and Turkish word
    ///   order is flexible. The shared first-word probe remains deliberately
    ///   small; the reliable sentence-final `mı/mi/mu/mü` family carries most
    ///   deterministic question detection.
    static let turkish = LanguagePack(
        code: "tr",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["ıı", "ııı", "ıııı"],
        // Multi-word commands name the mark unambiguously. The bare everyday
        // nouns above stay out and are handled contextually.
        spokenPunctuation: [
            "nokta işareti": ".",
            "virgül işareti": ",",
            "noktalı virgül": ";",
            "iki nokta üst üste": ":",
            "soru işareti": "?",
            "ünlem işareti": "!",
            "üç nokta işareti": "…",
            "tırnak işareti aç": "“",
            "tırnak işareti kapat": "”",
            "tırnak aç": "“",
            "tırnak kapat": "”",
            "tek tırnak aç": "‘",
            "tek tırnak kapat": "’",
            "yüzde işareti": "%",
            "binde işareti": "‰",
            "türk lirası işareti": "₺",
        ],
        questionPrefixWords: [
            "neden", "niye", "niçin", "kim", "nerede", "nereye", "nereden",
            "nasıl", "hangi", "kaç",
        ],
        // The leading space makes suffix matching a token-boundary check.
        // Turkish writes the particle separately, then joins personal/tense
        // suffixes to it: "geldi mi", "geliyor musun", "gelecek miydi".
        questionSuffixParticles: TurkishOrthography.questionParticleEndings,
        stopwords: TurkishOrthography.stopwords,
        prompt: .turkish,
        rules: TurkishOrthography.rules,
        casingLocaleIdentifier: "tr_TR",
        spokenSymbolWords: TurkishOrthography.spokenSymbolWords,
        // Turkish model wrappers observed/expected from the same "helpful
        // assistant" failure the shared English sanitizer catches.
        modelLeadInPatterns: [
            #"(?i)^\s*(?:elbette|tabii|tamam|peki)[,!.]+\s*(?:işte\s+)?[^\n:]{0,70}:\s+"#,
            #"(?i)^\s*(?:işte\s+)?(?:temizlenmiş|düzeltilmiş|düzenlenmiş)\s+(?:metin|dikte|transkript)[^\n:]{0,30}:\s+"#,
        ])
}

enum TurkishOrthography {
    // Private-use scalars hide Turkish decimal commas and abbreviation periods
    // from shared Latin passes that would otherwise split/capitalize them.
    private static let decimalComma = "\u{F0000}"
    private static let abbreviationPeriod = "\u{F0001}"
    private static let lineBreak = "\u{F0002}"
    private static let paragraphBreak = "\u{F0003}"
    private static let apostropheSuffix =
        #"(?:y[aeıiuü]|[dt][ae]|[dt][ae]n|n?[ıiuü]n|n?[ıiuü]|yl[ae]|[dt][ıiuü]r|y?m[ıiuü]ş|ys[ae])"#

    static let questionParticleEndings: Set<String> = [
        " mı", " mi", " mu", " mü",
        " mıyım", " miyim", " muyum", " müyüm",
        " mısın", " misin", " musun", " müsün",
        " mıyız", " miyiz", " muyuz", " müyüz",
        " mısınız", " misiniz", " musunuz", " müsünüz",
        " mıdır", " midir", " mudur", " müdür",
        " mıydı", " miydi", " muydu", " müydü",
        " mıydın", " miydin", " muydun", " müydün",
        " mıydınız", " miydiniz", " muydunuz", " müydünüz",
        " mıymış", " miymiş", " muymuş", " müymüş",
        " mıysa", " miyse", " muysa", " müyse",
    ]

    static let stopwords: Set<String> = [
        "bir", "bu", "şu", "o", "ve", "veya", "yahut", "ama", "fakat",
        "çünkü", "ile", "için", "gibi", "kadar", "göre", "daha", "çok",
        "az", "da", "de", "ki", "ise", "iken", "olarak",
        "ben", "sen", "biz", "siz", "onlar", "bana", "sana", "bize", "size",
        "beni", "seni", "bizi", "sizi", "onu", "onları",
        "benim", "senin", "bizim", "sizin", "onun", "onların",
        "mı", "mi", "mu", "mü", "ne", "kim", "nasıl", "neden", "niye",
        "nerede", "nereye", "nereden", "hangi", "kaç",
        "var", "yok", "olan", "oldu", "olabilir",
        "evet", "hayır", "tamam", "peki", "şey", "yani", "işte",
        "falan", "filan", "aslında", "pardon",
    ]

    static let spokenSymbolWords: Set<String> = [
        "nokta", "alt", "çizgi", "altçizgi", "tire", "kısaçizgi",
        "eğik", "eğikçizgi", "bölü", "tilde", "virgül", "et",
        "kuyruklu", "kuyruklua", "aç", "kapat", "kapa", "parantez",
        "köşeli", "köşeliparantez",
    ]

    static let rules: [CleanupRule] = [
        .regex(
            name: "protect Turkish decimal commas",
            stage: .early,
            runsInTerminal: true,
            pattern: #"(?<=\d),(?=\d)"#,
            template: decimalComma),
        CleanupRule(
            name: "expose sentence-initial Turkish apostrophe for casing",
            stage: .early) { text, _ in
                replace(
                    text,
                    pattern: #"^(\p{L}+)[’](?="# + apostropheSuffix + #"\b)"#,
                    template: "$1'")
            },
        CleanupRule(
            name: "protect Turkish abbreviation periods",
            stage: .early) { text, _ in
                replace(
                    text,
                    pattern: #"(?i)(?<![\p{L}\p{N}_])(dr|prof|doç|yrd|av|alb|gen|cad|sok|mah|no|vb|vs|örn|bk|sf|haz|çev|ed|alm|ing|kr|sn)\.(?=\s|$)"#,
                    template: "$1" + abbreviationPeriod)
            },
        CleanupRule(
            name: "protect dictated Turkish line breaks",
            stage: .early) { text, _ in
                text
                    .replacingOccurrences(
                        of: "yeni paragraf", with: paragraphBreak,
                        options: [.caseInsensitive])
                    .replacingOccurrences(
                        of: "yeni satır", with: lineBreak,
                        options: [.caseInsensitive])
            },
        TurkishSymbols.renderRule,
        .regex(
            name: "restore Turkish decimal commas",
            stage: .afterPunctuation,
            runsInTerminal: true,
            pattern: NSRegularExpression.escapedPattern(for: decimalComma),
            template: ","),
        CleanupRule(
            name: "apply Turkish prose punctuation spacing",
            stage: .afterPunctuation) { text, context in
                guard context.category == .general || context.category == .messaging else {
                    return text
                }
                var out = replace(
                    text,
                    pattern: #"(?<=\p{L}):(?=\p{L})"#,
                    template: ": ")
                out = replace(out, pattern: #"([“‘])\s+"#, template: "$1")
                out = replace(out, pattern: #"\s+([”’])"#, template: "$1")
                out = replace(out, pattern: #"([\(\[])\s+"#, template: "$1")
                return replace(out, pattern: #"\s+([\)\]])"#, template: "$1")
            },
        .regex(
            name: "attach Turkish rate and lira signs",
            stage: .afterPunctuation,
            pattern: #"([%‰₺])\s+(?=\d)"#,
            template: "$1"),
        .regex(
            name: "collapse idempotent Turkish spoken marks",
            stage: .afterPunctuation,
            pattern: #"([.,!?;:])\s+\1"#,
            template: "$1"),
        CleanupRule(
            name: "restore sentence-initial Turkish apostrophe",
            stage: .final) { text, _ in
                replace(
                    text,
                    pattern: #"^(\p{L}+)'(?="# + apostropheSuffix + #"\b)"#,
                    template: "$1’")
            },
        CleanupRule(
            name: "restore Turkish abbreviation periods",
            stage: .final) { text, _ in
                replace(
                    text,
                    pattern: NSRegularExpression.escapedPattern(for: abbreviationPeriod) + #"\.?"#,
                    template: ".")
            },
        CleanupRule(
            name: "restore dictated Turkish line breaks",
            stage: .final) { text, _ in
                var out = replace(
                    text,
                    pattern: #"\s*"# + NSRegularExpression.escapedPattern(for: paragraphBreak) + #"\.?\s*"#,
                    template: "\n\n")
                out = replace(
                    out,
                    pattern: #"\s*"# + NSRegularExpression.escapedPattern(for: lineBreak) + #"\.?\s*"#,
                    template: "\n")
                return out
            },
    ]

    private static func replace(_ text: String,
                                pattern: String,
                                template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(
            in: text, options: [], range: range, withTemplate: template)
    }
}
