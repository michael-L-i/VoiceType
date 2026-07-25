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
}

@Suite("Cleanup polish — English model output")
struct EnglishPolishTests {
    @Test("an unpunctuated interrogative opener gains a question mark and a capital")
    func questionAndCapital() {
        let out = CleanupPolish.apply("did you ship it", options: .default, locale: "en-US")
        #expect(out == "Did you ship it?")
    }
}
