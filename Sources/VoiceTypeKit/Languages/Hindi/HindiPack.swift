import Foundation

extension LanguagePack {
    /// Hindi in Devanagari (hi).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - मतलब / यानी / तो / अच्छा / अरे / बस / वो: each is common as a
    ///   discourse marker, but each also carries ordinary lexical or pragmatic
    ///   meaning. Only the model may remove one, with context.
    /// - हाँ / हम्म / हूँ: these can be an answer, acknowledgement, or
    ///   deliberate thinking signal. They are never blind fillers.
    /// - ना / न / है ना: Hindi questions are often marked only by intonation,
    ///   while these forms also negate, soften requests, or add emphasis. They
    ///   are left to the model rather than used as suffix heuristics.
    /// - पीरियड / डॉट: both are productive nouns outside dictation ("class
    ///   period", a visual dot). पूर्ण विराम is safe as punctuation; डॉट is
    ///   rendered only by the guarded technical-symbol rule.
    /// - Number values, digit scripts, grouping, dates, and abbreviations are
    ///   preserved deterministically. Their separators are protected from the
    ///   shared punctuation pass, but changing their representation requires
    ///   meaning and therefore belongs to the prompt.
    /// - Hindi-English code-switching is normal. The rules never translate,
    ///   transliterate, respell a name, or "correct" a mixed-script token.
    ///
    /// Hindi has no letter case, so `capitalizedStandalonePronoun` and
    /// `casingLocaleIdentifier` remain nil. `symbols` also remains nil because
    /// shared integrity intentionally reserves that field for English; the
    /// language-owned `render Hindi technical symbols` rule invokes the same
    /// guarded renderer and repairs model output as well.
    static let hindi = LanguagePack(
        code: "hi",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: "।",
        // Non-lexical filled-pause spellings only. The content-capable Hindi
        // discourse markers listed above stay out.
        fillers: ["उमम्", "उम्", "उम्म", "उह", "उह्"],
        // Established Hindi dictation names and standard punctuation names.
        // Technical डॉट/डैश/etc. use the context-guarded vocabulary instead.
        spokenPunctuation: [
            "विस्मयादिबोधक चिह्न": "!",
            "विस्मयसूचक चिह्न": "!",
            "एक्सक्लेमेशन पॉइंट": "!",
            "प्रश्नवाचक चिह्न": "?",
            "प्रश्न चिह्न": "?",
            "प्रश्नचिह्न": "?",
            "पूर्ण विराम": "।",
            "पूर्णविराम": "।",
            "अल्प विराम": ",",
            "अल्पविराम": ",",
            "कॉमा": ",",
            "अर्ध विराम": ";",
            "अर्धविराम": ";",
            "सेमीकोलन": ";",
            "उपविराम": ":",
            "कोलन": ":",
            "उद्धरण शुरू": "“",
            "उद्धरण समाप्त": "”",
            "संक्षेप चिह्न": "॰",
        ],
        // Direct-question openers only. क्या is also Hindi's ordinary polar
        // question marker; inflected क-/कैस-/कितन- forms cover wh-questions.
        questionPrefixWords: [
            "क्या", "क्यों", "कब", "कहाँ", "किधर",
            "कौन", "किस", "किसने", "किसे", "किसको",
            "किसका", "किसकी", "किसके",
            "कैसे", "कैसा", "कैसी",
            "कितना", "कितनी", "कितने",
        ],
        questionSuffixParticles: ["क्या"],
        questionMark: "?",
        stopwords: LanguagePack.hindiStopwords,
        prompt: .hindi,
        rules: HindiCleanupRules.all,
        // Respect an already-present ASCII period because it may close a Latin
        // abbreviation or identifier. Hindi rules convert only clearly
        // sentence-final periods adjacent to Devanagari; new prose gets ।.
        terminalMarks: LanguagePack.defaultTerminalMarks.union(["।", "॥"]),
        spokenSymbolWords: HindiCleanupRules.spokenSymbolWords,
        modelLeadInPatterns: [
            #"^\s*(?:ज़रूर|बिलकुल|ठीक है)[,!.।]+\s*(?:यहाँ|यह रहा|ये रहा)[^\n:]{0,60}(?:साफ़|सुधारा|संशोधित)[^\n:]{0,30}(?:प्रतिलेख|टेक्स्ट|पाठ)[^\n:]{0,20}:\s+"#,
            #"^\s*(?:यहाँ|यह रहा|ये रहा)[^\n:]{0,50}(?:साफ़ किया हुआ|सुधारा हुआ|संशोधित)(?:\s+(?:प्रतिलेख|टेक्स्ट|पाठ))?[^\n:]{0,20}:\s+"#,
        ])

    /// Function words are weak evidence for the faithfulness guard and unsafe
    /// neighbors for a dictated identifier. This is intentionally broader
    /// than the filler set: none of these words is ever removed.
    static let hindiStopwords: Set<String> = [
        "और", "या", "लेकिन", "पर", "तो", "कि", "क्योंकि", "अगर", "जब",
        "का", "की", "के", "को", "से", "में", "तक", "लिए", "द्वारा",
        "मैं", "हम", "तुम", "आप", "वह", "वो", "यह", "ये", "वे",
        "इस", "उस", "इन", "उन", "मेरा", "मेरी", "मेरे", "अपना", "अपने",
        "है", "हैं", "था", "थी", "थे", "हो", "हूँ", "होगा", "होगी",
        "कर", "करना", "किया", "गया", "गई", "रहा", "रही", "रहे",
        "न", "ना", "नहीं", "हाँ", "जी", "भी", "ही", "एक",
        "मतलब", "यानी", "अच्छा", "अरे", "बस", "खैर",
    ]
}

/// Hindi-specific deterministic behavior. Every rule is declared here rather
/// than branching shared cleanup code, and every paired placeholder has the
/// same terminal policy so it can never leak into a command.
enum HindiCleanupRules {
    private static let numericComma = "\u{F0000}"
    private static let numericPeriod = "\u{F0001}"
    private static let leadingLatin = "\u{F0002}"
    private static let lineBreak = "\u{F0003}"
    private static let paragraphBreak = "\u{F0004}"
    private static let abbreviationPeriod = "\u{F0005}"

    static let spokenSymbolWords: Set<String> = [
        "डॉट", "अंडरस्कोर", "डैश", "हाइफ़न", "हाइफन", "स्लैश",
        "टिल्ड", "टिल्डा", "कॉमा", "ऐट", "एट",
        "खुला", "ओपन", "बंद", "क्लोज़", "क्लोज",
        "कोष्ठक", "पैरन", "पैरेंथेसिस", "ब्रैकेट",
    ]

    static let all: [CleanupRule] = [
        CleanupRule(
            name: "protect Hindi numeric separators",
            stage: .early,
            runsInTerminal: true
        ) { text, _ in
            replace(
                replace(text,
                        pattern: #"(?<=[0-9०-९]),(?=[0-9०-९])"#,
                        template: numericComma),
                pattern: #"(?<=[0-9०-९])\.(?=[0-9०-९])"#,
                template: numericPeriod)
        },
        CleanupRule(
            name: "protect Hindi abbreviation periods",
            stage: .early
        ) { text, _ in
            let common = #"(डॉ|प्रो|सुश्री|श्रीमती|श्री|पं|सं|क्र|वि|ई|रा|मा|से|मी|कि|ग्रा)"#
            var out = replace(text,
                              pattern: common + #"\.(?=\s+[\u0900-\u097F])"#,
                              template: "$1" + abbreviationPeriod)
            // A sequence such as एम. ए. or रा.कृ. is an abbreviation even
            // when it is not in the small common-title list above. Mask the
            // first dot only when another short dotted Devanagari component
            // follows, then walk the remainder of that same sequence.
            out = replace(
                out,
                pattern: #"(?<=[\u0900-\u097F])\.(?=\s*[\u0900-\u097F]{1,4}\.)"#,
                template: abbreviationPeriod)
            for _ in 0..<4 {
                out = replace(
                    out,
                    pattern: abbreviationPeriod + #"(\s*)([\u0900-\u097F]{1,4})\."#,
                    template: abbreviationPeriod + "$1$2" + abbreviationPeriod)
            }
            return out
        },
        CleanupRule(
            name: "mask Hindi dictated line breaks",
            stage: .early
        ) { text, _ in
            var out = text
            for phrase in ["नया पैराग्राफ़", "नया पैराग्राफ", "नया अनुच्छेद"] {
                out = out.replacingOccurrences(of: phrase, with: paragraphBreak)
            }
            for phrase in ["नई पंक्ति", "नई लाइन"] {
                out = out.replacingOccurrences(of: phrase, with: lineBreak)
            }
            return out
        },
        CleanupRule(
            name: "render Hindi technical symbols",
            stage: .early,
            runsInTerminal: true
        ) { text, context in
            guard shouldRenderTechnicalSymbols(in: text) else { return text }
            return SpokenSymbols.render(text, category: context.category,
                                        vocabulary: .hindiRuleVocabulary)
        },
        CleanupRule(
            name: "protect leading Latin token from Hindi casing",
            stage: .early
        ) { text, _ in
            replace(text,
                    pattern: #"^([“"'‘]?)(?=[a-z])"#,
                    template: "$1" + leadingLatin)
        },
        CleanupRule(
            name: "smarten balanced Hindi quotation marks",
            stage: .afterPunctuation
        ) { text, _ in
            let doubles = replace(
                text,
                pattern: #""([^"\n]*[\u0900-\u097F][^"\n]*)""#,
                template: "“$1”")
            return replace(
                doubles,
                pattern: #"'([^'\n]*[\u0900-\u097F][^'\n]*)'"#,
                template: "‘$1’")
        },
        CleanupRule(
            name: "normalize Hindi sentence periods to danda",
            stage: .afterPunctuation
        ) { text, _ in
            let beforeClosingQuote = replace(
                text,
                pattern: #"(?<=[\u0900-\u097F])\.(?=[”’])"#,
                template: "।")
            return replace(
                beforeClosingQuote,
                pattern: #"(?<=[\u0900-\u097F”’)\]])\.(?=\s|$)"#,
                template: "।")
        },
        CleanupRule(
            name: "normalize Hindi danda and paired-mark spacing",
            stage: .afterPunctuation
        ) { text, _ in
            var out = replace(text, pattern: #"।\s*।"#, template: "।")
            out = replace(out, pattern: #"\s+([।॥])"#, template: "$1")
            out = replace(out, pattern: #"([।॥])(?=\S)"#, template: "$1 ")
            out = replace(out, pattern: #"([“‘(\[])\s+"#, template: "$1")
            out = replace(out, pattern: #"\s+([”’)\]])"#, template: "$1")
            return out
        },
        CleanupRule.regex(
            name: "space Hindi prose colon",
            stage: .afterPunctuation,
            pattern: #"(?<=[\u0900-\u097F]):(?=[\u0900-\u097F])"#,
            template: ": "
        ),
        CleanupRule(
            name: "normalize Hindi currency and percent spacing",
            stage: .afterPunctuation
        ) { text, _ in
            let currency = replace(
                text,
                pattern: #"₹\s+(?=[0-9०-९])"#,
                template: "₹")
            return replace(
                currency,
                pattern: #"(?<=[0-9०-९])\s+%"#,
                template: "%")
        },
        CleanupRule(
            name: "restore Hindi numeric separators",
            stage: .final,
            runsInTerminal: true
        ) { text, _ in
            text.replacingOccurrences(of: numericComma, with: ",")
                .replacingOccurrences(of: numericPeriod, with: ".")
        },
        CleanupRule(
            name: "restore Hindi abbreviation periods",
            stage: .final
        ) { text, _ in
            text.replacingOccurrences(of: abbreviationPeriod, with: ".")
        },
        CleanupRule(
            name: "restore leading Latin token",
            stage: .final
        ) { text, _ in
            text.replacingOccurrences(of: leadingLatin, with: "")
        },
        CleanupRule(
            name: "restore Hindi dictated line breaks",
            stage: .final
        ) { text, _ in
            let paragraphs = replace(
                text,
                pattern: #"\s*"# + paragraphBreak + #"\s*"#,
                template: "\n\n")
            return replace(
                paragraphs,
                pattern: #"\s*"# + lineBreak + #"\s*"#,
                template: "\n")
        },
    ]

    private static func replace(_ text: String, pattern: String,
                                template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: template)
    }

    /// `SpokenSymbols.render` also tidies literal symbol tokens already in the
    /// text. Do not invoke it unless Hindi actually contains a dictated trigger;
    /// that keeps ordinary parenthetical prose byte-for-byte until our explicit
    /// spacing rules handle it.
    private static func shouldRenderTechnicalSymbols(in text: String) -> Bool {
        let tokens = text.split(whereSeparator: \.isWhitespace)
            .map { String($0).lowercased() }
        let singleTokenTriggers: Set<String> = [
            "डॉट", "अंडरस्कोर", "डैश", "हाइफ़न", "हाइफन",
            "स्लैश", "टिल्ड", "टिल्डा", "ऐट", "एट",
        ]
        if tokens.contains(where: singleTokenTriggers.contains) { return true }

        let openClose: Set<String> = ["खुला", "ओपन", "बंद", "क्लोज़", "क्लोज"]
        let containers: Set<String> = [
            "कोष्ठक", "पैरन", "पैरेंथेसिस", "ब्रैकेट",
        ]
        guard tokens.count >= 2 else { return false }
        return tokens.indices.dropLast().contains { index in
            openClose.contains(tokens[index])
                && containers.contains(tokens[index + 1])
        }
    }
}
