import Testing
import Foundation
@testable import VoiceTypeKit

/// Everything specific to the Chinese pack. Lives beside the other per-language
/// suites so a contributor working on zh touches exactly one language source
/// directory and one test file — see docs/LOCALIZATION.md.
@Suite("Language pack — Chinese policy")
struct ChinesePackPolicyTests {
    @Test("unambiguous fillers only, ambiguous 点 and 那个 excluded from blind fields")
    func policy() {
        let zh = LanguagePack.chinese
        #expect(zh.fillers == ["嗯", "呃"])
        #expect(zh.spokenPunctuation["点"] == nil)
        #expect(!zh.fillers.contains("那个"))
        #expect(zh.symbols == nil)
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

    @Test("guarded 点 renders only a known Latin file extension")
    func guardedTechnicalPoint() {
        #expect(clean("请打开 main 点 py 检查配置") == "请打开 main.py 检查配置。")
        #expect(clean("把 config 点 json 发给我") == "把 config.json 发给我。")
    }

    @Test("点 remains lexical in times, spoken decimals, and requests")
    func ambiguousPointKept() {
        #expect(clean("会议安排在三点一刻") == "会议安排在三点一刻。")
        #expect(clean("圆周率约等于三点一四") == "圆周率约等于三点一四。")
        #expect(clean("请快点把文件发来") == "请快点把文件发来。")
    }

    @Test("a structurally anchored spoken Latin email renders")
    func spokenEmail() {
        #expect(clean("请发到 zhang 点 san 艾特 example 点 com 再确认")
                == "请发到 zhang.san@example.com 再确认。")
    }

    @Test("spoken full-width punctuation is set solid beside Latin text")
    func latinAdjacentSpokenPunctuation() {
        #expect(clean("支持 TypeScript 逗号 Python 和 Swift")
                == "支持 TypeScript，Python 和 Swift")
        #expect(clean("环境变量是 NODE_ENV 冒号 production")
                == "环境变量是 NODE_ENV：production")
    }

    @Test("spoken dates, measure words, quantities, and currency stay faithful")
    func numbersAndQuantities() {
        #expect(clean("发布日期是二零二六年七月二十六日")
                == "发布日期是二零二六年七月二十六日。")
        #expect(clean("请买三本书和两支笔") == "请买三本书和两支笔。")
        #expect(clean("总价是一百二十八元五角") == "总价是一百二十八元五角。")
    }

    @Test("儿化, repeated characters, and filler-lookalike idiom content survive")
    func lexicalFormsPreserved() {
        #expect(clean("待会儿去胡同口看看") == "待会儿去胡同口看看。")
        #expect(clean("这个问题要慢慢看看再说") == "这个问题要慢慢看看再说。")
        #expect(clean("这简直是对牛弹琴") == "这简直是对牛弹琴。")
    }

    @Test("no capitalization pass runs on a leading English fragment")
    func noCapitalization() {
        #expect(clean("git 命令很有用") == "git 命令很有用。")
    }

    @Test("terminal category preserves Chinese prose around a command without a terminal mark")
    func terminalCategory() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("请运行 git status 然后把结果发给我", category: .terminal)
                == "请运行 git status 然后把结果发给我")
        #expect(clean("请运行 python main 点 py 然后检查输出", category: .terminal)
                == "请运行 python main.py 然后检查输出")
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

    @Test("Chinese-owned technical and spacing rules also repair model output")
    func packRulesApply() {
        let out = CleanupPolish.apply(
            "请打开 main 点 py， 然后检查 TypeScript 逗号 Python",
            options: .default,
            locale: "zh-CN")
        #expect(out == "请打开 main.py，然后检查 TypeScript，Python")
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
