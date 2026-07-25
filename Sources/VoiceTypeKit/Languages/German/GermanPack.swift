import Foundation

extension LanguagePack {
    /// German. Verb-first questions invert like English, so finite verbs are
    /// reliable question openers. No spoken punctuation: "Punkt" and "Komma"
    /// are everyday nouns, far too ambiguous for unconditional replacement.
    static let german = LanguagePack(
        code: "de",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["äh", "ähm", "öhm", "hm", "mhm"],
        spokenPunctuation: [:],
        questionPrefixWords: [
            "was", "wer", "wen", "wem", "wessen", "wann", "wo", "wohin",
            "woher", "warum", "wieso", "weshalb", "wie", "welche", "welcher",
            "welches", "ist", "sind", "war", "waren", "hat", "haben", "hast",
            "habt", "kann", "kannst", "können", "könnt", "soll", "sollen",
            "wird", "werden", "darf", "muss", "müssen", "bist", "seid",
        ],
        questionSuffixParticles: [],
        promptAddendum: nil)
}
