import Foundation

extension LanguagePack {
    /// Modern Greek (monotonic orthography).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - λοιπόν, δηλαδή, βασικά, ξέρεις, ας πούμε, εντάξει: all can organize
    ///   discourse or carry ordinary lexical meaning. The deterministic pass
    ///   keeps them; the model may remove one only when context proves it is a
    ///   throwaway hesitation.
    /// - ε / εμ / μμμ: a single ε names a letter or works as an interjection,
    ///   uppercase ΕΜ can be an acronym, and μμμ can express appreciation or
    ///   agreement. Only unmistakably prolonged εεε / εμμ… forms are blind
    ///   fillers. In particular, εε is excluded because ΕΕ means the EU.
    /// - τι, πώς, γιατί, πότε, and πόσο are not deterministic question
    ///   openers: they also begin exclamations, causal answers, indirect
    ///   questions, and non-interrogative idioms. Contextual punctuation
    ///   belongs to the model; the narrow pronoun/adverb set below is the
    ///   zero-latency floor.
    /// - Decimal dots are not rewritten to commas and currency/date formats
    ///   are not rearranged. A dot may belong to a version, IP address, file
    ///   name, time, or date, so only already-Greek decimal commas are masked
    ///   from the shared spacing pass.
    /// - Bare τελεία and κόμμα are not unconditional punctuation commands:
    ///   both are ordinary nouns. Explicit "βάλε …" commands are rendered,
    ///   while bare τελεία remains available to the context-guarded file-name
    ///   renderer ("main τελεία py" → "main.py").
    /// - No lexical spelling or accent repair is blind. Homophones such as
    ///   η/ή, που/πού, πως/πώς, and οτι/ότι/ό,τι require sentence meaning.
    static let greek = LanguagePack(
        code: "el",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: [
            "εεε", "εεεε", "εμμ", "εμμμ", "εμμμμ",
        ],
        // Greek spoken punctuation is context-aware below rather than using
        // this unconditional table. That keeps shell commands safe and also
        // repairs model output through the same CleanupRule hook.
        spokenPunctuation: [:],
        questionPrefixWords: [
            "ποιος", "ποια", "ποιο", "ποιοι", "ποιες", "ποιους",
            "ποιανού", "τίνος", "πού", "μήπως",
        ],
        questionSuffixParticles: [],
        // Unicode recommends U+003B, the canonical form to which U+037E
        // normalizes. U+0387 is ano teleia, a different punctuation mark.
        questionMark: ";",
        stopwords: LanguagePack.greekStopwords,
        prompt: .greek,
        rules: [
            .greekMaskAbbreviationPeriods,
            .greekMaskProtectedCommas,
            .greekMaskTechnicalQuestionMarks,
            .greekRenderSpokenPunctuation,
            .greekPrepareQuestionMarks,
            .greekRenderSpokenSymbols,
            .greekNormalizeAnoTeleia,
            .greekNormalizeElisionApostrophe,
            .greekTightenGuillemets,
            .greekRestoreProtectedCharacters,
            .greekFinalizeQuestionMarks,
        ],
        spokenSymbolWords: GreekSpokenSymbols.guardWords,
        modelLeadInPatterns: [
            #"(?i)^\s*(?:βεβαίως|φυσικά|εντάξει)[,!.]+\s*(?:ορίστε\s+)?[^\n:]{0,60}:\s+"#,
            #"(?i)^\s*(?:ορίστε\s+)?(?:το\s+)?(?:καθαρισμένο|διορθωμένο)\s+(?:κείμενο|κείμενό σας|απομαγνητοφωνημένο κείμενο)[^\n:]{0,20}:\s+"#,
        ])

    /// Function words that neither prove content survived a model cleanup nor
    /// make safe identifier components around a spoken symbol.
    static let greekStopwords: Set<String> = [
        "ο", "η", "το", "οι", "τα", "του", "της", "των", "τον", "την", "τους", "τις",
        "ένας", "ένα", "μια", "μία", "κάποιος", "κάποια", "κάποιο",
        "και", "ή", "αλλά", "όμως", "ούτε", "μήτε", "ενώ", "αν", "όταν", "ότι", "πως",
        "να", "θα", "μη", "μην", "δεν", "δε", "ναι", "όχι",
        "σε", "με", "για", "από", "προς", "ως", "έως", "χωρίς", "κατά", "μετά", "παρά",
        "εγώ", "εσύ", "αυτός", "αυτή", "αυτό", "εμείς", "εσείς", "αυτοί", "αυτές",
        "μου", "σου", "του", "μας", "σας", "είναι", "ήταν", "είμαι", "ήμουν",
        "εδώ", "εκεί", "τώρα", "τότε", "που", "πού", "πώς", "τι", "γιατί",
        "λοιπόν", "δηλαδή", "βασικά", "ξέρεις", "εντάξει", "περίμενε", "συγγνώμη",
    ]
}

private extension CleanupRule {
    static let greekMaskAbbreviationPeriods = CleanupRule(
        name: "protect Greek abbreviation periods",
        stage: .early
    ) { text, _ in
        GreekOrthography.maskAbbreviationPeriods(text)
    }

    static let greekMaskProtectedCommas = CleanupRule(
        name: "protect Greek decimal and lexical commas",
        stage: .early
    ) { text, _ in
        GreekOrthography.maskProtectedCommas(text)
    }

    static let greekMaskTechnicalQuestionMarks = CleanupRule(
        name: "protect URL query question marks",
        stage: .early,
        runsInTerminal: true
    ) { text, _ in
        GreekOrthography.maskTechnicalQuestionMarks(text)
    }

    static let greekRenderSpokenPunctuation = CleanupRule(
        name: "render explicit Greek spoken punctuation",
        stage: .early
    ) { text, _ in
        GreekOrthography.renderSpokenPunctuation(text)
    }

    static let greekPrepareQuestionMarks = CleanupRule(
        name: "prepare Greek question marks for shared capitalization",
        stage: .early
    ) { text, _ in
        GreekOrthography.prepareQuestionMarks(text)
    }

    /// Safe in terminals: the shared renderer is deliberately stricter in
    /// prose and renders flags/paths only for the terminal category.
    static let greekRenderSpokenSymbols = CleanupRule(
        name: "render Greek spoken code symbols",
        stage: .early,
        runsInTerminal: true
    ) { text, context in
        GreekSpokenSymbols.render(text, category: context.category)
    }

    static let greekNormalizeAnoTeleia = CleanupRule(
        name: "normalize Greek ano teleia encoding and spacing",
        stage: .afterPunctuation
    ) { text, _ in
        GreekOrthography.normalizeAnoTeleia(text)
    }

    static let greekNormalizeElisionApostrophe = CleanupRule(
        name: "normalize Greek elision apostrophes",
        stage: .afterPunctuation
    ) { text, _ in
        GreekOrthography.normalizeElisionApostrophes(text)
    }

    static let greekTightenGuillemets = CleanupRule(
        name: "tighten Greek guillemets",
        stage: .afterPunctuation
    ) { text, _ in
        GreekOrthography.tightenGuillemets(text)
    }

    static let greekRestoreProtectedCharacters = CleanupRule(
        name: "restore protected Greek punctuation",
        stage: .final,
        runsInTerminal: true
    ) { text, _ in
        GreekOrthography.restoreProtectedCharacters(text)
    }

    static let greekFinalizeQuestionMarks = CleanupRule(
        name: "write Greek question marks as U+003B",
        stage: .final
    ) { text, _ in
        GreekOrthography.finalizeQuestionMarks(text)
    }
}

private enum GreekOrthography {
    static let abbreviationPeriodSentinel = "\u{E110}"
    static let decimalCommaSentinel = "\u{E111}"
    static let lineBreakSentinel = "\u{E112}"
    static let paragraphBreakSentinel = "\u{E113}"
    static let technicalQuestionSentinel = "\u{E114}"

    /// Period-bearing abbreviations whose final dot is not a sentence break.
    /// The final restore also collapses a period appended by the shared
    /// terminal-punctuation pass when an abbreviation ends the dictation.
    private static let abbreviations = [
        "κ.λπ.", "κ.τ.λ.", "κτλ.", "κ.ο.κ.", "κ.τ.ό.", "κ.τ.τ.",
        "π.χ.", "δηλ.", "βλ.", "κ.ά.", "λ.χ.", "μ.μ.", "π.μ.",
    ]

    /// Microsoft documents the bare Greek dictation commands ερωτηματικό,
    /// θαυμαστικό, νέα γραμμή, and νέα παράγραφος. Ambiguous bare τελεία and
    /// κόμμα require the explicit "βάλε" form here.
    private static let spokenPunctuation: [(String, String)] = [
        ("βάλε άνω και κάτω τελεία", ":"),
        ("βάλε άνοιγμα εισαγωγικών", "«"),
        ("βάλε κλείσιμο εισαγωγικών", "»"),
        ("άνοιγμα εισαγωγικών", "«"),
        ("κλείσιμο εισαγωγικών", "»"),
        ("βάλε ελληνικό ερωτηματικό", "?"),
        ("ελληνικό ερωτηματικό", "?"),
        // The temporary dot lets the option-controlled shared capitalization
        // pass see a sentence boundary. It disappears when the sentinel is
        // restored, so no punctuation is invented at the line break.
        ("βάλε νέα παράγραφο", paragraphBreakSentinel + "."),
        ("νέα παράγραφος", paragraphBreakSentinel + "."),
        ("βάλε επόμενη γραμμή", lineBreakSentinel + "."),
        ("βάλε επόμενη σειρά", lineBreakSentinel + "."),
        ("βάλε νέα γραμμή", lineBreakSentinel + "."),
        ("βάλε νέα σειρά", lineBreakSentinel + "."),
        ("επόμενη γραμμή", lineBreakSentinel + "."),
        ("επόμενη σειρά", lineBreakSentinel + "."),
        ("νέα γραμμή", lineBreakSentinel + "."),
        ("νέα σειρά", lineBreakSentinel + "."),
        ("βάλε αποσιωπητικά", "…"),
        ("αποσιωπητικά", "…"),
        ("βάλε άνω τελεία", "·"),
        ("βάλε διπλή τελεία", ":"),
        ("άνω και κάτω τελεία", ":"),
        ("βάλε ερωτηματικό", "?"),
        ("ερωτηματικό", "?"),
        ("βάλε θαυμαστικό", "!"),
        ("θαυμαστικό", "!"),
        ("βάλε τελεία", "."),
        ("βάλε κόμμα", ","),
    ].sorted { $0.0.count > $1.0.count }

    static func maskAbbreviationPeriods(_ text: String) -> String {
        var out = text
        for abbreviation in abbreviations {
            let pattern = NSRegularExpression.escapedPattern(for: abbreviation)
            guard let regex = try? NSRegularExpression(
                pattern: #"(?i)(?<![\p{L}\p{N}])\#(pattern)(?![\p{L}\p{N}])"#
            ) else { continue }
            let matches = regex.matches(
                in: out,
                range: NSRange(out.startIndex..., in: out))
            for match in matches.reversed() {
                guard let range = Range(match.range, in: out) else { continue }
                let protected = out[range].replacingOccurrences(
                    of: ".", with: abbreviationPeriodSentinel)
                out.replaceSubrange(range, with: protected)
            }
        }
        return out
    }

    static func renderSpokenPunctuation(_ text: String) -> String {
        spokenPunctuation.reduce(text) { current, entry in
            current.replacingOccurrences(
                of: entry.0,
                with: entry.1,
                options: [.caseInsensitive])
        }
    }

    static func maskProtectedCommas(_ text: String) -> String {
        var out = replace(
            text,
            // Mask one self-contained numeric token, not comma-separated
            // sequences such as "1,2,3", whose commas need ordinary spacing.
            pattern: #"(?<![\d,])(\d+(?:\.\d{3})*),(\d+)(?![\d,])"#,
            template: "$1\(decimalCommaSentinel)$2")
        // ό,τι is a pronoun written with an internal comma, not punctuation
        // followed by a word boundary. The shared spacing pass must not turn
        // it into the conjunction phrase "ό, τι".
        out = replace(
            out,
            pattern: #"(?<=ό),(?=τι\b)"#,
            template: decimalCommaSentinel,
            options: [.caseInsensitive])
        return out
    }

    static func maskTechnicalQuestionMarks(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: #"(?i)\b(?:https?://|www\.)\S+"#)
        else { return text }
        var out = text
        let matches = regex.matches(
            in: out,
            range: NSRange(out.startIndex..., in: out))
        for match in matches.reversed() {
            guard let range = Range(match.range, in: out) else { continue }
            let protected = out[range].replacingOccurrences(
                of: "?", with: technicalQuestionSentinel)
            out.replaceSubrange(range, with: protected)
        }
        return out
    }

    /// The shared capitalization pass knows `?`, not Greek `;`. Temporarily
    /// expose a prose question as `?`, then restore the Greek mark at `.final`.
    /// The Greek-letter/closing-delimiter lookbehind leaves URLs and code such
    /// as `https://x?y=1` alone.
    static func prepareQuestionMarks(_ text: String) -> String {
        let canonical = text.replacingOccurrences(of: "\u{037E}", with: ";")
        return replace(
            canonical,
            pattern: #"(?<=[\p{Greek}»\)])\s*;"#,
            template: "?")
    }

    static func normalizeAnoTeleia(_ text: String) -> String {
        let canonical = text.replacingOccurrences(of: "\u{0387}", with: "·")
        // Restrict spacing repair to Greek prose. U+00B7 can also be a
        // mathematical operator between Latin identifiers.
        return replace(
            canonical,
            pattern: #"(?<=\p{Greek})\s*·\s*(?=\p{Greek})"#,
            template: "· ")
    }

    static func normalizeElisionApostrophes(_ text: String) -> String {
        replace(
            text,
            pattern: #"\b(σ|μ|γι|θ|απ|κατ|παρ|επ|αντ|δι)['΄’]\s*(?=\p{Greek})"#,
            template: "$1’ ",
            options: [.caseInsensitive])
    }

    static func tightenGuillemets(_ text: String) -> String {
        var out = replace(text, pattern: #"«\s+"#, template: "«")
        out = replace(out, pattern: #"\s+»"#, template: "»")
        return out
    }

    static func restoreProtectedCharacters(_ text: String) -> String {
        var out = text.replacingOccurrences(
            of: abbreviationPeriodSentinel, with: ".")
        out = replace(out, pattern: #"\.{2,}"#, template: ".")
        out = out.replacingOccurrences(of: decimalCommaSentinel, with: ",")
        out = replace(
            out,
            pattern: #"\s*\#(paragraphBreakSentinel)\.\s*"#,
            template: "\n\n")
        out = replace(
            out,
            pattern: #"\s*\#(lineBreakSentinel)\.\s*"#,
            template: "\n")
        out = out.replacingOccurrences(
            of: technicalQuestionSentinel, with: "?")
        return out
    }

    static func finalizeQuestionMarks(_ text: String) -> String {
        var out = text.replacingOccurrences(of: "\u{037E}", with: ";")
        out = replace(
            out,
            pattern: #"(?<=[\p{Greek}»\)])\?"#,
            template: ";")
        out = replace(out, pattern: #";(?:\s*;)+"#, template: ";")
        return out
    }

    private static func replace(
        _ text: String,
        pattern: String,
        template: String,
        options: NSRegularExpression.Options = []
    ) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: options)
        else { return text }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: template)
    }
}
