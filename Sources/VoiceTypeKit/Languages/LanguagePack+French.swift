import Foundation

extension LanguagePack {
    /// French. "ben"/"bah"/"quoi" carry meaning too often to strip blindly;
    /// only the pure hesitation vowels go. Question openers are interrogative
    /// words plus "est-ce" (the "est-ce que" frame is unambiguous).
    static let french = LanguagePack(
        code: "fr",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["euh", "heu", "hum", "hem"],
        spokenPunctuation: [:],
        questionPrefixWords: [
            "est-ce", "pourquoi", "comment", "quand", "où", "qui", "quel",
            "quelle", "quels", "quelles", "combien", "lequel", "laquelle",
        ],
        questionSuffixParticles: [],
        promptAddendum: nil)
}
