import Foundation

extension LanguagePack {
    /// Italian. Interrogative-word openers only — Italian yes/no questions
    /// don't invert, so verbs would misfire on statements. "che" is excluded:
    /// as a first word it opens exclamations ("Che bello!") as often as
    /// questions. "eh"/"beh" are meaningful interjections, not fillers.
    static let italian = LanguagePack(
        code: "it",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["ehm", "uhm", "mmm"],
        spokenPunctuation: [:],
        questionPrefixWords: [
            "cosa", "chi", "quando", "dove", "perché", "come", "quale",
            "quali", "quanto", "quanta", "quanti", "quante",
        ],
        questionSuffixParticles: [],
        promptAddendum: nil)
}
