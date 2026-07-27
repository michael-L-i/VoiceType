import Foundation

extension LanguagePack {
    /// Simplified/Traditional Chinese (Mandarin dictation; keyed on "zh").
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - 那个 / 就是 / 然后 / 对: real words at least as often as hesitations.
    ///   The deterministic pass never removes them; the LLM pass may, when
    ///   context shows they carry no meaning (see the pack's prompt addendum).
    /// - 点 ("dot") remains absent from blind spoken punctuation: o'clock
    ///   (三点), decimals (三点一四), and "a bit" (快点) all outnumber the
    ///   technical sense. A guarded rule renders it only before a known Latin
    ///   file extension or inside an email anchored by 艾特 plus a known TLD.
    /// - Spoken numerals, dates, classifiers, quantities, and currency keep the
    ///   speaker's chosen form. Converting 二零二六 to 2026 or 元 to ¥ is a
    ///   register/meaning decision, not deterministic cleanup.
    /// - 儿化 and repeated characters (看看 / 慢慢) are lexical morphology,
    ///   never stutter to collapse. Characters that merely resemble discourse
    ///   fillers inside words or idioms (呃逆 / 对牛弹琴) remain content.
    /// - 呢 / 吧 as question particles: too often non-interrogative; only 吗 is
    ///   reliable enough for the deterministic question-mark rule.
    static let chinese = LanguagePack(
        code: "zh",
        separatesWordsWithSpaces: false,
        usesFullWidthPunctuation: true,
        terminalPeriod: "。",
        // Pure disfluencies only. 呃 has a rare literary reading (呃逆), which
        // the boundary-anchored removal in RuleBasedCleanup already protects
        // mid-sentence; the trade-off is documented there.
        fillers: ["嗯", "呃"],
        // The iOS-dictation convention: spoken names render unconditionally,
        // longest name first, idempotent when the engine already produced the
        // mark. Yes, that means dictating ABOUT punctuation ("加一个句号")
        // renders the mark — same trade-off Apple's dictation makes.
        spokenPunctuation: [
            "句号": "。",
            "逗号": "，",
            "顿号": "、",
            "问号": "？",
            "感叹号": "！",
            "叹号": "！",
            "冒号": "：",
            "分号": "；",
            "左括号": "（",
            "右括号": "）",
            "左引号": "“",
            "右引号": "”",
            "省略号": "……",
            "另起一行": "\n",
            "新段落": "\n\n",
            "换行": "\n",
        ],
        questionPrefixWords: [],
        questionSuffixParticles: ["吗"],
        questionMark: "？",
        prompt: .addendumOnly("""
        - The dictation is Chinese. Use full-width Chinese punctuation \
        （，。？！：；）for Chinese text and never insert spaces between \
        Chinese characters.
        - Keep embedded English words, file names, and identifiers in ASCII, \
        with ASCII punctuation inside them.
        - Always drop the fillers 嗯 and 呃. Drop 那个 or 就是 only when it is \
        clearly a hesitation carrying no meaning; when it points at something \
        (那个方案 = "that plan") or asserts (就是最好的), it is content — keep \
        it. When in doubt, keep it.
        """),
        rules: [
            .renderChineseSpokenSymbols,
            .chineseFullWidthMarkSpacing,
        ],
        spokenSymbolWords: ChineseSpokenSymbols.spokenWords)
}

private extension CleanupRule {
    /// Chinese full-width punctuation is set solid even when the neighboring
    /// run is Latin (`TypeScript，Python`). `CJKPunctuation` intentionally
    /// guards its shared spacing changes on CJK letters, so this pack-owned
    /// rule removes only horizontal ASR padding immediately around an existing
    /// Chinese mark. Newlines and ordinary Latin word spaces remain untouched.
    static let chineseFullWidthMarkSpacing = CleanupRule.regex(
        name: "Chinese full-width punctuation spacing beside Latin text",
        stage: .afterPunctuation,
        pattern: #"[ \t]+(?=[。，、！？：；])|(?<=[。，、！？：；])[ \t]+"#,
        template: "")
}
