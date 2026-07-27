import Foundation

extension LanguagePack {
    /// Arabic — scaffolding only. Every field below is the neutral default, so
    /// this pack currently behaves exactly as Arabic did with no pack at all.
    /// It exists so the language is registered and reachable; the contributor
    /// who fills it in touches only this directory, its test file, and its eval
    /// battery. See docs/LOCALIZATION.md.
    ///
    /// Arabic is the only right-to-left language the app offers, and the first
    /// to need `؟` `،` `؛` rather than ASCII marks.
    static let arabic = LanguagePack(
        code: "ar",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: [],
        spokenPunctuation: [:],
        questionPrefixWords: [],
        questionSuffixParticles: [])
}
