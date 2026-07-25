import Foundation

extension LanguagePack {
    /// English. The filler lexicon and interrogative list moved here verbatim
    /// from `RuleBasedCleanup` / `CleanupPolish` so behavior is provably
    /// unchanged. Spoken-symbol rendering stays in `SpokenSymbols` (a richer
    /// token pipeline than the pack's flat replacement table), so
    /// `spokenPunctuation` is deliberately empty.
    static let english = LanguagePack(
        code: "en",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Kept conservative: only tokens that are almost never meaningful
        // content. We deliberately do NOT strip "like", "so", "well" — they're
        // too often real words.
        fillers: [
            "um", "umm", "uh", "uhh", "uhm", "er", "erm", "ah", "hmm", "mhm",
        ],
        spokenPunctuation: [:],
        // Words that open a direct question.
        questionPrefixWords: [
            "what", "where", "when", "who", "whom", "whose", "why", "how",
            "is", "are", "am", "was", "were", "do", "does", "did",
            "can", "could", "will", "would", "should", "shall", "may", "might",
        ],
        questionSuffixParticles: [],
        promptAddendum: nil)
}
