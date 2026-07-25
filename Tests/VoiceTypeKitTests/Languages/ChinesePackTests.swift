import Testing
import Foundation
@testable import VoiceTypeKit

/// Everything specific to the Chinese pack. Lives beside the other per-language
/// suites so a contributor working on zh touches exactly one source file and
/// one test file — see docs/LOCALIZATION.md.
@Suite("Language pack — Chinese policy")
struct ChinesePackPolicyTests {
    @Test("unambiguous fillers only, 点 and 那个 excluded")
    func policy() {
        let zh = LanguagePack.chinese
        #expect(zh.fillers == ["嗯", "呃"])
        #expect(zh.spokenPunctuation["点"] == nil)
        #expect(!zh.fillers.contains("那个"))
        #expect(zh.usesFullWidthPunctuation)
        #expect(!zh.separatesWordsWithSpaces)
    }
}

@Suite("Rule-based cleanup — Chinese")
struct ChineseRuleCleanupTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(text, options: .default,
                                 context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                                 locale: "zh-CN")
    }

    @Test("unambiguous fillers are removed at boundaries")
    func fillers() {
        #expect(clean("嗯，今天天气很好") == "今天天气很好。")
        #expect(clean("我觉得，呃，这个方案更好") == "我觉得，这个方案更好。")
    }

    @Test("ambiguous fillers 那个/就是 are never touched deterministically")
    func ambiguousFillersKept() {
        #expect(clean("那个方案就是最好的") == "那个方案就是最好的。")
    }

    @Test("spoken punctuation renders full-width marks")
    func spokenPunctuation() {
        #expect(clean("今天天气很好句号") == "今天天气很好。")
        #expect(clean("第一逗号第二逗号第三") == "第一，第二，第三。")
        #expect(clean("你明天来吗问号") == "你明天来吗？")
    }

    @Test("spoken punctuation is idempotent when the engine already rendered it")
    func spokenPunctuationIdempotent() {
        #expect(clean("今天天气很好。句号") == "今天天气很好。")
    }

    @Test("换行 renders a newline and the following text keeps flowing")
    func newline() {
        #expect(clean("第一点换行第二点") == "第一点\n第二点。")
    }

    @Test("a 吗-question with no terminal mark gains a full-width question mark")
    func questionParticle() {
        #expect(clean("你明天有空吗") == "你明天有空吗？")
    }

    @Test("terminal 。 lands only on a Han ending; an English tail stays bare")
    func terminalPeriod() {
        #expect(clean("今天天气很好") == "今天天气很好。")
        #expect(clean("我在用 VoiceType") == "我在用 VoiceType")
    }

    @Test("Whisper-style inter-character spaces are joined")
    func interCharacterSpaces() {
        #expect(clean("今天 天气 很好") == "今天天气很好。")
    }

    @Test("embedded English keeps ASCII and its boundary spacing")
    func embeddedEnglish() {
        #expect(clean("请把 main.py 发给我") == "请把 main.py 发给我。")
    }

    @Test("no capitalization pass runs on a leading English fragment")
    func noCapitalization() {
        #expect(clean("git 命令很有用") == "git 命令很有用。")
    }

    @Test("terminal category stays command-safe: no terminal mark, no filler surprises")
    func terminalCategory() {
        #expect(clean("git status", category: .terminal) == "git status")
    }
}

@Suite("Cleanup polish — Chinese model output")
struct ChinesePolishTests {
    @Test("ASCII commas the model drifts into become full-width, and the terminal 。 is guaranteed")
    func asciiDrift() {
        let out = CleanupPolish.apply("今天很好,明天见", options: .default, locale: "zh-CN")
        #expect(out == "今天很好，明天见。")
    }

    @Test("spoken punctuation the model left as words renders in polish, absorbing wrapped marks")
    func spokenNamesRendered() {
        let out = CleanupPolish.apply("我们需要苹果，顿号，香蕉", options: .default, locale: "zh-CN")
        #expect(out == "我们需要苹果、香蕉。")
    }

    @Test("English capitalization repairs are skipped for Chinese")
    func capitalizationSkipped() {
        let out = CleanupPolish.apply("ok 我们开始吧。", options: .default, locale: "zh-CN")
        #expect(out == "ok 我们开始吧。")
    }
}

@Suite("Word replacements — CJK")
struct ChineseWordReplacementTests {
    @Test("a CJK phrase matches inside continuous Chinese text")
    func cjkPhrase() {
        let rules = [WordReplacement(from: "微信", to: "WeChat")]
        #expect(WordReplacements.apply(rules, to: "帮我打开微信发个消息") == "帮我打开WeChat发个消息")
    }

    @Test("a CJK phrase adjacent to Latin still matches")
    func cjkNextToLatin() {
        let rules = [WordReplacement(from: "语音输入", to: "VoiceType")]
        #expect(WordReplacements.apply(rules, to: "我用语音输入app写代码") == "我用VoiceTypeapp写代码")
    }

    @Test("English whole-word boundaries are unchanged")
    func englishBoundaries() {
        let rules = [WordReplacement(from: "cat", to: "dog")]
        #expect(WordReplacements.apply(rules, to: "the cat concatenates") == "the dog concatenates")
    }
}
