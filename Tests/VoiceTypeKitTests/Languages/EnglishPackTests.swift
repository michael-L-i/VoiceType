import Testing
import Foundation
@testable import VoiceTypeKit

/// Everything specific to the English pack. English is the reference
/// implementation: it is the only pack that currently ships a spoken-symbol
/// vocabulary and prompt guidance, so these tests double as the worked example
/// for the fields a new language can fill in.
@Suite("Language pack — English policy")
struct EnglishPackPolicyTests {
    @Test("carries the historical filler lexicon verbatim, ambiguous words excluded")
    func fillers() {
        #expect(LanguagePack.english.fillers.contains("um"))
        #expect(LanguagePack.english.fillers.contains("mhm"))
        #expect(!LanguagePack.english.fillers.contains("like"))
        #expect(!LanguagePack.english.fillers.contains("so"))
    }

    @Test("owns the stopword list the guard and the symbol renderer both probe")
    func stopwords() {
        #expect(LanguagePack.english.stopwords.contains("the"))
        #expect(LanguagePack.english.stopwords.contains("actually"))
        #expect(!LanguagePack.english.stopwords.contains("deploy"))
    }

    @Test("owns the standalone pronoun and the spoken-symbol vocabulary")
    func ownedRules() {
        #expect(LanguagePack.english.capitalizedStandalonePronoun == "i")
        #expect(LanguagePack.english.symbols?.dot == ["dot"])
        #expect(LanguagePack.english.symbols?.fileExtensions.contains("swift") == true)
    }

    @Test("no other pack claims symbol rendering or a standalone pronoun yet")
    func englishIsTheOnlyOptIn() {
        for pack in LanguagePack.all where pack.code != "en" {
            #expect(pack.symbols == nil, "\(pack.code)")
            #expect(pack.capitalizedStandalonePronoun == nil, "\(pack.code)")
        }
    }
}

@Suite("Cleanup polish — English model output")
struct EnglishPolishTests {
    @Test("an unpunctuated interrogative opener gains a question mark and a capital")
    func questionAndCapital() {
        let out = CleanupPolish.apply("did you ship it", options: .default, locale: "en-US")
        #expect(out == "Did you ship it?")
    }
}
