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
        // Deliberately an unassigned code rather than a real language: this
        // test used "fi-FI" until Finnish got a pack, and every language we
        // ship is on its way to having one.
        let pack = LanguagePack.pack(for: "qq-QQ")
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
        #expect(CleanupGuard.droppedScriptOpening(
            raw: "请把 main.py 发给我", cleaned: "main.py 发给我。"))
        #expect(!CleanupGuard.droppedScriptOpening(
            raw: "请把 main.py 发给我", cleaned: "请把 main.py 发给我。"))
        #expect(!CleanupGuard.droppedScriptOpening(
            raw: "嗯嗯今天天气很好", cleaned: "今天天气很好。"))
        #expect(!CleanupGuard.droppedScriptOpening(
            raw: "ok cool", cleaned: "Ok cool."))
    }
}


/// The translation guard used to police Han only, so a Russian or Greek
/// dictation silently rewritten into English sailed through.
@Suite("Cleanup guard — translation out of any tracked script")
struct DominantScriptGuardTests {
    @Test("a majority-script dictation replaced by English trips, whatever the script")
    func translationTrips() {
        let cases: [(String, String)] = [
            ("сегодня очень хорошая погода пойдём гулять в парк", "The weather is great today, let's walk in the park."),
            ("σήμερα ο καιρός είναι πολύ ωραίος", "The weather is really nice today."),
            ("오늘 날씨가 정말 좋으니까 공원에 산책하러 가자", "The weather is great today, let's go for a walk."),
            ("今日はとてもいい天気ですね", "It's really nice weather today."),
        ]
        for (raw, cleaned) in cases {
            #expect(CleanupGuard.lostDominantScript(raw: raw, cleaned: cleaned), "\(raw)")
            #expect(CleanupGuard.looksUnfaithful(raw: raw, cleaned: cleaned), "\(raw)")
        }
    }

    @Test("faithful cleanup in those same scripts passes")
    func faithfulPasses() {
        let cases: [(String, String)] = [
            ("сегодня очень хорошая погода", "Сегодня очень хорошая погода."),
            ("σήμερα ο καιρός είναι ωραίος", "Σήμερα ο καιρός είναι ωραίος."),
            ("오늘 날씨가 좋다", "오늘 날씨가 좋다."),
            ("今日はいい天気ですね", "今日はいい天気ですね。"),
        ]
        for (raw, cleaned) in cases {
            #expect(!CleanupGuard.lostDominantScript(raw: raw, cleaned: cleaned), "\(raw)")
        }
    }

    @Test("Japanese written in both kana and kanji counts as one script, not two")
    func kanaAndKanjiAreOneScript() {
        // A kanji-heavy sentence answered in kana is a style choice, not a
        // translation, so it must not trip.
        #expect(!CleanupGuard.lostDominantScript(raw: "明日会議があります",
                                                 cleaned: "あした かいぎ が あります"))
    }

    @Test("Latin dictation with a borrowed word is never policed")
    func latinNeverTrips() {
        #expect(!CleanupGuard.lostDominantScript(raw: "the weather is great today",
                                                 cleaned: "The weather is great today."))
        #expect(!CleanupGuard.lostDominantScript(raw: "send it to 田中 tomorrow",
                                                 cleaned: "Send it to 田中 tomorrow."))
    }
}
