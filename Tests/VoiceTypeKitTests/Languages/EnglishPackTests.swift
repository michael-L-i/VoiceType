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

    @Test("English's vocabulary is English's, never handed to another language")
    func vocabularyIsNotShared() {
        // The failure this guards against is a pack reaching for
        // `SpokenSymbolVocabulary.english` because it is the only one that
        // exists — which would teach a German transcript to render the English
        // word "dot". A language opting in must bring its own trigger words.
        for pack in LanguagePack.all where pack.code != "en" {
            guard let symbols = pack.symbols else { continue }
            #expect(symbols.dot != LanguagePack.english.symbols?.dot,
                    "\(pack.code) reuses English's spoken-symbol triggers")
        }
    }
}

@Suite("Cleanup rules — English deterministic commands")
struct EnglishRuleTests {
    @Test("spoken camel case joins only the marked identifier")
    func camelCaseIdentifier() {
        let out = RuleBasedCleanup.process(
            "call camel case get user name with the session token",
            options: .default,
            locale: "en-US")
        #expect(out == "Call getUserName with the session token.")
    }

    @Test("camel case stops at an English function-word boundary")
    func camelCaseBoundary() {
        let out = RuleBasedCleanup.process(
            "use camel case parse request in the handler",
            options: .default,
            locale: "en-US")
        #expect(out == "Use parseRequest in the handler.")
    }

    @Test("a leading camel identifier remains lower camel case")
    func leadingCamelCaseIdentifier() {
        let out = RuleBasedCleanup.process(
            "camel case parse request",
            options: .default,
            locale: "en-US")
        #expect(out == "parseRequest.")
    }

    @Test("multiple camel-case commands render independently")
    func multipleCamelCaseIdentifiers() {
        let out = RuleBasedCleanup.process(
            "call camel case parse request and then call camel case load user with it",
            options: .default,
            locale: "en-US")
        #expect(out == "Call parseRequest and then call loadUser with it.")
    }

    @Test("camel case without a multiword target remains prose")
    func camelCaseProseGuard() {
        let out = RuleBasedCleanup.process(
            "camel case is common in javascript",
            options: .default,
            locale: "en-US")
        #expect(out == "Camel case is common in javascript.")
    }

    @Test("the same camel-case rule repairs model output")
    func camelCaseModelPolish() {
        let out = CleanupPolish.apply(
            "call camel case get user name with the token",
            options: .default,
            locale: "en-US")
        #expect(out == "Call getUserName with the token")
    }

    @Test("camel-case commands sit out terminal dictation")
    func camelCaseTerminalGuard() {
        let out = RuleBasedCleanup.process(
            "git branch camel case feature name",
            options: .default,
            context: CleanupContext(category: .terminal),
            locale: "en-US")
        #expect(out == "git branch camel case feature name")
    }

    @Test("no wait retracts an argument only when its preposition repeats")
    func repeatedPrepositionCorrection() {
        let out = RuleBasedCleanup.process(
            "send the report to bob, no wait, to alice before lunch",
            options: .default,
            locale: "en-US")
        #expect(out == "Send the report to alice before lunch.")
    }

    @Test("ordinary no wait prose is never treated as a correction")
    func noWaitProseGuard() {
        let out = RuleBasedCleanup.process(
            "there is no wait, to enter the museum",
            options: .default,
            locale: "en-US")
        #expect(out == "There is no wait, to enter the museum.")
    }

    @Test("a changed preposition leaves an ambiguous correction untouched")
    func noWaitAnchorGuard() {
        let out = RuleBasedCleanup.process(
            "send the report to bob, no wait, for alice before lunch",
            options: .default,
            locale: "en-US")
        #expect(out == "Send the report to bob, no wait, for alice before lunch.")
    }

    @Test("no-wait correction sits out terminal dictation")
    func noWaitTerminalGuard() {
        let out = RuleBasedCleanup.process(
            "send the report to bob, no wait, to alice",
            options: .default,
            context: CleanupContext(category: .terminal),
            locale: "en-US")
        #expect(out == "send the report to bob, no wait, to alice")
    }

    @Test("bare numeric self-correction remains model territory")
    func numericCorrectionRefusal() {
        let out = RuleBasedCleanup.process(
            "we need five, no six copies",
            options: .default,
            locale: "en-US")
        #expect(out == "We need five, no six copies.")
    }

    @Test("ordinary numeric no prose preserves both numbers")
    func numericNoProseGuard() {
        let out = RuleBasedCleanup.process(
            "the answer is five, no six is allowed by the rubric",
            options: .default,
            locale: "en-US")
        #expect(out == "The answer is five, no six is allowed by the rubric.")
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

/// The question heuristic is shared machinery; these cover the pack-supplied
/// pieces a new language will rely on.
@Suite("Question heuristic — pack-supplied particles and marks")
struct QuestionHeuristicTests {
    @Test("a multi-character sentence-final particle is matched, longest first")
    func multiCharacterParticle() {
        let pack = LanguagePack(
            code: "xx",
            separatesWordsWithSpaces: true,
            usesFullWidthPunctuation: false,
            terminalPeriod: ".",
            fillers: [],
            spokenPunctuation: [:],
            questionPrefixWords: [],
            questionSuffixParticles: ["ka", "desuka"])
        // Single-character probing could never have seen either of these.
        #expect(CleanupPolish.ensureQuestionMark("kore wa nan desuka", pack: pack)
            == "kore wa nan desuka?")
        #expect(CleanupPolish.ensureQuestionMark("iku ka", pack: pack) == "iku ka?")
        #expect(CleanupPolish.ensureQuestionMark("kore wa hon", pack: pack) == "kore wa hon")
    }

    @Test("the pack's own question mark is used, not a hardcoded one")
    func packQuestionMark() {
        #expect(CleanupPolish.ensureQuestionMark("你明天有空吗", pack: .chinese) == "你明天有空吗？")
        #expect(CleanupPolish.ensureQuestionMark("did you ship it", pack: .english) == "did you ship it?")
    }

    @Test("output that already ends in punctuation is left alone")
    func respectsExistingPunctuation() {
        #expect(CleanupPolish.ensureQuestionMark("did you ship it.", pack: .english)
            == "did you ship it.")
    }
}
