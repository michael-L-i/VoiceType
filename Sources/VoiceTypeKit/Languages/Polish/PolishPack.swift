import Foundation

extension LanguagePack {
    /// Polish. "czy" is an explicit question particle and the interrogative
    /// words are unambiguous openers. "no" (≈ "yeah") carries meaning and
    /// stays.
    static let polish = LanguagePack(
        code: "pl",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["yyy", "eee", "hmm", "mmm", "ym"],
        spokenPunctuation: [:],
        questionPrefixWords: [
            "co", "kto", "kiedy", "gdzie", "dlaczego", "czemu", "jak", "jaki",
            "jaka", "jakie", "który", "która", "które", "ile", "czy",
        ],
        questionSuffixParticles: [],
        promptAddendum: nil)
}
