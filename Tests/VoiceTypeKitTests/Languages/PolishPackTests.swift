import Testing
import Foundation
@testable import VoiceTypeKit

/// Everything specific to the Polish pack. Lives beside the other per-language
/// suites so a contributor working on pl touches exactly one source directory
/// and one test file — see docs/LOCALIZATION.md.
@Suite("Language pack — Polish policy")
struct PolishPackPolicyTests {
    @Test("only never-content hesitations are fillers")
    func fillerPolicy() {
        let pl = LanguagePack.polish
        // "no", "wiesz", "znaczy", "jakby" are real Polish words; "yhy",
        // "mhm" and "aha" mean *yes*. None of them may be stripped blind.
        for word in ["no", "wiesz", "znaczy", "jakby", "yhy", "mhm", "aha", "ee", "prawda"] {
            #expect(!pl.fillers.contains(word), "\(word)")
        }
        #expect(pl.fillers.contains("yyy"))
        #expect(pl.fillers.contains("eee"))
    }

    @Test("no unconditional spoken-punctuation table, no ambiguous question particle")
    func seams() {
        let pl = LanguagePack.polish
        // kropka/przecinek are everyday nouns, so they are rendered by
        // position-guarded rules instead of the unconditional table.
        #expect(pl.spokenPunctuation.isEmpty)
        // "prawda?" is a real tag question but "to prawda" is a statement, and
        // hasSuffix cannot tell them apart.
        #expect(pl.questionSuffixParticles.isEmpty)
        #expect(pl.questionMark == "?")
        #expect(pl.terminalPeriod == ".")
        #expect(pl.separatesWordsWithSpaces)
        #expect(!pl.usesFullWidthPunctuation)
    }

    @Test("every Polish rule is uniquely named and compiles")
    func rules() {
        var seen: Set<String> = []
        for rule in LanguagePack.polish.rules {
            #expect(rule.name.hasPrefix("pl: "), "\(rule.name)")
            #expect(seen.insert(rule.name).inserted, "\(rule.name)")
        }
        #expect(LanguagePack.polish.rules.count >= 8)
    }
}

@Suite("Rule-based cleanup — Polish")
struct PolishRuleCleanupTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(text, options: .default,
                                 context: CleanupContext(category: category),
                                 locale: "pl-PL")
    }

    // MARK: Fillers

    @Test("hesitation runs go, including lengths the fixed list can't spell")
    func fillers() {
        #expect(clean("yyy myślę że to dobry pomysł") == "Myślę, że to dobry pomysł.")
        #expect(clean("nie wiem eee kiedy to zrobię") == "Nie wiem, kiedy to zrobię.")
        #expect(clean("myślę yyyy że to zadziała") == "Myślę, że to zadziała.")
    }

    @Test("words that carry meaning survive: no, wiesz, jakby, and the yes-sounds")
    func ambiguousWordsKept() {
        #expect(clean("no dobra zróbmy to jutro") == "No dobra zróbmy to jutro.")
        #expect(clean("yhy zgadzam się z tobą") == "Yhy zgadzam się z tobą.")
        #expect(clean("ee nie ma mowy") == "Ee nie ma mowy.")
    }

    // MARK: Clause commas

    @Test("the obligatory comma before a subordinate clause is inserted")
    func clauseCommas() {
        #expect(clean("myślę że to dobry pomysł") == "Myślę, że to dobry pomysł.")
        #expect(clean("zrobiłem to bo nie było innego wyjścia")
                == "Zrobiłem to, bo nie było innego wyjścia.")
        #expect(clean("nie przyszedł ponieważ był chory")
                == "Nie przyszedł, ponieważ był chory.")
        #expect(clean("przyjdę wtedy gdy skończę pracę")
                == "Przyjdę wtedy, gdy skończę pracę.")
    }

    @Test("a relative pronoun takes its comma before the preposition governing it")
    func relativeClauses() {
        #expect(clean("to jest dom w którym mieszkam") == "To jest dom, w którym mieszkam.")
        #expect(clean("nie wiem kiedy to zrobię") == "Nie wiem, kiedy to zrobię.")
        #expect(clean("zrób tyle ile trzeba") == "Zrób tyle, ile trzeba.")
    }

    @Test("the exceptions are skipped rather than guessed at")
    func clauseCommaExceptions() {
        // Compound conjunctions take the comma before their FIRST word, which
        // this rule does not attempt to place — so it inserts nothing.
        #expect(clean("zrobię to dlatego że muszę") == "Zrobię to dlatego że muszę.")
        #expect(clean("mimo że padało poszliśmy") == "Mimo że padało poszliśmy.")
        // Two conjunctions in a row take one comma, before the first.
        #expect(clean("powiedział że przyjdzie i że przyniesie wino")
                == "Powiedział, że przyjdzie i że przyniesie wino.")
        // "mało kto" is a quantifier phrase, not a clause.
        #expect(clean("mało kto wie o tym problemie") == "Mało kto wie o tym problemie.")
        // "czy" is not a trigger at all: mid-sentence it usually means "or".
        #expect(clean("chcę dwa czy trzy razy") == "Chcę dwa czy trzy razy.")
    }

    @Test("a comma already in the transcript is never doubled, and cleanup is idempotent")
    func idempotence() {
        let once = clean("myślę że to dobry pomysł i że zadziała")
        #expect(once == clean(once))
        #expect(clean("Myślę, że to dobry pomysł.") == "Myślę, że to dobry pomysł.")
    }

    // MARK: Spoken punctuation

    @Test("spoken marks render where the noun reading is impossible")
    func spokenMarks() {
        #expect(clean("kupimy chleb przecinek mleko i masło kropka")
                == "Kupimy chleb, mleko i masło.")
        #expect(clean("sprawdź to jeszcze raz wykrzyknik") == "Sprawdź to jeszcze raz!")
        #expect(clean("czy to działa znak zapytania") == "Czy to działa?")
        #expect(clean("potrzebuję trzech rzeczy dwukropek chleba mleka i masła")
                == "Potrzebuję trzech rzeczy: chleba mleka i masła.")
        #expect(clean("pierwsza linia nowy akapit druga linia")
                == "Pierwsza linia\n\ndruga linia.")
    }

    @Test("kropka and przecinek stay words where they are words")
    func spokenMarksAreGuarded() {
        // The idiom "i kropka" ("and that's that").
        #expect(clean("to jest moja decyzja i kropka") == "To jest moja decyzja i kropka.")
        // The proverb "kropka nad i".
        #expect(clean("kropka nad i to szczegół") == "Kropka nad i to szczegół.")
        // A dot you can look at.
        #expect(clean("czerwona kropka") == "Czerwona kropka.")
        // Every Polish speaker reads 3,14 as "trzy przecinek czternaście".
        #expect(clean("trzy przecinek czternaście to liczba pi")
                == "Trzy przecinek czternaście to liczba pi.")
    }

    @Test("a mark the engine already rendered is not doubled by the spoken name")
    func spokenMarkIdempotence() {
        #expect(clean("czy to działa? znak zapytania") == "Czy to działa?")
        let once = clean("kupimy chleb przecinek mleko kropka")
        #expect(once == clean(once))
    }

    // MARK: Typography

    @Test("Polish quotation marks, wielokropek, and the spaced półpauza")
    func typography() {
        #expect(clean("powiedział \"zrobię to jutro\" i wyszedł")
                == "Powiedział „zrobię to jutro” i wyszedł.")
        #expect(clean("no nie wiem...") == "No nie wiem…")
        #expect(clean("spotkajmy się w środę - albo w czwartek")
                == "Spotkajmy się w środę – albo w czwartek.")
        // A compound hyphen carries no spaces and must survive untouched.
        #expect(clean("to tekst polsko-niemiecki o e-mailach")
                == "To tekst polsko-niemiecki o e-mailach.")
    }

    @Test("the decimal comma survives the shared spacing pass")
    func decimalComma() {
        #expect(clean("mam 1,5 miliona powodów") == "Mam 1,5 miliona powodów.")
        #expect(clean("to kosztuje 3,14 złotego") == "To kosztuje 3,14 złotego.")
        // A list dictated with spaces is left as a list.
        #expect(clean("wybierz 1, 2, 3 albo 4") == "Wybierz 1, 2, 3 albo 4.")
    }

    @Test("a sentence-opening parenthetical is cut off by a comma")
    func parentheticals() {
        #expect(clean("co ciekawe wszystko działa") == "Co ciekawe, wszystko działa.")
        #expect(clean("krótko mówiąc nie da się") == "Krótko mówiąc, nie da się.")
        #expect(clean("Co ciekawe, wszystko działa") == "Co ciekawe, wszystko działa.")
    }

    // MARK: Questions

    @Test("an interrogative opener gains a question mark")
    func questions() {
        #expect(clean("gdzie jest ten raport") == "Gdzie jest ten raport?")
        #expect(clean("czy możesz to sprawdzić") == "Czy możesz to sprawdzić?")
        #expect(clean("dlaczego to nie działa") == "Dlaczego to nie działa?")
    }

    @Test("openers that only look interrogative keep a period")
    func questionFalsePositives() {
        // The correlative frame, once the clause comma is in place.
        #expect(clean("jak skończysz, to daj znać") == "Jak skończysz, to daj znać.")
        #expect(clean("jak wiadomo wszystko się zmienia")
                == "Jak wiadomo, wszystko się zmienia.")
    }

    // MARK: Code, identifiers, terminal

    @Test("spoken symbols render into file names, identifiers and addresses")
    func spokenSymbols() {
        #expect(clean("wyślij mi plik main kropka py") == "Wyślij mi plik main.py")
        #expect(clean("zmień max podkreślnik retries na dziesięć")
                == "Zmień max_retries na dziesięć.")
        #expect(clean("napisz do mnie jan kropka kowalski małpa gmail kropka com")
                == "Napisz do mnie jan.kowalski@gmail.com")
        // Polish puts the adjective after the noun: "nawias kwadratowy".
        #expect(clean("otwórz nawias kwadratowy zero zamknij nawias kwadratowy")
                == "[zero]")
    }

    @Test("prose that merely mentions a symbol word is never joined")
    func spokenSymbolsAreGuarded() {
        #expect(clean("dodaj podkreślenie tutaj") == "Dodaj podkreślenie tutaj.")
        #expect(clean("zamów łącznik hydrauliczny") == "Zamów łącznik hydrauliczny.")
        #expect(clean("otworzył plik main.py i zaczął pracę")
                == "Otworzył plik main.py i zaczął pracę.")
    }

    @Test("embedded English survives untouched, with no terminal period glued to it")
    func embeddedEnglish() {
        #expect(clean("ta funkcja zwraca wartość typu string")
                == "Ta funkcja zwraca wartość typu string.")
        #expect(clean("sprawdź plik app kropka ts") == "Sprawdź plik app.ts")
    }

    @Test("terminal category stays command-safe")
    func terminalCategory() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("uruchom git push myślnik myślnik force", category: .terminal)
                == "uruchom git push --force")
        #expect(clean("cd tylda ukośnik projekty ukośnik voice", category: .terminal)
                == "cd ~/projekty/voice")
        // No prose typography in a shell: no capital, no period, no dash swap.
        #expect(clean("ls -la /tmp", category: .terminal) == "ls -la /tmp")
    }

    @Test("a code editor keeps quote and dash characters as typed")
    func codeEditorCategory() {
        #expect(clean("let x = \"abc\"", category: .codeEditor).contains("\"abc\""))
        #expect(clean("a - b", category: .codeEditor).contains(" - "))
    }
}

@Suite("Cleanup polish — Polish model output")
struct PolishPolishTests {
    private func polish(_ text: String, category: AppCategory = .general) -> String {
        CleanupPolish.apply(text, options: .default,
                            context: CleanupContext(category: category),
                            locale: "pl-PL")
    }

    /// Note the missing terminal period: `CleanupPolish` deliberately doesn't
    /// append one for a Latin pack — the model punctuates its own sentences,
    /// and a blind period would land on file names. The pack's rules still
    /// run, which is what these assert.
    @Test("the pack's orthography holds over model output too")
    func rulesRunInBothPaths() {
        #expect(polish("myślę że to dobry pomysł") == "Myślę, że to dobry pomysł")
        #expect(polish("powiedział \"nie\" i wyszedł") == "Powiedział „nie” i wyszedł")
        #expect(polish("no nie wiem...") == "No nie wiem…")
    }

    @Test("an unpunctuated interrogative opener gains a question mark and a capital")
    func questionAndCapital() {
        #expect(polish("gdzie jest raport") == "Gdzie jest raport?")
    }

    @Test("a Polish model lead-in is stripped by the pack's own patterns")
    func leadIn() {
        let stripped = CleanupSanitizer.strip("Oto oczyszczony tekst: Myślę, że to dobry pomysł.",
                                              locale: "pl-PL")
        #expect(stripped == "Myślę, że to dobry pomysł.")
        let opener = CleanupSanitizer.strip("Jasne, oto wynik: Kupimy chleb.", locale: "pl-PL")
        #expect(opener == "Kupimy chleb.")
    }

    @Test("terminal model output is left command-shaped")
    func terminal() {
        #expect(polish("git status", category: .terminal) == "git status")
    }
}

@Suite("Cleanup prompt — Polish guidance")
struct PolishPromptTests {
    private var instructions: String {
        CleanupPrompt.instructions(for: .default, locale: "pl-PL")
    }

    @Test("the prompt names Polish and carries Polish hesitation sounds")
    func language() {
        #expect(instructions.contains("Polish"))
        #expect(instructions.contains("yyy"))
        #expect(!instructions.contains("\"um\""))
    }

    @Test("capitalization guidance states the rules English gets wrong")
    func capitalization() {
        // Days and months are lowercase in Polish; the generic rule says the
        // opposite, so the pack must replace it wholesale.
        #expect(instructions.contains("poniedziałek"))
        #expect(instructions.contains("styczeń"))
        #expect(!instructions.contains(CleanupPrompt.genericCapitalizationRule))
    }

    @Test("self-correction and code guidance are Polish, not English fallbacks")
    func sections() {
        #expect(!instructions.contains(CleanupPrompt.genericSelfCorrectionRule))
        #expect(instructions.contains("podkreślnik"))
        #expect(instructions.contains("małpa"))
    }

    @Test("terminal guidance appears only for the terminal category")
    func terminal() {
        let shell = CleanupPrompt.instructions(
            for: .default,
            context: CleanupContext(category: .terminal),
            locale: "pl-PL")
        #expect(shell.contains("--verbose"))
        #expect(!instructions.contains("--verbose"))
    }

    @Test("no few-shot examples ship until a model eval earns them")
    func noFewShot() {
        #expect(LanguagePack.polish.prompt.fewShot.isEmpty)
        #expect(LanguagePack.polish.prompt.terminalFewShot.isEmpty)
    }
}
