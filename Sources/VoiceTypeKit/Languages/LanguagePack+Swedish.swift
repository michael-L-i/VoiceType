import Foundation

extension LanguagePack {
    /// Swedish. Verb-first questions invert like English, so finite verbs are
    /// reliable openers alongside the interrogative words.
    static let swedish = LanguagePack(
        code: "sv",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["eh", "öh", "öhm", "ehm", "hmm"],
        spokenPunctuation: [:],
        questionPrefixWords: [
            "vad", "vem", "när", "var", "vart", "varför", "hur", "vilken",
            "vilket", "vilka", "är", "kan", "ska", "har", "gör", "finns",
            "vill", "får", "blir",
        ],
        questionSuffixParticles: [],
        promptAddendum: nil)
}
