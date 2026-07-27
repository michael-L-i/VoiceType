import Foundation

extension LanguagePack {
    /// Romanian — scaffolding only. Every field below is the neutral default, so
    /// this pack currently behaves exactly as Romanian did with no pack at all.
    /// It exists so the language is registered and reachable; the contributor
    /// who fills it in touches only this directory, its test file, and its eval
    /// battery. See docs/LOCALIZATION.md.
    static let romanian = LanguagePack(
        code: "ro",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: [],
        spokenPunctuation: [:],
        questionPrefixWords: [],
        questionSuffixParticles: [])
}
