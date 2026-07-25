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
        let pack = LanguagePack.pack(for: "fi-FI")
        #expect(pack.code.isEmpty)
        #expect(pack.fillers.isEmpty)
        #expect(pack.spokenPunctuation.isEmpty)
        #expect(pack.separatesWordsWithSpaces)
        #expect(pack.terminalPeriod == ".")
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

