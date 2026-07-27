import Foundation

extension LanguagePack {
    /// Vietnamese (Tiếng Việt; keyed on "vi").
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - ừ / ờ / à / ơ, rồi, thì, là, mà, kiểu, and "nói chung": all can carry
    ///   discourse, grammatical, or lexical meaning. Only the longer hesitation
    ///   noises below are removed blindly; the prompt handles the rest in context.
    /// - ai / gì / sao and final không / chưa / à / ạ / hả / nhỉ / chứ: Vietnamese
    ///   questions are commonly in situ, while every one of these also occurs in
    ///   statements ("ai cũng đồng ý", "tôi chưa"). A deterministic question
    ///   heuristic would manufacture question marks, so explicit "dấu hỏi" is the
    ///   only zero-latency guarantee and contextual classification belongs to the
    ///   model.
    /// - Bare chấm / phẩy / gạch are not unconditional punctuation. Chấm is also
    ///   "grade/mark/dot", phẩy is used when speaking decimals, and gạch is an
    ///   ordinary verb/noun. Explicit dấu… commands render as punctuation; bare
    ///   tech words render only when `SpokenSymbols` sees a known extension,
    ///   identifier shape, email, flag, or terminal path.
    /// - Decimal/group separators are never converted blindly: versions, IP
    ///   addresses, foreign-formatted numbers, and code literals coexist with
    ///   Vietnamese prose. We preserve an already compact decimal comma through
    ///   the shared spacing pass and let the prompt normalize only clear prose.
    /// - No broad spelling or tone "repair" is deterministic. Vietnamese tones,
    ///   vowel contrasts, and regional consonants distinguish real words; an ASR
    ///   substitution needs sentence context and must not be guessed by regex.
    /// - `symbols` remains nil to satisfy the cross-pack contract. The pack-owned
    ///   spoken-symbol rule below invokes the Vietnamese vocabulary directly, so
    ///   it also repairs model output and can opt into terminal use safely.
    static let vietnamese = LanguagePack(
        code: "vi",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["ừm", "ờm", "ưm", "uhm", "hmm"],
        // Latin-pack model polish does not run this flat table. Vietnamese uses
        // a pack-owned rule instead so explicit commands are idempotent in both
        // the rules path and the model-output repair path.
        spokenPunctuation: [:],
        questionPrefixWords: [],
        questionSuffixParticles: [],
        stopwords: LanguagePack.vietnameseStopwords,
        prompt: .vietnamese,
        rules: [
            CleanupRule(
                name: "protect compact Vietnamese decimal commas",
                stage: .early,
                runsInTerminal: true
            ) { text, _ in
                VietnameseSymbols.protectNumericSeparators(in: text)
            },
            CleanupRule(
                name: "render explicit Vietnamese punctuation commands",
                stage: .early
            ) { text, _ in
                VietnameseSymbols.renderPunctuation(in: text)
            },
            CleanupRule(
                name: "render contextual Vietnamese code symbols",
                stage: .early,
                runsInTerminal: true
            ) { text, context in
                VietnameseSymbols.renderCode(in: text, category: context.category)
            },
            CleanupRule(
                name: "normalize Vietnamese punctuation and quotation spacing",
                stage: .afterPunctuation
            ) { text, context in
                VietnameseSymbols.normalizeTypography(in: text, category: context.category)
            },
            CleanupRule(
                name: "format Vietnamese percent and đồng signs",
                stage: .afterPunctuation
            ) { text, context in
                VietnameseSymbols.normalizeLocalizedNumbers(in: text, category: context.category)
            },
            CleanupRule(
                name: "restore protected Vietnamese separators and line breaks",
                stage: .final,
                runsInTerminal: true
            ) { text, _ in
                VietnameseSymbols.restoreProtectedCharacters(in: text)
            },
        ],
        // The guard sees whitespace tokens, not multiword symbol phrases, so it
        // needs every component that legitimately disappears when "mở ngoặc
        // kép", "gạch chéo", or "dấu phần trăm" becomes punctuation.
        spokenSymbolWords: [
            "a", "còng", "dấu", "chấm", "phẩy", "hỏi", "than", "cảm", "thán",
            "hai", "ba", "lửng", "mở", "đóng", "ngoặc", "kép", "đơn", "vuông",
            "xuống", "dòng", "đoạn", "gạch", "dưới", "ngang", "nối", "chéo",
            "ngược", "ngã", "bằng", "cộng", "trừ", "sao", "phần", "trăm",
            "thăng", "đứng",
        ],
        modelLeadInPatterns: [
            #"(?i)^\s*(?:vâng|được|chắc chắn)[,!.]+\s*(?:đây là|sau đây là)[^:\n]{0,80}:\s+"#,
            #"(?i)^\s*(?:đây là|sau đây là)\s+(?:văn bản|bản chép|nội dung)[^:\n]{0,80}:\s+"#,
        ])

    /// Function words are unsafe identifier neighbors and weak evidence for the
    /// model faithfulness guard. Kept broad enough that phrases such as "hãy
    /// gạch dưới từ này" never become an accidental snake_case identifier.
    static let vietnameseStopwords: Set<String> = [
        "và", "hoặc", "nhưng", "mà", "thì", "là", "của", "cho", "với", "từ",
        "đến", "trong", "ngoài", "trên", "dưới", "tại", "về", "bởi", "vì",
        "để", "theo", "giữa", "qua", "bằng",
        "tôi", "ta", "mình", "chúng", "bạn", "anh", "chị", "em", "họ", "nó",
        "ai", "gì", "nào",
        "có", "không", "chưa", "được", "bị", "đang", "đã", "sẽ", "muốn", "cần",
        "hãy", "nên", "phải",
        "này", "đó", "kia", "đây", "đấy", "ấy",
        "à", "ạ", "ư", "hả", "nhỉ", "nhé", "nha", "chứ", "cơ", "thôi", "rồi",
        // Contextual fillers and correction markers may legitimately disappear
        // in the model path, so they do not prove that the opening was lost.
        "ừ", "ờ", "ơ", "kiểu", "ý", "nhầm", "xin", "lỗi",
    ]
}
