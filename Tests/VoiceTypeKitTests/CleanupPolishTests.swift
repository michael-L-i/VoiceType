import Testing
@testable import VoiceTypeKit

@Suite("Cleanup polish")
struct CleanupPolishTests {
    let opts = CleanupOptions.default

    @Test("capitalizes a lowercase leading word")
    func leadingCapital() {
        let out = CleanupPolish.apply("the deploy finished this morning.", options: opts)
        #expect(out == "The deploy finished this morning.")
    }

    @Test("leaves a leading identifier or path untouched")
    func leadingIdentifier() {
        #expect(CleanupPolish.apply("app.py is missing.", options: opts) == "app.py is missing.")
        #expect(CleanupPolish.apply("~/projects has moved.", options: opts) == "~/projects has moved.")
        #expect(CleanupPolish.apply("get_user needs a fix.", options: opts) == "get_user needs a fix.")
    }

    @Test("leading word with trailing punctuation still capitalizes")
    func leadingWordWithComma() {
        let out = CleanupPolish.apply("yeah, that works for me.", options: opts)
        #expect(out == "Yeah, that works for me.")
    }

    @Test("capitalizes the standalone pronoun i")
    func standaloneI() {
        let out = CleanupPolish.apply("honestly i think i agree.", options: opts)
        #expect(out == "Honestly I think I agree.")
    }

    @Test("repairs a literal underscore joiner left in an identifier")
    func underscoreJoiner() {
        let out = CleanupPolish.apply("set max_underscore_retries to five.", options: opts)
        #expect(out == "Set max_retries to five.")
    }

    @Test("terminal context gets the identifier repair but no capitalization")
    func terminalContext() {
        let terminal = CleanupContext(category: .terminal)
        let out = CleanupPolish.apply("git status", options: opts, context: terminal)
        #expect(out == "git status")
        #expect(CleanupPolish.apply("export a_underscore_b=1", options: opts, context: terminal)
                == "export a_b=1")
    }

    @Test("disabled capitalization option skips the prose rules")
    func disabledOption() {
        let none = CleanupOptions(removeFillers: false, addPunctuation: false, fixCapitalization: false)
        #expect(CleanupPolish.apply("the deploy finished", options: none) == "the deploy finished")
    }

    @Test("non-English locale skips the standalone-i rule but keeps the leading capital")
    func nonEnglish() {
        let out = CleanupPolish.apply("i cani sono qui.", options: opts, locale: "it-IT")
        #expect(out == "I cani sono qui.")
        #expect(!out.contains(" I "))
    }

    @Test("already-capitalized output passes through unchanged")
    func alreadyClean() {
        let text = "The build is green. I pushed it."
        #expect(CleanupPolish.apply(text, options: opts) == text)
    }
}
