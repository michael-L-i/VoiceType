import Foundation

extension LanguagePack {
    /// Simplified/Traditional Chinese (Mandarin dictation; keyed on "zh").
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - 那个 / 就是 / 然后 / 对: real words at least as often as hesitations.
    ///   The deterministic pass never removes them; the LLM pass may, when
    ///   context shows they carry no meaning (see `promptAddendum`).
    /// - 点 ("dot"): far too ambiguous for a blind rule — o'clock (三点),
    ///   decimals (三点一四), and "a bit" (快点) all outnumber the tech-dictation
    ///   sense. Dictating "main 点 py" is left to the LLM path for now.
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
        promptAddendum: """
        - The dictation is Chinese. Use full-width Chinese punctuation \
        （，。？！：；）for Chinese text and never insert spaces between \
        Chinese characters.
        - Keep embedded English words, file names, and identifiers in ASCII, \
        with ASCII punctuation inside them.
        - Always drop the fillers 嗯 and 呃. Drop 那个 or 就是 only when it is \
        clearly a hesitation carrying no meaning; when it points at something \
        (那个方案 = "that plan") or asserts (就是最好的), it is content — keep \
        it. When in doubt, keep it.
        """)
}
