import Foundation

extension LanguagePack {
    /// Japanese (keyed on "ja").
    ///
    /// Ambiguity policy — deliberately NOT handled deterministically:
    /// - まる／てん as spoken punctuation: both are everyday words (circle,
    ///   point); only the unambiguous technical names 句点／読点 render.
    /// - あの without the trailing sound mark: it's the demonstrative "that";
    ///   only the clearly-drawn-out あのー is a filler.
    /// - か as a question particle: sentence-final か is often not a question
    ///   (そうか、行こうか), so no suffix heuristic — the engines' own
    ///   punctuation and the LLM handle ？.
    static let japanese = LanguagePack(
        code: "ja",
        separatesWordsWithSpaces: false,
        usesFullWidthPunctuation: true,
        terminalPeriod: "。",
        fillers: ["えーと", "ええと", "えっと", "あのー"],
        spokenPunctuation: [
            "句点": "。",
            "読点": "、",
            "疑問符": "？",
            "感嘆符": "！",
            "改行": "\n",
        ],
        questionPrefixWords: [],
        questionSuffixParticles: [],
        promptAddendum: """
        - The dictation is Japanese. Use full-width Japanese punctuation \
        （、。！？）and never insert spaces between Japanese characters.
        - Keep embedded English words, file names, and identifiers in ASCII, \
        with ASCII punctuation inside them.
        - Always drop drawn-out hesitations like えーと・えっと・あのー; keep \
        every content word exactly as spoken.
        """)
}
