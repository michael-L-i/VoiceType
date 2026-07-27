import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Language pack — Bulgarian policy")
struct BulgarianPackPolicyTests {
    @Test("only unmistakable hesitation spellings are deterministic fillers")
    func fillers() {
        let bg = LanguagePack.bulgarian
        #expect(bg.fillers.contains("ъъъ"))
        #expect(bg.fillers.contains("ъм"))
        #expect(bg.fillers.contains("ааа"))
        #expect(!bg.fillers.contains("а"))
        #expect(!bg.fillers.contains("ами"))
        #expect(!bg.fillers.contains("значи"))
        #expect(!bg.fillers.contains("нали"))
        #expect(!bg.fillers.contains("мхм"))
    }

    @Test("symbol rendering stays local and few-shot examples stay unshipped")
    func scopedFeatures() {
        let bg = LanguagePack.bulgarian
        #expect(bg.symbols == nil)
        #expect(bg.spokenPunctuation.isEmpty)
        #expect(bg.prompt.codeRendering != nil)
        #expect(bg.prompt.terminalGuidance != nil)
        #expect(bg.prompt.codeEditorGuidance != nil)
        #expect(bg.prompt.selfCorrectionRule != nil)
        #expect(bg.prompt.fewShot.isEmpty)
        #expect(bg.prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Bulgarian")
struct BulgarianRuleCleanupTests {
    private func clean(_ text: String,
                       category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(
            text,
            options: .default,
            context: CleanupContext(category: category),
            locale: "bg-BG")
    }

    @Test("prolonged hesitation vowels are removed without deleting content")
    func fillerRemoval() {
        #expect(clean("ъъъ, днес ще изпратя доклада") == "Днес ще изпратя доклада.")
        #expect(clean("мисля ъм че е готово") == "Мисля че е готово.")
        #expect(clean("ааа нека започнем") == "Нека започнем.")
    }

    @Test("meaningful filler lookalikes are retained")
    func ambiguousFillersStay() {
        let out = clean("ами това значи нещо нали")
        #expect(out == "Ами това значи нещо нали.")
        #expect(out.lowercased().contains("ами"))
        #expect(out.contains("значи"))
        #expect(out.contains("нали"))
    }

    @Test("unambiguous spoken punctuation renders with Bulgarian spacing")
    func spokenPunctuation() {
        #expect(clean("първо запетая второ") == "Първо, второ.")
        #expect(clean("кажи двоеточие готово") == "Кажи: готово.")
        #expect(clean("това вярно ли е въпросителен знак") == "Това вярно ли е?")
        #expect(clean("важно удивителен знак") == "Важно!")
        #expect(clean("пауза многоточие после") == "Пауза… после.")
    }

    @Test("spoken punctuation is idempotent around an existing mark")
    func spokenPunctuationIdempotence() {
        #expect(clean("първо, запетая, второ") == "Първо, второ.")
        #expect(clean("готово? въпросителен знак") == "Готово?")
    }

    @Test("question openers and sentence-final ли gain a question mark")
    func questions() {
        #expect(clean("къде е докладът") == "Къде е докладът?")
        #expect(clean("защо закъсня") == "Защо закъсня?")
        #expect(clean("така ли") == "Така ли?")
    }

    @Test("embedded ли is not mistaken for a standalone question")
    func embeddedQuestion() {
        #expect(clean("не знам има ли време") == "Не знам има ли време.")
    }

    @Test("decimal commas and abbreviation periods survive shared passes")
    func protectedPunctuation() {
        #expect(clean("стойността е 3,14") == "Стойността е 3,14.")
        #expect(clean("срещата е в 10 ч. утре") == "Срещата е в 10 ч. утре.")
        #expect(clean("виж стр. пета за подробности") == "Виж стр. пета за подробности.")
    }

    @Test("Bulgarian quotation marks and elision apostrophes normalize")
    func typography() {
        #expect(clean(#"той каза "готово""#) == "Той каза „готово“.")
        // The pack guarantees quote glyphs; the shared capitalization option
        // deliberately does not reach through leading punctuation.
        #expect(clean("“това е цитат”") == "„това е цитат“.")
        #expect(clean("наш'та среща е утре") == "Наш’та среща е утре.")
    }

    @Test("currency follows the amount with a nonbreaking space")
    func currencySpacing() {
        #expect(clean("цената е 50EUR") == "Цената е 50\u{00A0}EUR.")
        #expect(clean("струва 3,14€") == "Струва 3,14\u{00A0}€.")
        #expect(clean("бюджетът е 200лв") == "Бюджетът е 200\u{00A0}лв.")
    }

    @Test("spoken file and identifier symbols render compactly")
    func codeSymbols() {
        #expect(clean("отвори main точка py") == "Отвори main.py")
        #expect(clean("преименувай на test долна черта client точка py")
            == "Преименувай на test_client.py")
        #expect(clean("извикай print отваряща скоба x запетая y затваряща скоба")
            == "Извикай print(x, y)")
    }

    @Test("ordinary uses of точка and долна черта stay prose")
    func spokenSymbolProseGuards() {
        #expect(clean("това е отправна точка за проекта")
            == "Това е отправна точка за проекта.")
        #expect(clean("добави долна черта на графиката")
            == "Добави долна черта на графиката.")
    }

    @Test("embedded Latin identifiers and dates remain unchanged")
    func mixedScriptPreservation() {
        #expect(clean("провери config.json и APIClient")
            == "Провери config.json и APIClient.")
        #expect(clean("срокът е 26.07.2026 г.")
            == "Срокът е 26.07.2026 г.")
        #expect(clean("версията е 2.0") == "Версията е 2.0")
    }

    @Test("terminal rendering is useful but command-safe")
    func terminal() {
        #expect(clean("git commit тире m fix", category: .terminal)
            == "git commit -m fix")
        #expect(clean("npm run build тире тире verbose", category: .terminal)
            == "npm run build --verbose")
        #expect(clean("cd тилда наклонена черта projects наклонена черта VoiceType",
                      category: .terminal)
            == "cd ~/projects/VoiceType")
        #expect(clean("echo 3,14", category: .terminal) == "echo 3,14")
        #expect(clean("git status", category: .terminal) == "git status")
    }

    @Test("code editor keeps straight code-string quotes")
    func codeEditorQuotes() {
        #expect(clean(#"let value = "готово""#, category: .codeEditor)
            == #"Let value = "готово"."#)
    }
}

@Suite("Cleanup polish — Bulgarian model output")
struct BulgarianPolishTests {
    @Test("model output receives the same typography repairs")
    func typography() {
        let out = CleanupPolish.apply(
            #"той каза "готово" и цената е 3,14EUR"#,
            options: .default,
            locale: "bg-BG")
        #expect(out == "Той каза „готово“ и цената е 3,14\u{00A0}EUR")
    }

    @Test("model output receives local spoken-symbol rendering")
    func symbols() {
        let out = CleanupPolish.apply(
            "отвори test долна черта client точка py",
            options: .default,
            locale: "bg-BG")
        #expect(out == "Отвори test_client.py")
    }

    @Test("terminal model output stays lowercase and unpunctuated")
    func terminal() {
        let out = CleanupPolish.apply(
            "git commit тире m fix",
            options: .default,
            context: CleanupContext(category: .terminal),
            locale: "bg-BG")
        #expect(out == "git commit -m fix")
    }
}

@Suite("Cleanup prompt — Bulgarian guidance")
struct BulgarianPromptTests {
    @Test("prompt carries Bulgarian-specific cleanup and code guidance")
    func guidance() {
        let instructions = CleanupPrompt.instructions(
            for: .default,
            context: CleanupContext(category: .terminal),
            locale: "bg-BG")
        #expect(instructions.contains("ъъъ"))
        #expect(instructions.contains("ами"))
        #expect(instructions.contains("ѝ"))
        #expect(instructions.contains("долна черта"))
        #expect(instructions.contains("--verbose"))
        #expect(instructions.contains("„…“"))
        #expect(!instructions.contains("five, no six copies"))
    }
}
