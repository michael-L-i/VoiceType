import Foundation
import Testing
@testable import VoiceTypeKit

@Suite("Language pack — Russian policy")
struct RussianPackPolicyTests {
    @Test("only unmistakably lengthened hesitation vowels are blind fillers")
    func conservativeFillers() {
        let ru = LanguagePack.russian
        #expect(ru.fillers == ["ээ", "эээ", "э-э", "э-э-э"])
        #expect(!ru.fillers.contains("э"))
        #expect(!ru.fillers.contains("эм"))
        #expect(!ru.fillers.contains("ммм"))
        #expect(!ru.fillers.contains("ну"))
        #expect(!ru.fillers.contains("типа"))
    }

    @Test("ambiguous point/minus words stay out of unconditional punctuation")
    func ambiguousSymbols() {
        let ru = LanguagePack.russian
        #expect(ru.spokenPunctuation.isEmpty)
        #expect(ru.symbols == nil)
        #expect(ru.spokenSymbolWords.contains("точка"))
        #expect(ru.spokenSymbolWords.contains("подчёркивание"))
    }

    @Test("Russian guard stopwords include function and correction words")
    func stopwords() {
        let ru = LanguagePack.russian
        #expect(ru.stopwords.contains("и"))
        #expect(ru.stopwords.contains("вы"))
        #expect(ru.stopwords.contains("точнее"))
        #expect(!ru.stopwords.contains("развернуть"))
    }
}

@Suite("Rule-based cleanup — Russian")
struct RussianRuleCleanupTests {
    private func clean(_ text: String,
                       category: AppCategory = .general,
                       options: CleanupOptions = .default) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(category: category),
            locale: "ru-RU")
    }

    @Test("lengthened fillers are removed cleanly")
    func fillers() {
        #expect(clean("ээ сегодня встречаемся в семь") == "Сегодня встречаемся в семь.")
        #expect(clean("я думаю, э-э, надо подождать") == "Я думаю, надо подождать.")
    }

    @Test("letter names and meaningful discourse words are retained")
    func ambiguousFillersKept() {
        #expect(clean("эм это имя латинской буквы") == "Эм это имя латинской буквы.")
        #expect(clean("ну вот и всё") == "Ну вот и всё.")
        #expect(clean("это типа данных") == "Это типа данных.")
    }

    @Test("conventional spoken punctuation commands render with Russian spacing")
    func spokenPunctuation() {
        #expect(clean("привет запятая как дела вопросительный знак")
            == "Привет, как дела?")
        #expect(clean("важно восклицательный знак") == "Важно!")
        #expect(clean("первое точка с запятой второе") == "Первое; второе.")
        #expect(clean("он ответил двоеточие готово") == "Он ответил: готово.")
    }

    @Test("spoken punctuation is idempotent when ASR already emitted the mark")
    func spokenPunctuationIdempotent() {
        #expect(clean("готово! восклицательный знак") == "Готово!")
        #expect(clean("первое, запятая второе") == "Первое, второе.")
    }

    @Test("spoken line and paragraph breaks survive the shared whitespace pass")
    func spokenLineBreaks() {
        #expect(clean("первая строка новая строка вторая строка")
            == "Первая строка\nвторая строка.")
        #expect(clean("первый абзац новый абзац второй абзац")
            == "Первый абзац\n\nвторой абзац.")
    }

    @Test("ambiguous точка remains prose outside anchored technical patterns")
    func pointWordKept() {
        #expect(clean("точка зрения изменилась") == "Точка зрения изменилась.")
        #expect(clean("точка доступа недоступна") == "Точка доступа недоступна.")
    }

    @Test("interrogative openers gain a question mark")
    func questionHeuristic() {
        #expect(clean("почему сборка упала") == "Почему сборка упала?")
        #expect(clean("где лежит файл") == "Где лежит файл?")
    }

    @Test("decimal commas survive without a spurious space")
    func decimalComma() {
        #expect(clean("значение равно 3,14") == "Значение равно 3,14.")
        #expect(clean("версия 2.4.1 готова") == "Версия 2.4.1 готова.")
    }

    @Test("Russian ellipses and combined terminal marks survive")
    func ellipses() {
        #expect(clean("я пока не знаю...") == "Я пока не знаю...")
        #expect(clean("и что теперь?..") == "И что теперь?..")
        #expect(clean("вот это да!..") == "Вот это да!..")
    }

    @Test("common multipart abbreviations gain spaces without false sentence casing")
    func abbreviations() {
        #expect(clean("это т.е. рабочий вариант") == "Это т. е. рабочий вариант.")
        #expect(clean("т.д. писать не нужно") == "Т. д. писать не нужно.")
        #expect(clean("нужны логи и т.п. материалы") == "Нужны логи и т. п. материалы.")
    }

    @Test("straight and English smart quotation marks become Russian guillemets")
    func quotes() {
        #expect(clean(#""готово.""#) == "«Готово».")
        #expect(clean("он назвал это “быстрым решением”")
            == "Он назвал это «быстрым решением».")
    }

    @Test("question and exclamation marks belonging to quotes stay inside")
    func quoteTerminalMarks() {
        #expect(clean(#""готово?""#) == "«Готово?»")
        #expect(clean(#""осторожно!""#) == "«Осторожно!»")
    }

    @Test("grouped numbers currencies and measurement units use nonbreaking spaces")
    func numberSpacing() {
        #expect(clean("бюджет 1 000 000 рублей")
            == "Бюджет 1\u{00A0}000\u{00A0}000 рублей.")
        #expect(clean("это стоит 100₽") == "Это стоит 100\u{00A0}₽.")
        #expect(clean("температура 20°С и влажность 80%")
            == "Температура 20\u{00A0}°С и влажность 80\u{00A0}%.")
    }

    @Test("date dots and foreign-name apostrophes are preserved")
    func datesAndApostrophes() {
        #expect(clean("встреча назначена на 26.07.2026")
            == "Встреча назначена на 26.07.2026")
        #expect(clean("это книга О’Брайена") == "Это книга О’Брайена.")
    }

    @Test("context-anchored file and identifier symbols render deterministically")
    func technicalSymbols() {
        #expect(clean("main точка пай") == "main.py")
        #expect(clean("config точка json готов") == "config.json готов.")
        #expect(clean("max нижнее подчеркивание retries") == "max_retries")
        #expect(clean("ivan собака gmail точка com") == "ivan@gmail.com")
    }

    @Test("embedded English identifiers retain script and case")
    func embeddedEnglish() {
        #expect(clean("открой VoiceType и файл main.py")
            == "Открой VoiceType и файл main.py")
        #expect(clean("метод parseRequest уже готов") == "Метод parseRequest уже готов.")
    }

    @Test("terminal rendering is command-safe and opts into flags and paths only")
    func terminalCategory() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("git checkout дефис b", category: .terminal) == "git checkout -b")
        #expect(clean("ls дефис дефис all", category: .terminal) == "ls --all")
        #expect(clean("cd тильда слэш projects слэш VoiceType", category: .terminal)
            == "cd ~/projects/VoiceType")
        #expect(clean("echo вопросительный знак", category: .terminal)
            == "echo вопросительный знак")
    }

    @Test("terminal-safe placeholder pairs never leak")
    func terminalProtectedSequences() {
        #expect(clean("printf 3,14", category: .terminal) == "printf 3,14")
        #expect(clean("echo ...", category: .terminal) == "echo ...")
    }

    @Test("code editor skips prose number typography")
    func codeEditorNumberSafety() {
        #expect(clean("let ratio = 80%", category: .codeEditor) == "Let ratio = 80%.")
    }
}

@Suite("Cleanup polish — Russian model output")
struct RussianPolishTests {
    private func polish(_ text: String,
                        category: AppCategory = .general) -> String {
        CleanupPolish.apply(
            text,
            options: .default,
            context: CleanupContext(category: category),
            locale: "ru-RU")
    }

    @Test("Russian rules repair punctuation words and decimal commas after the model")
    func mechanicalRepairs() {
        #expect(polish("привет запятая мир") == "Привет, мир")
        #expect(polish("значение 3,14") == "Значение 3,14")
        #expect(polish(#""готово.""#) == "«Готово».")
    }

    @Test("spoken file symbols repair model output without pack.symbols")
    func symbols() {
        #expect(LanguagePack.russian.symbols == nil)
        #expect(polish("main точка пай") == "main.py")
        #expect(polish("max нижнее подчёркивание retries") == "max_retries")
    }

    @Test("terminal model polish leaves commands bare")
    func terminal() {
        #expect(polish("git checkout дефис b", category: .terminal) == "git checkout -b")
    }
}

@Suite("Cleanup prompt — Russian")
struct RussianPromptTests {
    @Test("prompt supplies all Russian guidance without few-shot leakage")
    func guidance() {
        let ru = LanguagePack.russian.prompt
        #expect(ru.fillerExamples?.contains("как бы") == true)
        #expect(ru.capitalizationRule?.contains("понедельник") == true)
        #expect(ru.codeRendering?.contains("main.py") == true)
        #expect(ru.terminalGuidance?.contains("--verbose") == true)
        #expect(ru.codeEditorGuidance?.contains("API") == true)
        #expect(ru.selfCorrectionRule?.contains("во вторник") == true)
        #expect(ru.addendum?.contains("26.07.2026") == true)
        #expect(ru.fewShot.isEmpty)
        #expect(ru.terminalFewShot.isEmpty)
    }

    @Test("rendered instructions stay Russian-specific and anti-translation")
    func renderedPrompt() {
        let prompt = CleanupPrompt.instructions(for: .default, locale: "ru-RU")
        #expect(prompt.contains("The dictation is in Russian"))
        #expect(prompt.contains("NEVER translate"))
        #expect(prompt.contains("Outer quotation marks"))
        #expect(prompt.contains("нижнее подчёркивание"))
        #expect(!prompt.contains(#""five, no six copies""#))
    }

    @Test("Russian model lead-ins are stripped conservatively")
    func sanitizer() {
        #expect(CleanupSanitizer.strip(
            "Конечно! Вот исправленный текст: привет, мир.",
            locale: "ru-RU") == "привет, мир.")
        #expect(CleanupSanitizer.strip(
            "Вот исправленный текст: привет, мир.",
            locale: "ru-RU") == "привет, мир.")
        #expect(CleanupSanitizer.strip(
            "Вот мой текст: привет, мир.",
            locale: "ru-RU") == "Вот мой текст: привет, мир.")
    }
}
