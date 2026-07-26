import Testing
import Foundation
@testable import VoiceTypeKit

/// Everything specific to the Spanish pack. Lives beside the other
/// per-language suites so a contributor working on es touches exactly one
/// source directory and one test file — see docs/LOCALIZATION.md.
@Suite("Language pack — Spanish policy")
struct SpanishPackPolicyTests {
    @Test("fillers are hesitation sounds only — discourse markers stay")
    func fillerPolicy() {
        let es = LanguagePack.spanish
        for marker in ["este", "esto", "pues", "bueno", "vale", "claro", "tipo", "digamos"] {
            #expect(!es.fillers.contains(marker), "\(marker) is a real Spanish word")
        }
        // "mm" is the millimetre symbol; only the tripled nasal is a filler.
        #expect(!es.fillers.contains("mm"))
        #expect(es.fillers.contains("eh"))
        #expect(es.fillers.contains("mmm"))
    }

    @Test("the unconditional spoken-punctuation table stays empty")
    func noBlindSpokenPunctuation() {
        // "punto" and "coma" are everyday Spanish words; the multi-word
        // commands are rendered by rules instead, which can be anchored.
        #expect(LanguagePack.spanish.spokenPunctuation.isEmpty)
    }

    @Test("question openers are interrogative words, never verbs")
    func questionOpeners() {
        let es = LanguagePack.spanish
        // Spanish yes/no questions don't invert, so a verb opener would turn
        // "es bueno" (a statement) into a question.
        for verb in ["es", "son", "puede", "tiene", "hay"] {
            #expect(!es.questionPrefixWords.contains(verb))
        }
        #expect(es.questionPrefixWords.contains("dónde"))
        #expect(SpanishOrthography.questionOpeners.contains("por qué"))
    }

    @Test("only the symbol renderer opts into terminal dictation")
    func rulesSkipTerminal() {
        // Everything typographic — ¿ ¡, « », symbol spacing, capitalization —
        // stays out of a shell, where a "correction" is corruption. The two
        // exceptions are the spoken-symbol renderer and the "guion bajo" join
        // that has to precede it: rendering "guion guion verbose" as --verbose
        // is the whole point of dictating into a terminal.
        let optedIn = LanguagePack.spanish.rules.filter(\.runsInTerminal).map(\.name)
        #expect(optedIn == [
            "es: spoken «guion bajo» joins an identifier",
            "es: spoken symbols render file names, identifiers and paths",
        ])
    }

    @Test("the diacritic restorer deliberately excludes «qué»")
    func tildePolicy() {
        // "¿Que te vas?" is a correctly unaccented echo question, and dictation
        // is spoken Spanish.
        #expect(SpanishOrthography.interrogativeTildes["que"] == nil)
        #expect(SpanishOrthography.interrogativeTildes["donde"] == "dónde")
    }
}

@Suite("Rule-based cleanup — Spanish")
struct SpanishRuleCleanupTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(text, options: .default,
                                 context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                                 locale: "es-ES")
    }

    // MARK: Fillers

    @Test("hesitation sounds are removed, discourse markers are not")
    func fillers() {
        #expect(clean("eh creo que sí") == "Creo que sí.")
        #expect(clean("me parece, ehm, buena idea") == "Me parece, buena idea.")
        #expect(clean("este informe es bueno") == "Este informe es bueno.")
        #expect(clean("pues bueno, o sea, no sé") == "Pues bueno, o sea, no sé.")
    }

    // MARK: Opening marks

    @Test("a question gains both marks, not just the closing one")
    func openingQuestionMark() {
        #expect(clean("qué hora es") == "¿Qué hora es?")
        #expect(clean("dónde está el informe") == "¿Dónde está el informe?")
    }

    @Test("multi-word interrogative openers are recognized too")
    func multiWordOpeners() {
        #expect(clean("por qué no lo hacemos mañana") == "¿Por qué no lo hacemos mañana?")
        #expect(clean("hasta cuándo dura la promoción") == "¿Hasta cuándo dura la promoción?")
    }

    @Test("a statement is never turned into a question")
    func statementsUntouched() {
        #expect(clean("no sé si vendrá") == "No sé si vendrá.")
        #expect(clean("es bueno") == "Es bueno.")
        // Accepted limitation, inherited from the shared single-token
        // heuristic: an indirect question opening with an interrogative word
        // still reads as a direct question. Our own rule declines it (the
        // internal comma is its guard), but the shared pass has already
        // appended the "?" by the time a rule can see the text.
        #expect(clean("cómo lo hizo, no lo sé") == "¿Cómo lo hizo, no lo sé?")
        // Multi-word openers ARE ours, so the comma guard holds for them.
        #expect(clean("por qué lo hizo, nadie lo sabe") == "Por qué lo hizo, nadie lo sabe.")
    }

    @Test("an exclamation gains its ¡")
    func openingExclamationMark() {
        #expect(clean("qué alegría verte!") == "¡Qué alegría verte!")
    }

    @Test("marks the engine already produced are left alone (idempotent)")
    func idempotent() {
        let once = clean("¿Qué hora es?")
        #expect(once == "¿Qué hora es?")
        #expect(clean(once) == once)
        #expect(clean("¡Hola!") == "¡Hola!")
    }

    @Test("¿ lands after a leading vocative, not before it")
    func vocative() {
        #expect(clean("María, qué hora es?") == "María, ¿qué hora es?")
    }

    @Test("a question in a later sentence still gets both marks")
    func laterSentence() {
        #expect(clean("Llegué tarde. Qué opinas") == "Llegué tarde. ¿Qué opinas?")
    }

    // MARK: Spoken punctuation

    @Test("the unambiguous multi-word punctuation commands render")
    func spokenPunctuation() {
        #expect(clean("primera parte punto y coma segunda parte")
                == "Primera parte; segunda parte.")
        #expect(clean("llegué tarde punto y seguido no pasó nada")
                == "Llegué tarde. No pasó nada.")
        #expect(clean("primera idea punto y aparte segunda idea")
                == "Primera idea.\n\nSegunda idea.")
        #expect(clean("uno nueva línea dos") == "Uno\nDos.")
    }

    @Test("ambiguous punctuation nouns stay words")
    func ambiguousPunctuationWords() {
        #expect(clean("hay dos puntos importantes") == "Hay dos puntos importantes.")
        #expect(clean("no entiendo el punto de vista") == "No entiendo el punto de vista.")
    }

    @Test("a dictated quotation renders angular quotes")
    func angularQuotes() {
        #expect(clean("él dijo abrir comillas no vengo cerrar comillas")
                == "Él dijo «no vengo».")
    }

    // MARK: Spoken symbols

    @Test("spoken symbols build file names and identifiers")
    func symbols() {
        #expect(clean("abre main punto pi") == "Abre main.py")
        #expect(clean("cambia max guion bajo reintentos a cinco")
                == "Cambia max_reintentos a cinco.")
        #expect(clean("mándalo a juan punto perez arroba gmail punto com")
                == "Mándalo a juan.perez@gmail.com")
    }

    @Test("symbol words inside ordinary prose stay prose")
    func symbolProseGuards() {
        #expect(clean("el guion bajo del documento no aparece")
                == "El guion bajo del documento no aparece.")
        #expect(clean("un guion de cine muy bueno") == "Un guion de cine muy bueno.")
        #expect(clean("hasta cierto punto tienes razón") == "Hasta cierto punto tienes razón.")
    }

    // MARK: Typography

    @Test("RAE symbol spacing: 50 %, 20 €, 23 °C")
    func symbolSpacing() {
        #expect(clean("las ventas subieron un 20%") == "Las ventas subieron un 20 %.")
        #expect(clean("cuesta 30€") == "Cuesta 30 €.")
        #expect(clean("hacen 23°C") == "Hacen 23 °C.")
        // Idempotent: an already-spaced figure is untouched.
        #expect(clean("subió un 20 %") == "Subió un 20 %.")
    }

    @Test("numbers pass through exactly as dictated — both separators are valid")
    func numbersUntouched() {
        #expect(clean("el total es 1.234,56") == "El total es 1.234,56.")
        #expect(clean("pi es 3.14") == "Pi es 3.14")
        #expect(clean("subió 3,5 puntos") == "Subió 3,5 puntos.")
    }

    @Test("months, weekdays and language names lose an engine's capital")
    func lowercaseCommonNouns() {
        #expect(clean("nos vemos el Lunes") == "Nos vemos el lunes.")
        #expect(clean("la reunión es en Enero") == "La reunión es en enero.")
        #expect(clean("tradúcelo al Inglés") == "Tradúcelo al inglés.")
        // A festivity is a proper name: the following capital is the guard.
        #expect(clean("descansamos el Viernes Santo") == "Descansamos el Viernes Santo.")
        // A sentence-initial weekday keeps its capital.
        #expect(clean("Lunes es festivo") == "Lunes es festivo.")
    }

    // MARK: Embedded foreign text and terminal safety

    @Test("embedded English and identifiers survive untouched")
    func embeddedEnglish() {
        #expect(clean("revisa el pull request de main.py") == "Revisa el pull request de main.py")
        #expect(clean("usamos get_user_data en el backend")
                == "Usamos get_user_data en el backend.")
    }

    @Test("terminal category stays command-safe")
    func terminalCategory() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("npm run build guion guion verbose", category: .terminal)
                == "npm run build --verbose")
        #expect(clean("cd virgulilla barra proyectos", category: .terminal)
                == "cd ~/proyectos")
        // No ¿ ¡ and no period ever reach a command line.
        #expect(clean("qué hora es", category: .terminal) == "qué hora es")
    }

    @Test("a code editor keeps typographic spacing out and quotes straight")
    func codeEditorCategory() {
        // "50%" is a CSS length, not a figure needing RAE spacing.
        #expect(clean("width 50%", category: .codeEditor) == "Width 50%.")
        // A dictated quotation there is a string literal, so « » would be a
        // syntax error.
        #expect(clean("print abrir comillas hola cerrar comillas", category: .codeEditor)
                == "Print \"hola\".")
    }

    @Test("a mark glued to the preceding word is spaced off it")
    func openingMarkSpacing() {
        #expect(clean("hola¿qué tal?") == "Hola ¿qué tal?")
    }
}

@Suite("Cleanup polish — Spanish model output")
struct SpanishPolishTests {
    private func polish(_ text: String, category: AppCategory = .general) -> String {
        CleanupPolish.apply(text, options: .default,
                            context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                            locale: "es-ES")
    }

    @Test("the model's missing opening marks are restored")
    func openingMarks() {
        #expect(polish("Qué hora es?") == "¿Qué hora es?")
        #expect(polish("Hola! Cómo estás?") == "¡Hola! ¿Cómo estás?")
    }

    @Test("a dropped diacritic inside ¿…? is restored and capitalized")
    func diacritics() {
        #expect(polish("¿donde está la reunión?") == "¿Dónde está la reunión?")
        #expect(polish("¿cuando llegas?") == "¿Cuándo llegas?")
        // "¿Que te vas?" is a correct echo question — never "corrected".
        #expect(polish("¿Que te vas?") == "¿Que te vas?")
    }

    @Test("spoken punctuation the model left as words renders in polish too")
    func spokenPunctuationInPolish() {
        #expect(polish("Primera parte punto y coma segunda parte.")
                == "Primera parte; segunda parte.")
    }

    @Test("a URL query string is never mistaken for a question")
    func urlsUntouched() {
        let url = "Mira https://ejemplo.es/buscar?q=hola"
        #expect(polish(url) == url)
    }

    @Test("terminal output keeps every Spanish rule out")
    func terminalUntouched() {
        #expect(polish("git commit -m arreglar el login", category: .terminal)
                == "git commit -m arreglar el login")
    }
}
