import Foundation

extension LanguagePack {
    /// Turkish. "şey" (the most common hesitation) literally means "thing"
    /// and stays — LLM territory. The mi/mı/mu/mü question particles are
    /// written as separate words in second-to-last position, out of the
    /// single-character suffix heuristic's reach, so only interrogative-word
    /// openers are probed.
    static let turkish = LanguagePack(
        code: "tr",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["ııı", "eee", "hmm", "iii"],
        spokenPunctuation: [:],
        questionPrefixWords: [
            "ne", "neden", "niye", "niçin", "kim", "nerede", "nereye",
            "nereden", "nasıl", "hangi", "kaç",
        ],
        questionSuffixParticles: [],
        promptAddendum: nil)
}
