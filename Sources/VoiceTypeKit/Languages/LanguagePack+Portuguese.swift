import Foundation

extension LanguagePack {
    /// Portuguese (Brazilian conventions; keyed on "pt", applies to pt-PT
    /// dictation too). Interrogative-word openers only — no inversion in
    /// yes/no questions. "né"/"tipo"/"então" carry meaning too often to strip
    /// blindly. "o que" can't be probed (the heuristic sees only "o").
    static let portuguese = LanguagePack(
        code: "pt",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["hum", "uhm", "ãh", "hã", "éé"],
        spokenPunctuation: [:],
        questionPrefixWords: [
            "quê", "quem", "quando", "onde", "aonde", "cadê", "qual", "quais",
            "quanto", "quanta", "quantos", "quantas", "como", "porque", "por",
        ],
        questionSuffixParticles: [],
        promptAddendum: nil)
}
