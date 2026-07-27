import Foundation

extension LanguagePack {
    /// Arabic (Modern Standard Arabic and the regional varieties covered by
    /// the app's `ar` locales).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `آه` / `اه` can express assent, pain, surprise, or recognition, while
    ///   `يعني`, `طيب`, `مثلاً`, and `والله` all have ordinary lexical or
    ///   discourse meanings. The deterministic pass never removes them. The
    ///   prompt may remove one only when context makes it a pure hesitation.
    /// - Bare `نقطة`, `فاصلة`, and `شرطة` can mean a point, a separator/break,
    ///   and the police. Only explicit phrases such as `علامة استفهام` render
    ///   unconditionally. Technical uses of the ambiguous words are handled by
    ///   the guarded spoken-symbol rule, where a known extension or terminal
    ///   context supplies evidence.
    /// - Arabic has no letter case. In particular, we do not borrow English
    ///   capitalization for a Latin identifier embedded in Arabic.
    /// - Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩), European digits (0123456789), and
    ///   their separators vary by region and context. Cleanup preserves the
    ///   transcriber's digit family and numeric punctuation instead of
    ///   silently converting either.
    /// - Quotation styles, abbreviations, dates, and currency presentation vary
    ///   across Arabic publishing traditions and locales. Blind normalization
    ///   would destroy valid input, so these stay as dictated and the prompt
    ///   only asks for internal consistency.
    /// - No bidi controls are inserted. They are invisible payload that can
    ///   surprise users after pasting; the receiving app owns visual layout.
    static let arabic = LanguagePack(
        code: "ar",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Written elongations that have no lexical reading. `أمم` ("nations"),
        // `همم` ("concerns/ambitions"), and `آه` are intentionally excluded.
        fillers: ["إمم", "إممم", "ممم", "مممم"],
        // Microsoft Word's documented Arabic dictation commands, limited to
        // multi-word phrases that unambiguously name a mark. Bare نقطة and
        // فاصلة are deliberately left to the guarded symbol rule / model.
        spokenPunctuation: ArabicSpokenPunctuation.mapping,
        // Initial interrogatives that are strongly question-bearing. We omit
        // ما / من / كم / أي because each has frequent non-question readings.
        questionPrefixWords: ["هل", "أين", "متى", "لماذا", "كيف", "ماذا"],
        questionSuffixParticles: [],
        questionMark: "؟",
        stopwords: LanguagePack.arabicStopwords,
        // Arabic has no uppercase/lowercase distinction.
        capitalizedStandalonePronoun: nil,
        prompt: .arabic,
        rules: ArabicCleanupRules.all,
        casingLocaleIdentifier: nil,
        terminalMarks: LanguagePack.defaultTerminalMarks.union(["؟", "،", "؛"]),
        spokenSymbolWords: ArabicSpokenSymbols.spokenWords,
        modelLeadInPatterns: [
            #"^\s*(?:بالتأكيد[،,:]?\s*)?(?:إليك|هذا هو)\s+(?:النص\s+)?(?:المنقح|المنظف|المصحح)\s*[:：]\s*"#,
        ])

    /// Function words are conservative guard hints, not a deletion list.
    /// Arabic clitics often attach to their host, so only standalone forms are
    /// useful here.
    static let arabicStopwords: Set<String> = [
        "أنا", "نحن", "أنت", "أنتم", "هو", "هي", "هم", "هذا", "هذه", "ذلك", "تلك",
        "هنا", "هناك", "الذي", "التي", "الذين",
        "في", "من", "إلى", "على", "عن", "مع", "بين", "عند", "لدى",
        "و", "أو", "ثم", "لكن", "بل", "أن", "إن", "كان", "يكون", "تكون",
        "لا", "لم", "لن", "ما", "هل", "يا",
        // Explicit correction markers may legitimately disappear with the
        // retracted words, so they do not prove that an opening was dropped.
        "قصدي", "أقصد", "عفوا", "عفوًا",
    ]
}
