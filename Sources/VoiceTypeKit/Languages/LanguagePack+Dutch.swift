import Foundation

extension LanguagePack {
    /// Dutch. Verb-first questions invert like English, so finite verbs are
    /// reliable question openers alongside the interrogative words.
    static let dutch = LanguagePack(
        code: "nl",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["uh", "uhm", "eh", "ehm", "hmm"],
        spokenPunctuation: [:],
        questionPrefixWords: [
            "wat", "wie", "wanneer", "waar", "waarom", "hoe", "welk", "welke",
            "is", "zijn", "kan", "kun", "kunnen", "heb", "heeft", "hebben",
            "mag", "moet", "moeten", "zal", "zullen", "ben", "bent", "wil",
            "willen", "ga", "gaat", "gaan",
        ],
        questionSuffixParticles: [],
        promptAddendum: nil)
}
