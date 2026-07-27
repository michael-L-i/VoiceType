import Foundation

extension LanguagePack {
    /// Finnish — scaffolding only. Every field below is the neutral default, so
    /// this pack currently behaves exactly as Finnish did with no pack at all.
    /// It exists so the language is registered and reachable; the contributor
    /// who fills it in touches only this directory, its test file, and its eval
    /// battery. See docs/LOCALIZATION.md.
    static let finnish = LanguagePack(
        code: "fi",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: [],
        spokenPunctuation: [:],
        questionPrefixWords: [],
        questionSuffixParticles: [])
}
