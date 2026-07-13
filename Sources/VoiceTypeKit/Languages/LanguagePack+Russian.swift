import Foundation

extension LanguagePack {
    /// Russian. Interrogative-word openers; the "ли" particle sits in second
    /// position, out of the first-word heuristic's reach, so intonation-only
    /// yes/no questions stay untouched (fail conservative).
    static let russian = LanguagePack(
        code: "ru",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["э", "ээ", "эм", "ммм", "гм"],
        spokenPunctuation: [:],
        questionPrefixWords: [
            "что", "кто", "когда", "где", "куда", "откуда", "почему",
            "зачем", "как", "какой", "какая", "какое", "какие", "сколько",
            "чей", "чья", "чьё", "чьи",
        ],
        questionSuffixParticles: [],
        promptAddendum: nil)
}
