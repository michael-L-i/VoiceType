import Foundation

extension LanguagePack {
    /// Vietnamese. Question markers are mostly sentence-final words (không,
    /// gì, sao) — multi-character, so outside the suffix heuristic's reach;
    /// only the clearly interrogative openers are probed. "thì"/"là"/"mà"
    /// hesitations carry grammar and stay.
    static let vietnamese = LanguagePack(
        code: "vi",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["ừm", "ờm", "hmm"],
        spokenPunctuation: [:],
        questionPrefixWords: ["ai", "sao"],
        questionSuffixParticles: [],
        promptAddendum: nil)
}
