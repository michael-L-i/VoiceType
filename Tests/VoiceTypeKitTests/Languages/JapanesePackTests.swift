import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Language pack — Japanese policy")
struct JapanesePackPolicyTests {
    @Test("only unmistakable hesitations are deterministic fillers")
    func fillerPolicy() {
        let ja = LanguagePack.japanese
        #expect(ja.fillers.contains("えっと"))
        #expect(ja.fillers.contains("あのー"))
        #expect(!ja.fillers.contains("あの"))
        #expect(!ja.fillers.contains("その"))
        #expect(!ja.fillers.contains("まあ"))
        #expect(!ja.fillers.contains("うーん"))
    }

    @Test("ambiguous punctuation words stay out of blind replacement")
    func punctuationPolicy() {
        let ja = LanguagePack.japanese
        #expect(ja.spokenPunctuation["句点"] == "。")
        #expect(ja.spokenPunctuation["読点"] == "、")
        #expect(ja.spokenPunctuation["点"] == nil)
        #expect(ja.spokenPunctuation["まる"] == nil)
        #expect(ja.spokenPunctuation["ドット"] == nil)
        #expect(ja.symbols == nil)
    }

    @Test("prompt guidance is complete without risky few-shot examples")
    func promptPolicy() {
        let prompt = LanguagePack.japanese.prompt
        #expect(prompt.fillerExamples != nil)
        #expect(prompt.capitalizationRule?.contains("Japanese has no sentence capitalization") == true)
        #expect(prompt.codeRendering?.contains("main.py") == true)
        #expect(prompt.terminalGuidance?.contains("--verbose") == true)
        #expect(prompt.codeEditorGuidance != nil)
        #expect(prompt.selfCorrectionRule?.contains("じゃなくて") == true)
        #expect(prompt.addendum?.contains("1,234.56") == true)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Cleanup prompt — Japanese")
struct JapanesePromptTests {
    @Test("Japanese guidance replaces English-specific fallbacks")
    func languageGuidance() {
        let instructions = CleanupPrompt.instructions(
            for: .default,
            locale: "ja-JP")
        #expect(instructions.contains("Japanese has no sentence capitalization"))
        #expect(instructions.contains("「えーと」「えっと」「あのー」"))
        #expect(instructions.contains("「いや」「違う」「じゃなくて」"))
        #expect(instructions.contains("2026年7月26日"))
        #expect(!instructions.contains("five, no six copies"))
        #expect(!instructions.contains(#""um", "uh""#))
    }

    @Test("terminal prompt teaches Japanese shell dictation without few-shot leakage")
    func terminalGuidance() {
        let context = CleanupContext(
            appBundleID: nil,
            appName: nil,
            category: .terminal)
        let instructions = CleanupPrompt.instructions(
            for: .default,
            context: context,
            locale: "ja-JP")
        #expect(instructions.contains("「ハイフン ハイフン verbose」→ --verbose"))
        #expect(instructions.contains("ギット→git"))
        #expect(!instructions.contains("Examples (left = spoken"))
    }
}

@Suite("Rule-based cleanup — Japanese")
struct JapaneseRuleCleanupTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(
            text,
            options: .default,
            context: CleanupContext(appBundleID: nil, appName: nil, category: category),
            locale: "ja-JP")
    }

    @Test("unambiguous fillers are removed only at safe boundaries")
    func fillers() {
        #expect(clean("えっと、今日は晴れです") == "今日は晴れです。")
        #expect(clean("明日は、えーと、雨です") == "明日は、雨です。")
        #expect(clean("あの資料とその資料を比べます") == "あの資料とその資料を比べます。")
        #expect(clean("うーん、今回は見送ります") == "うーん、今回は見送ります。")
    }

    @Test("spoken punctuation renders Japanese marks and is idempotent")
    func spokenPunctuation() {
        #expect(clean("今日は晴れです句点") == "今日は晴れです。")
        #expect(clean("赤読点青読点緑") == "赤、青、緑。")
        #expect(clean("今日は晴れです。句点") == "今日は晴れです。")
        #expect(clean("本当ですか疑問符") == "本当ですか？")
    }

    @Test("spoken quotes, leaders, currency, and line breaks render")
    func extendedSpokenPunctuation() {
        #expect(clean("彼は開きかぎ括弧了解閉じかぎ括弧と言いました")
            == "彼は「了解」と言いました。")
        #expect(clean("まだ考えています三点リーダー") == "まだ考えています……")
        #expect(clean("価格は千円記号です") == "価格は千¥です。")
        #expect(clean("一行目改行二行目") == "一行目\n二行目。")
    }

    @Test("polite interrogative endings gain a full-width question mark")
    func questionEndings() {
        #expect(clean("明日は空いていますか") == "明日は空いていますか？")
        #expect(clean("こちらでよろしいでしょうか") == "こちらでよろしいでしょうか？")
        #expect(clean("一緒に確認しませんか") == "一緒に確認しませんか？")
        #expect(clean("そうか") == "そうか。")
        #expect(clean("行こうか") == "行こうか。")
    }

    @Test("question and exclamation marks separate a following sentence by one em")
    func dividingMarkSpacing() {
        #expect(clean("本当？次を確認します") == "本当？　次を確認します。")
        #expect(clean("成功！次へ進みます") == "成功！　次へ進みます。")
        #expect(clean("彼は「本当？」と言いました") == "彼は「本当？」と言いました。")
    }

    @Test("Japanese brackets are set solid without literal ASCII spaces")
    func bracketSpacing() {
        #expect(clean("彼は 「 了解 」 と言いました") == "彼は「了解」と言いました。")
        #expect(clean("項目 【 重要 】 を確認します") == "項目【重要】を確認します。")
    }

    @Test("full-width punctuation and Japanese terminal period are used")
    func punctuationAndTerminalPeriod() {
        #expect(clean("今日は晴れです,明日は雨です") == "今日は晴れです，明日は雨です。")
        #expect(clean("今日は晴れです!") == "今日は晴れです！")
        #expect(clean("今日は晴れです") == "今日は晴れです。")
    }

    @Test("numbers, dates, currency, and Latin abbreviations survive exactly")
    func mixedNumericAndLatinText() {
        #expect(clean("日付は2026年7月26日です") == "日付は2026年7月26日です。")
        #expect(clean("金額は1,234.56円です") == "金額は1,234.56円です。")
        #expect(clean("AIとVoiceTypeを使います") == "AIとVoiceTypeを使います。")
        #expect(clean("API's valueを確認します") == "API's valueを確認します。")
    }

    @Test("embedded English file names and identifiers remain ASCII")
    func embeddedCode() {
        #expect(clean("main.pyを開きます") == "main.pyを開きます。")
        #expect(clean("get_user_dataを呼びます") == "get_user_dataを呼びます。")
        #expect(clean("gitコマンドを使います") == "gitコマンドを使います。")
    }

    @Test("guarded Japanese symbol names render code-shaped speech")
    func codeSymbols() {
        #expect(clean("main ドット パイを開きます") == "main.pyを開きます。")
        #expect(clean("max アンダースコア retriesを五にします")
            == "max_retriesを五にします。")
        #expect(clean("ドット柄のシャツです") == "ドット柄のシャツです。")
    }

    @Test("terminal flags and paths render without prose punctuation")
    func terminalSymbols() {
        #expect(clean("git commit ハイフン m fix", category: .terminal)
            == "git commit -m fix")
        #expect(clean("npm run build ハイフン ハイフン verbose", category: .terminal)
            == "npm run build --verbose")
        #expect(clean("cd チルダ スラッシュ projects スラッシュ VoiceType",
                      category: .terminal)
            == "cd ~/projects/VoiceType")
    }
}

@Suite("Cleanup polish — Japanese model output")
struct JapanesePolishTests {
    private func polish(_ text: String, category: AppCategory = .general) -> String {
        CleanupPolish.apply(
            text,
            options: .default,
            context: CleanupContext(appBundleID: nil, appName: nil, category: category),
            locale: "ja-JP")
    }

    @Test("model punctuation drift and Japanese spacing are repaired")
    func punctuationRepair() {
        #expect(polish("今日は晴れです,明日は雨です") == "今日は晴れです，明日は雨です。")
        #expect(polish("本当？次を確認します") == "本当？　次を確認します。")
        #expect(polish("彼は 「 了解 」 と言いました") == "彼は「了解」と言いました。")
    }

    @Test("symbols left by the model receive the same guarded rendering")
    func symbolRepair() {
        #expect(polish("config ドット ジェイソンを開きます")
            == "config.jsonを開きます。")
        #expect(polish("git status", category: .terminal) == "git status")
    }

    @Test("Japanese model lead-ins are stripped without touching real prose")
    func sanitizerLeadIn() {
        #expect(CleanupSanitizer.strip(
            "はい、こちらが修正した文章です：今日は晴れです。",
            locale: "ja-JP") == "今日は晴れです。")
        #expect(CleanupSanitizer.strip(
            "こちらが今日の予定です：会議に出ます。",
            locale: "ja-JP") == "こちらが今日の予定です：会議に出ます。")
    }
}
