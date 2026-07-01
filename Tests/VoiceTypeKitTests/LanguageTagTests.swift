import Testing
@testable import VoiceTypeKit

@Suite("Language tag — BCP-47 to code / name")
struct LanguageTagTests {
    @Test("code strips the region subtag")
    func code() {
        #expect(LanguageTag.code(for: "en-US") == "en")
        #expect(LanguageTag.code(for: "pt-BR") == "pt")
        #expect(LanguageTag.code(for: "zh-CN") == "zh")
        #expect(LanguageTag.code(for: "fr") == "fr")
        #expect(LanguageTag.code(for: "de_DE") == "de")
    }

    @Test("englishName resolves a readable, English language name")
    func englishName() {
        #expect(LanguageTag.englishName(for: "es-ES") == "Spanish")
        #expect(LanguageTag.englishName(for: "ja-JP") == "Japanese")
        #expect(LanguageTag.englishName(for: "en-GB") == "English")
    }
}

@Suite("Rule-based cleanup — language awareness")
struct CleanupLanguageTests {
    let opts = CleanupOptions.default

    @Test("English filler removal and standalone-I only apply to English")
    func englishOnly() {
        // In Italian, "i" is a real word (the plural article) and English fillers
        // don't exist — neither rule should fire. (Sentence capitalization still
        // does, so the leading "um" becomes "Um" but is NOT removed.)
        let out = RuleBasedCleanup.process("io i cani sono qui um", options: opts, locale: "it-IT")
        #expect(out.lowercased().contains("um"))   // English filler left intact
        #expect(out.contains(" i "))               // "i" not capitalized to "I"
        #expect(!out.contains(" I "))
    }

    @Test("sentence capitalization still applies for any language")
    func capitalizesFirstLetterAnyLanguage() {
        let out = RuleBasedCleanup.process("hola mundo", options: opts, locale: "es-ES")
        #expect(out.hasPrefix("Hola"))
    }
}
