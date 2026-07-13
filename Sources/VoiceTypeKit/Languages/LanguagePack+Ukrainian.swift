import Foundation

extension LanguagePack {
    /// Ukrainian. Same shape as Russian: interrogative-word openers,
    /// intonation-only yes/no questions left alone. "є" (is) is a real word —
    /// only pure hesitation vowels are fillers.
    static let ukrainian = LanguagePack(
        code: "uk",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["е-е", "ем", "гм", "ммм", "еее"],
        spokenPunctuation: [:],
        questionPrefixWords: [
            "що", "хто", "коли", "де", "куди", "звідки", "чому", "навіщо",
            "як", "який", "яка", "яке", "які", "скільки", "чий", "чия",
            "чиє", "чиї",
        ],
        questionSuffixParticles: [],
        promptAddendum: nil)
}
