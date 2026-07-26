import Testing
import Foundation
@testable import VoiceTypeKit

/// The contract a language pack relies on when it ships its own rules. These
/// tests are the promise made to every pack author: your rule runs, at the
/// stage you asked for, in both cleanup paths, and it stays out of a terminal
/// unless you said otherwise.
@Suite("Language packs — pack-owned cleanup rules")
struct CleanupRuleTests {

    /// A pack with nothing but the rules under test, so nothing else can
    /// explain the result.
    private func pack(rules: [CleanupRule],
                      terminalMarks: Set<Character> = LanguagePack.defaultTerminalMarks,
                      casing: String? = nil,
                      preservesFullWidthMarks: Bool? = nil) -> LanguagePack {
        LanguagePack(
            code: "xx",
            separatesWordsWithSpaces: true,
            usesFullWidthPunctuation: false,
            terminalPeriod: ".",
            fillers: [],
            spokenPunctuation: [:],
            questionPrefixWords: [],
            questionSuffixParticles: [],
            rules: rules,
            casingLocaleIdentifier: casing,
            preservesFullWidthMarks: preservesFullWidthMarks,
            terminalMarks: terminalMarks)
    }

    private func marker(_ name: String, _ stage: CleanupRule.Stage) -> CleanupRule {
        CleanupRule(name: name, stage: stage) { text, _ in text + " [\(name)]" }
    }

    @Test("every stage runs in the deterministic path, in declared order")
    func stagesRunInOrder() {
        let out = RuleBasedCleanup.process(
            "hello", options: .default,
            pack: pack(rules: [marker("c", .final),
                               marker("a", .early),
                               marker("b", .afterPunctuation)]))
        // Stage order wins over declaration order.
        #expect(out.range(of: "[a]")!.lowerBound < out.range(of: "[b]")!.lowerBound)
        #expect(out.range(of: "[b]")!.lowerBound < out.range(of: "[c]")!.lowerBound)
    }

    @Test("the same rule runs in the model-output path too")
    func rulesRunOnModelOutput() {
        let rules = [marker("a", .early), marker("b", .afterPunctuation), marker("c", .final)]
        let polished = CleanupPolish.apply("hello", options: .default, pack: pack(rules: rules))
        #expect(polished.contains("[a]"))
        #expect(polished.contains("[b]"))
        #expect(polished.contains("[c]"))
    }

    @Test("rules within one stage apply in declaration order")
    func declarationOrderWithinAStage() {
        let out = RuleBasedCleanup.process(
            "x", options: .default,
            pack: pack(rules: [marker("first", .early), marker("second", .early)]))
        #expect(out.range(of: "[first]")!.lowerBound < out.range(of: "[second]")!.lowerBound)
    }

    @Test("a rule sits out terminal dictation unless it opts in")
    func terminalOptOut() {
        let optedOut = marker("prose", .final)
        let optedIn = CleanupRule(name: "cmd", stage: .final, runsInTerminal: true) { text, _ in
            text + " [cmd]"
        }
        let out = RuleBasedCleanup.process(
            "git status", options: .default,
            context: CleanupContext(category: .terminal),
            pack: pack(rules: [optedOut, optedIn]))
        #expect(!out.contains("[prose]"))
        #expect(out.contains("[cmd]"))
    }

    @Test("the rule sees the dictation context")
    func rulesSeeContext() {
        let rule = CleanupRule(name: "ctx", stage: .final, runsInTerminal: true) { text, context in
            text + " [\(context.category.rawValue)]"
        }
        let out = RuleBasedCleanup.process(
            "x", options: .default,
            context: CleanupContext(category: .codeEditor),
            pack: pack(rules: [rule]))
        #expect(out.contains("[codeEditor]"))
    }

    // MARK: - The motivating case

    @Test("an afterPunctuation rule restores what the shared spacing pass removed")
    func frenchStyleSpacingSurvives() {
        // `fixPunctuationSpacing` strips whitespace before ; : ! ? — correct for
        // English, wrong for French. A pack rule at this stage is the supported
        // way to put it back, and it must survive to the output.
        let spacing = CleanupRule.regex(
            name: "narrow space before high punctuation",
            stage: .afterPunctuation,
            pattern: "(?<=\\S)([;:!?])",
            template: "\u{202F}$1")
        let out = RuleBasedCleanup.process("bonjour !", options: .default,
                                           pack: pack(rules: [spacing]))
        #expect(out.contains("\u{202F}!"))
    }

    @Test("a malformed regex degrades to no rule rather than crashing")
    func badRegexIsInert() {
        let broken = CleanupRule.regex(name: "broken", stage: .early,
                                       pattern: "([unclosed", template: "x")
        #expect(RuleBasedCleanup.process("hello there", options: .default,
                                         pack: pack(rules: [broken])) == "Hello there.")
    }

    // MARK: - Other pack-owned policy

    @Test("the pack's casing locale decides how a sentence is capitalized")
    func casingFollowsThePack() {
        let turkish = pack(rules: [], casing: "tr_TR")
        #expect(turkish.uppercased("i") == "İ")
        #expect(RuleBasedCleanup.process("izmir güzel", options: .default, pack: turkish)
            .hasPrefix("İ"))
        // Unset means Swift's locale-independent casing, which is what every
        // other language wants.
        #expect(pack(rules: []).uppercased("i") == "I")
    }

    @Test("a pack's own terminal marks stop the period being appended")
    func terminalMarksAreThePack() {
        var marks = LanguagePack.defaultTerminalMarks
        marks.insert("।")
        let devanagariStyle = pack(rules: [], terminalMarks: marks)
        #expect(RuleBasedCleanup.process("यह ठीक है।", options: .default, pack: devanagariStyle)
            == "यह ठीक है।")
    }

    @Test("preservesFullWidthMarks keeps full-width punctuation out of the ASCII repair")
    func fullWidthMarksArePreserved() {
        let preserving = pack(rules: [], preservesFullWidthMarks: true)
        #expect(CleanupPolish.apply("좋아요！", options: .default, pack: preserving)
            .contains("！"))
        // The default for a spaced, non-full-width language is still to repair
        // the model's drift into CJK marks.
        #expect(CleanupPolish.apply("okay！", options: .default, pack: pack(rules: []))
            .contains("!"))
    }

    @Test("Korean states its full-width policy in its pack, not in shared code")
    func koreanKeepsItsMarks() {
        // Regression: this used to be a hardcoded ["zh","ja","ko","yue"] list
        // inside CleanupPolish.
        #expect(LanguagePack.pack(for: "ko-KR").preservesFullWidthMarks)
        #expect(!LanguagePack.pack(for: "de-DE").preservesFullWidthMarks)
        #expect(LanguagePack.pack(for: "zh-CN").preservesFullWidthMarks)
        #expect(LanguagePack.pack(for: "ja-JP").preservesFullWidthMarks)
    }

    @Test("a pack's lead-in patterns strip a wrapper written in its language")
    func packLeadInPatterns() {
        let german = LanguagePack(
            code: "xx", separatesWordsWithSpaces: true,
            usesFullWidthPunctuation: false, terminalPeriod: ".",
            fillers: [], spokenPunctuation: [:],
            questionPrefixWords: [], questionSuffixParticles: [],
            modelLeadInPatterns: [#"(?i)^\s*klar[,!.]+\s*hier ist[^\n:]{0,60}:\s+"#])
        #expect(CleanupSanitizer.strip("Klar, hier ist der bereinigte Text: guten Morgen.",
                                       pack: german) == "guten Morgen.")
        // The shared English patterns keep working alongside it.
        #expect(CleanupSanitizer.strip("Sure, here's the cleaned transcript: hello.",
                                       pack: german) == "hello.")
    }

    @Test("guard thresholds come from the pack")
    func guardPolicyIsPerPack() {
        let raw = "one two three four five six seven eight nine ten"
        let halved = "one two three four five"
        // Default policy: retaining half is exactly at the limit, not below it.
        #expect(!CleanupGuard.looksLikeSummary(raw: raw, cleaned: halved, pack: pack(rules: [])))
        let strict = LanguagePack(
            code: "xx", separatesWordsWithSpaces: true,
            usesFullWidthPunctuation: false, terminalPeriod: ".",
            fillers: [], spokenPunctuation: [:],
            questionPrefixWords: [], questionSuffixParticles: [],
            guardPolicy: CleanupGuardPolicy(minimumRetainedRatio: 0.9))
        #expect(CleanupGuard.looksLikeSummary(raw: raw, cleaned: halved, pack: strict))
    }
}
