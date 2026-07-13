import Foundation

extension LanguagePack {
    /// Korean. Written with spaces and western punctuation, so the Latin-style
    /// passes apply. 어 and 그 are everyday words (oh / that) — only the pure
    /// hesitation hums are fillers. Yes/no questions end in verb endings
    /// (-까/-니/-나요) that a first-word probe can't see; the interrogative
    /// words still catch wh-questions.
    static let korean = LanguagePack(
        code: "ko",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["음", "흠", "으음"],
        spokenPunctuation: [:],
        questionPrefixWords: [
            "뭐", "무엇", "누가", "누구", "언제", "어디", "어디서", "왜",
            "어떻게", "몇",
        ],
        questionSuffixParticles: [],
        promptAddendum: nil)
}
