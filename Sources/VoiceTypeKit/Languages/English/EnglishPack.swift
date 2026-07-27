import Foundation

extension LanguagePack {
    /// English — the reference pack. It is the only language that currently
    /// fills in every optional field, so it doubles as the worked example of
    /// what a complete pack looks like.
    ///
    /// Nothing here is English-flavored *behavior*: the shared engine no longer
    /// knows the word "um", the pronoun "I", or the trigger word "dot". It
    /// reads them from this file, exactly as it reads German's from German's.
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
        // Empty by design: English uses the richer `SpokenSymbolVocabulary`
        // token pipeline below rather than the flat replacement table.
        spokenPunctuation: [:],
        // Words that open a direct question.
        questionPrefixWords: [
            "what", "where", "when", "who", "whom", "whose", "why", "how",
            "is", "are", "am", "was", "were", "do", "does", "did",
            "can", "could", "will", "would", "should", "shall", "may", "might",
        ],
        questionSuffixParticles: [],
        stopwords: LanguagePack.englishStopwords,
        symbols: .english,
        capitalizedStandalonePronoun: "i",
        prompt: .english,
        rules: LanguagePack.englishRules)

    /// Function words too common to prove anything about whether the opening of
    /// a dictation survived into the output, and too common to be joined into a
    /// dictated identifier. Declared separately because
    /// `SpokenSymbolVocabulary.english` builds on it before
    /// `LanguagePack.english` itself finishes initializing.
    static let englishStopwords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "so", "to", "of", "in", "on",
        "at", "for", "with", "about", "from",
        "i", "we", "you", "he", "she", "they", "it", "me", "my", "your", "our", "us",
        "is", "are", "was", "were", "be", "been", "am",
        "do", "does", "did", "have", "has", "had",
        "there", "here", "this", "that", "these", "those",
        "okay", "ok", "yeah", "yes", "well", "just", "like", "really",
        // Self-correction markers: legitimately removed along with the words
        // they retract, so they prove nothing about the opening.
        "no", "not", "wait", "actually", "sorry",
    ]
}
