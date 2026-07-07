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

    @Test("pronoun rule never touches i inside identifiers or handles")
    func identifierISafe() {
        let out = CleanupPolish.apply("Push it to michael-L-i and check i.test today.", options: opts)
        #expect(out.contains("michael-L-i"))
        #expect(out.contains("i.test"))
    }

    @Test("pronoun rule still handles contractions")
    func contractionI() {
        let out = CleanupPolish.apply("i'll take it.", options: opts)
        #expect(out == "I'll take it.")
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

    @Test("unpunctuated question gains a question mark")
    func questionMark() {
        let out = CleanupPolish.apply("what time does the demo start tomorrow", options: opts)
        #expect(out == "What time does the demo start tomorrow?")
    }

    @Test("question mark respects the model's own punctuation and statements")
    func questionMarkRestraint() {
        #expect(CleanupPolish.apply("What is the plan.", options: opts) == "What is the plan.")
        #expect(CleanupPolish.apply("the demo starts at noon", options: opts) == "The demo starts at noon")
        let terminal = CleanupContext(category: .terminal)
        #expect(CleanupPolish.apply("which app", options: opts, context: terminal) == "which app")
    }

    @Test("already-capitalized output passes through unchanged")
    func alreadyClean() {
        let text = "The build is green. I pushed it."
        #expect(CleanupPolish.apply(text, options: opts) == text)
    }
}

@Suite("Cleanup polish — foreign punctuation")
struct CleanupPolishPunctuationTests {
    let opts = CleanupOptions.default

    @Test("CJK punctuation normalizes to ASCII for English dictation")
    func normalizesForEnglish() {
        let out = CleanupPolish.apply("ship it on friday。", options: opts, locale: "en-US")
        #expect(out.hasSuffix("friday."))
        #expect(!out.contains("。"))
    }

    @Test("full set of drift marks maps to ASCII equivalents")
    func fullMap() {
        #expect(CleanupPolish.normalizeForeignPunctuation("a，b、c？d！e：f；（g）")
            == "a,b,c?d!e:f;(g)")
    }

    @Test("CJK languages keep their own punctuation")
    func cjkLocaleUntouched() {
        let text = "今天天气很好。"
        #expect(CleanupPolish.apply(text, options: opts, locale: "zh-CN") == text)
    }

    @Test("text without drift marks is untouched")
    func asciiUntouched() {
        let text = "Plain English, with (normal) punctuation!"
        #expect(CleanupPolish.normalizeForeignPunctuation(text) == text)
    }
}
