import Foundation
import Testing
@testable import VoiceTypeKit

@Suite("Language pack — Ukrainian policy")
struct UkrainianPackPolicyTests {
    @Test("keeps deterministic fillers nonlexical and contextual lookalikes")
    func fillers() {
        let uk = LanguagePack.ukrainian
        #expect(uk.fillers == ["е-е", "е-е-е"])
        for contentWord in ["е", "ем", "гм", "мм", "ну", "так", "типу", "значить", "коротше", "власне", "ось"] {
            #expect(!uk.fillers.contains(contentWord))
        }
    }

    @Test("uses a language-owned symbol rule without claiming the reserved pack field")
    func symbolPolicy() {
        let uk = LanguagePack.ukrainian
        #expect(uk.symbols == nil)
        #expect(uk.spokenPunctuation.isEmpty)
        #expect(uk.spokenSymbolWords.contains("крапка"))
        #expect(uk.rules.contains { $0.name == "render structurally explicit Ukrainian spoken symbols" })
    }

    @Test("ships complete Ukrainian prompt guidance without unvalidated few-shots")
    func promptPolicy() {
        let prompt = LanguagePack.ukrainian.prompt
        #expect(prompt.fillerExamples?.contains("е-е") == true)
        #expect(prompt.capitalizationRule?.contains("weekdays") == true)
        #expect(prompt.codeRendering?.contains("main.py") == true)
        #expect(prompt.terminalGuidance?.contains("--verbose") == true)
        #expect(prompt.codeEditorGuidance?.contains("API") == true)
        #expect(prompt.selfCorrectionRule?.contains("шість копій") == true)
        #expect(prompt.addendum?.contains("Never translate it into Russian") == true)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Ukrainian")
struct UkrainianRuleCleanupTests {
    private func clean(
        _ text: String,
        category: AppCategory = .general,
        options: CleanupOptions = .default
    ) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(
                appBundleID: nil,
                appName: nil,
                category: category),
            locale: "uk-UA")
    }

    @Test("removes prolonged hesitation sounds but preserves lexical lookalikes")
    func fillers() {
        #expect(clean("е-е ми починаємо") == "Ми починаємо.")
        #expect(clean("е-е-е, це готово") == "Це готово.")
        #expect(clean("ну це значить багато") == "Ну це значить багато.")
        #expect(clean("цей розчин типу емульсії") == "Цей розчин типу емульсії.")
    }

    @Test("normalizes punctuation spacing and preserves decimal commas")
    func punctuationAndDecimals() {
        #expect(clean("ціна 3,14,а похибка мала") == "Ціна 3,14, а похибка мала.")
        #expect(clean("готово !  так ,працює") == "Готово! Так, працює.")
    }

    @Test("renders unambiguous spoken punctuation and paired marks")
    func spokenPunctuation() {
        #expect(clean("увага двокрапка починаємо") == "Увага: починаємо.")
        #expect(clean("це справді працює знак питання") == "Це справді працює?")
        #expect(clean("перший крапка з комою другий") == "Перший; другий.")
        #expect(clean("він сказав відкриті лапки готово закриті лапки")
            == "Він сказав «готово».")
        #expect(clean("масив відкрита квадратна дужка 0 закрита квадратна дужка")
            == "Масив [0]")
    }

    @Test("spoken punctuation is idempotent when recognition already emitted a mark")
    func spokenPunctuationIdempotence() {
        #expect(clean("це готово? знак питання") == "Це готово?")
        #expect(clean("зачекай... три крапки") == "Зачекай…")
    }

    @Test("normalizes present apostrophes without guessing missing ones")
    func apostrophes() {
        #expect(clean("п ' ять обʼєктів") == "П’ять об’єктів.")
        #expect(clean("обєкт готовий") == "Обєкт готовий.")
        #expect(clean("комп'ютер працює") == "Комп’ютер працює.")
    }

    @Test("uses guillemets for quoted Ukrainian while preserving ASCII code strings")
    func quotationMarks() {
        #expect(clean(#"він сказав "усе готово""#) == "Він сказав «усе готово».")
        #expect(clean(#"значення "ready" не змінюй"#) == #"Значення "ready" не змінюй."#)
    }

    @Test("preserves ellipses in prose but leaves code-editor variadics alone")
    func ellipses() {
        #expect(clean("можливо... але перевірмо") == "Можливо… але перевірмо.")
        #expect(clean("func call...", category: .codeEditor) == "Func call.")
    }

    @Test("compacts date-like dot groups")
    func numericDates() {
        // The shared engine conservatively leaves a dot-delimited numeric tail
        // bare, just as it leaves a file name bare.
        #expect(clean("зустріч 7. 8. 2026") == "Зустріч 7.8.2026")
        #expect(clean("дата 26.07.2026") == "Дата 26.07.2026")
    }

    @Test("keeps known abbreviations from falsely starting a new sentence")
    func abbreviationCapitalization() {
        #expect(clean("див. наступний розділ") == "Див. наступний розділ.")
        #expect(clean("це описано на стор. п’ять") == "Це описано на стор. п’ять.")
    }

    @Test("uses nonbreaking spaces only where numeric grouping or a unit is explicit")
    func nonbreakingSpaces() {
        #expect(clean("це коштує 1 250 грн") == "Це коштує 1\u{00A0}250\u{00A0}грн.")
        #expect(clean("знижка 20 %") == "Знижка 20\u{00A0}%.")
        #expect(clean("бюджет 500 ₴") == "Бюджет 500\u{00A0}₴.")
    }

    @Test("marks explicit interrogative openers and leaves intonation-only questions conservative")
    func questions() {
        #expect(clean("чи готовий реліз") == "Чи готовий реліз?")
        #expect(clean("невже це працює") == "Невже це працює?")
        #expect(clean("ти готовий") == "Ти готовий.")
    }

    @Test("renders explicit file names, identifiers, emails, and parentheses")
    func spokenSymbols() {
        #expect(clean("відкрий main крапка пі") == "Відкрий main.py")
        #expect(clean("відкрий index крапка джей ес") == "Відкрий index.js")
        #expect(clean("змінна user андерскор id") == "Змінна user_id")
        #expect(clean("напиши user равлик example крапка com") == "Напиши user@example.com")
        #expect(clean("виклич print відкрита дужка x кома y закрита дужка")
            == "Виклич print(x, y)")
    }

    @Test("symbol lookalikes remain ordinary prose outside structural contexts")
    func spokenSymbolGuards() {
        #expect(clean("це важлива крапка на карті") == "Це важлива крапка на карті.")
        #expect(clean("постав підкреслення під словом") == "Постав підкреслення під словом.")
        #expect(clean("мінус цього плану очевидний") == "Мінус цього плану очевидний.")
    }

    @Test("embedded English identifiers and Ukrainian letters survive untouched")
    func mixedScript() {
        #expect(clean("перевір APIClient і main.py у новому об’єкті")
            == "Перевір APIClient і main.py у новому об’єкті.")
    }

    @Test("terminal rendering is command-safe and handles flags and paths")
    func terminalCategory() {
        #expect(clean("git commit мінус ем fix", category: .terminal) == "git commit -m fix")
        #expect(clean("git log мінус мінус oneline", category: .terminal) == "git log --oneline")
        #expect(clean("cd тильда слеш projects слеш VoiceType", category: .terminal)
            == "cd ~/projects/VoiceType")
        #expect(clean("echo 3,14", category: .terminal) == "echo 3,14")
        #expect(clean("echo знак питання", category: .terminal) == "echo знак питання")
    }

    @Test("cleanup is idempotent")
    func idempotence() {
        let once = clean(#"е-е він сказав "ціна 1 250 грн""#)
        #expect(clean(once) == once)
    }
}

@Suite("Cleanup polish — Ukrainian model output")
struct UkrainianPolishTests {
    @Test("language rules repair model punctuation and typography too")
    func orthography() {
        let out = CleanupPolish.apply(
            #"він сказав "п ' ять товарів коштують 3,14 грн""#,
            options: .default,
            locale: "uk-UA")
        // Latin-script polish repairs existing punctuation but only guarantees
        // a terminal mark for questions; the model normally supplies periods.
        #expect(out == "Він сказав «п’ять товарів коштують 3,14\u{00A0}грн»")
    }

    @Test("known abbreviations do not trigger polish capitalization")
    func abbreviations() {
        let out = CleanupPolish.apply(
            "див. наступний розділ",
            options: .default,
            locale: "uk-UA")
        #expect(out == "Див. наступний розділ")
    }

    @Test("model output gets the same structurally explicit symbol rendering")
    func symbols() {
        let out = CleanupPolish.apply(
            "відкрий main крапка пі",
            options: .default,
            locale: "uk-UA")
        #expect(out == "Відкрий main.py")
    }
}

@Suite("Cleanup prompt — Ukrainian")
struct UkrainianPromptTests {
    @Test("general guidance covers Ukrainian-specific ambiguity and orthography")
    func general() {
        let prompt = CleanupPrompt.instructions(
            for: .default,
            locale: "uk-UA")
        #expect(prompt.contains("Keep the output Ukrainian"))
        #expect(prompt.contains("Never translate it into Russian"))
        #expect(prompt.contains("outer quotation marks «…»"))
        #expect(prompt.contains("п’ять, об’єкт"))
        #expect(prompt.contains("main крапка пі"))
        #expect(prompt.contains("when in doubt, keep it"))
        #expect(!prompt.contains("Examples (left = spoken"))
    }

    @Test("terminal guidance teaches Ukrainian flags and paths")
    func terminal() {
        let prompt = CleanupPrompt.instructions(
            for: .default,
            context: CleanupContext(
                appBundleID: nil,
                appName: nil,
                category: .terminal),
            locale: "uk-UA")
        #expect(prompt.contains("мінус мінус verbose"))
        #expect(prompt.contains("тильда слеш projects"))
        #expect(prompt.contains("Do not capitalize a command"))
    }
}
