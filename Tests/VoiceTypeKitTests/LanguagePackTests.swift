import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Language packs — registry")
struct LanguagePackRegistryTests {
    @Test("locale variants resolve to the same pack by primary subtag")
    func lookup() {
        #expect(LanguagePack.pack(for: "zh-CN").code == "zh")
        #expect(LanguagePack.pack(for: "zh-Hans-CN").code == "zh")
        #expect(LanguagePack.pack(for: "zh_CN").code == "zh")
        #expect(LanguagePack.pack(for: "en-GB").code == "en")
    }

    @Test("languages without a pack fall back to neutral (no fillers, no spoken punctuation)")
    func neutralFallback() {
        let pack = LanguagePack.pack(for: "fr-FR")
        #expect(pack.code.isEmpty)
        #expect(pack.fillers.isEmpty)
        #expect(pack.spokenPunctuation.isEmpty)
        #expect(pack.separatesWordsWithSpaces)
        #expect(pack.terminalPeriod == ".")
    }

    @Test("English pack carries the historical filler lexicon verbatim")
    func englishFillers() {
        #expect(LanguagePack.english.fillers.contains("um"))
        #expect(LanguagePack.english.fillers.contains("mhm"))
        #expect(!LanguagePack.english.fillers.contains("like"))
    }

    @Test("Chinese pack policy: unambiguous fillers only, 点 and 那个 excluded")
    func chinesePolicy() {
        let zh = LanguagePack.chinese
        #expect(zh.fillers == ["嗯", "呃"])
        #expect(zh.spokenPunctuation["点"] == nil)
        #expect(!zh.fillers.contains("那个"))
        #expect(zh.usesFullWidthPunctuation)
        #expect(!zh.separatesWordsWithSpaces)
    }
}

@Suite("CJK punctuation normalization")
struct CJKPunctuationTests {
    @Test("ASCII marks after Han become full-width and swallow the padding space")
    func asciiToFullWidth() {
        #expect(CJKPunctuation.normalize("今天很好, 明天见") == "今天很好，明天见")
        #expect(CJKPunctuation.normalize("你来吗?") == "你来吗？")
        #expect(CJKPunctuation.normalize("太棒了!") == "太棒了！")
    }

    @Test("sentence periods become 。 but identifier and decimal tails stay ASCII")
    func periods() {
        #expect(CJKPunctuation.normalize("今天很好. 明天见") == "今天很好。明天见")
        #expect(CJKPunctuation.normalize("文件是主程序.py") == "文件是主程序.py")
        #expect(CJKPunctuation.normalize("pi is 3.14") == "pi is 3.14")
    }

    @Test("spaces between Han characters vanish; Latin–Han boundaries keep theirs")
    func spacing() {
        #expect(CJKPunctuation.normalize("你 好 世 界") == "你好世界")
        #expect(CJKPunctuation.normalize("VoiceType 很棒") == "VoiceType 很棒")
        #expect(CJKPunctuation.normalize("你好 ，世界") == "你好，世界")
    }

    @Test("doubled marks collapse so spoken punctuation stays idempotent")
    func dedupe() {
        #expect(CJKPunctuation.normalize("今天很好。。") == "今天很好。")
        #expect(CJKPunctuation.normalize("你来吗？。") == "你来吗？")
    }

    @Test("pure English text passes through untouched")
    func englishUntouched() {
        let text = "Hello, world! Ship main.py now."
        #expect(CJKPunctuation.normalize(text) == text)
    }

    @Test("newlines survive — they only exist because the speaker dictated them")
    func newlines() {
        #expect(CJKPunctuation.normalize("第一行\n第二行") == "第一行\n第二行")
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

    @Test("echoed transcript markers are stripped by the sanitizer")
    func markerEcho() {
        let out = CleanupSanitizer.strip("我在用 VoiceType\n\n<<<TRANSCRIPT\nTRANSCRIPT>>>")
        #expect(out == "我在用 VoiceType")
    }

    @Test("a model-added code fence is unwrapped; inline backticks survive")
    func codeFence() {
        #expect(CleanupSanitizer.strip("git status\n```") == "git status")
        #expect(CleanupSanitizer.strip("```\ngit status\n```") == "git status")
        #expect(CleanupSanitizer.strip("run `git status` now") == "run `git status` now")
    }

    @Test("English capitalization repairs are skipped for Chinese")
    func capitalizationSkipped() {
        let out = CleanupPolish.apply("ok 我们开始吧。", options: .default, locale: "zh-CN")
        #expect(out == "ok 我们开始吧。")
    }

    @Test("English polish behavior is unchanged")
    func englishUnchanged() {
        let out = CleanupPolish.apply("did you ship it", options: .default, locale: "en-US")
        #expect(out == "Did you ship it?")
    }
}

@Suite("Cleanup guard — lost dominant script")
struct LostScriptGuardTests {
    @Test("majority-Han dictation translated to English trips the guard")
    func translationTrips() {
        #expect(CleanupGuard.lostDominantScript(
            raw: "今天天气很好我们去公园散步吧",
            cleaned: "The weather is great today, let's take a walk in the park."))
    }

    @Test("faithful Chinese cleanup does not trip")
    func faithfulPasses() {
        #expect(!CleanupGuard.lostDominantScript(
            raw: "嗯今天天气很好",
            cleaned: "今天天气很好。"))
    }

    @Test("English dictation never trips")
    func englishNeverTrips() {
        #expect(!CleanupGuard.lostDominantScript(
            raw: "the weather is great today",
            cleaned: "The weather is great today."))
    }

    @Test("mixed dictation that keeps its Han passes")
    func mixedPasses() {
        #expect(!CleanupGuard.lostDominantScript(
            raw: "请把 main.py 发给我",
            cleaned: "请把 main.py 发给我。"))
    }

    @Test("wired into looksUnfaithful")
    func wiredIn() {
        #expect(CleanupGuard.looksUnfaithful(
            raw: "今天天气很好我们去公园散步吧",
            cleaned: "The weather is great today, let's take a walk in the park."))
    }

    @Test("a dropped Han opener trips the guard; faithful and filler-skipped outputs pass")
    func hanOpening() {
        #expect(CleanupGuard.droppedHanOpening(
            raw: "请把 main.py 发给我", cleaned: "main.py 发给我。"))
        #expect(!CleanupGuard.droppedHanOpening(
            raw: "请把 main.py 发给我", cleaned: "请把 main.py 发给我。"))
        #expect(!CleanupGuard.droppedHanOpening(
            raw: "嗯嗯今天天气很好", cleaned: "今天天气很好。"))
        #expect(!CleanupGuard.droppedHanOpening(
            raw: "ok cool", cleaned: "Ok cool."))
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
