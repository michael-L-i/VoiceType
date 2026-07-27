import Testing
import Foundation
@testable import VoiceTypeKit

/// Everything specific to the German pack. Lives beside the other per-language
/// suites so a contributor working on de touches exactly one source directory
/// and one test file — see docs/LOCALIZATION.md.
@Suite("Language pack — German policy")
struct GermanPackPolicyTests {
    @Test("only pure hesitation sounds are fillers; every modal particle is content")
    func fillers() {
        let de = LanguagePack.german
        #expect(de.fillers.contains("äh"))
        #expect(de.fillers.contains("ähm"))
        #expect(de.fillers.contains("mhm"))
        // Modal particles change the meaning or the attitude of a German
        // sentence. None of them may ever be removed blindly.
        for particle in ["doch", "ja", "mal", "halt", "eben", "denn", "wohl",
                         "schon", "bloß", "eh", "gell", "ne", "also"] {
            #expect(!de.fillers.contains(particle), "\(particle)")
        }
    }

    @Test("no unconditional spoken-punctuation table: Punkt and Komma are nouns")
    func noSpokenPunctuationTable() {
        // The flat table replaces without word boundaries or context, which is
        // right for Chinese 句号 and wrong for a German noun. German renders
        // its marks through `GermanRules.spokenPunctuation` instead.
        #expect(LanguagePack.german.spokenPunctuation.isEmpty)
    }

    @Test("German writes with Latin conventions and no standalone capital pronoun")
    func conventions() {
        let de = LanguagePack.german
        #expect(de.separatesWordsWithSpaces)
        #expect(!de.usesFullWidthPunctuation)
        #expect(!de.preservesFullWidthMarks)
        #expect(de.terminalPeriod == ".")
        #expect(de.questionMark == "?")
        // "ich" is lowercase in German — the English "I" rule must not apply.
        #expect(de.capitalizedStandalonePronoun == nil)
    }

    @Test("question openers include interrogatives and inverted finite verbs, never imperatives")
    func questionWords() {
        let de = LanguagePack.german
        for opener in ["warum", "wieso", "wofür", "hast", "kannst", "willst", "gibt"] {
            #expect(de.questionPrefixWords.contains(opener), "\(opener)")
        }
        // German imperatives are also clause-initial verbs; capitalizing them
        // with a "?" would be wrong.
        for imperative in ["mach", "geh", "komm", "sei", "gib", "zeig", "lass"] {
            #expect(!de.questionPrefixWords.contains(imperative), "\(imperative)")
        }
    }

    @Test("tag particles avoid word-final homographs, since hasSuffix isn't word-bounded")
    func tagParticles() {
        let de = LanguagePack.german
        #expect(de.questionSuffixParticles.contains("oder"))
        // "ne" would fire on "keine"/"Sonne"; "richtig" is a statement at least
        // as often as it is a tag.
        #expect(!de.questionSuffixParticles.contains("ne"))
        #expect(!de.questionSuffixParticles.contains("richtig"))
    }

    @Test("German names its own symbol words rather than inheriting English's")
    func spokenSymbolWords() {
        let de = LanguagePack.german
        #expect(de.spokenSymbolWords.contains("unterstrich"))
        #expect(de.spokenSymbolWords.contains("schrägstrich"))
        #expect(de.spokenSymbolWords != LanguagePack.defaultSpokenSymbolWords)
    }

    @Test("the spoken-symbol vocabulary is driven from a rule, not the pack field")
    func symbolsStayOutOfThePackField() {
        // `symbols` would also claim the paren path, and German says
        // "Klammer auf" — noun before direction — which it cannot express.
        #expect(LanguagePack.german.symbols == nil)
        #expect(SpokenSymbolVocabulary.german.dot == ["punkt"])
        #expect(SpokenSymbolVocabulary.german.parenNouns.isEmpty)
    }

    @Test("prompt guidance carries German's own substance, never English's")
    func promptGuidance() {
        let prompt = LanguagePack.german.prompt
        #expect(prompt.capitalizationRule?.contains("EVERY noun") == true)
        #expect(prompt.fillerExamples?.contains("\"äh\"") == true)
        #expect(prompt.codeRendering?.contains("Unterstrich") == true)
        #expect(prompt.terminalGuidance?.contains("Schrägstrich") == true)
        #expect(prompt.selfCorrectionRule?.contains("nein sechs") == true)
        // No few-shot pairs until a model-engine battery justifies them.
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — German")
struct GermanRuleCleanupTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(text, options: .default,
                                 context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                                 locale: "de-DE")
    }

    // MARK: Fillers

    @Test("hesitation sounds are removed wherever they occur")
    func fillers() {
        #expect(clean("ähm das ist ähm ganz gut") == "Das ist ganz gut.")
        #expect(clean("äh ich glaube schon") == "Ich glaube schon.")
    }

    @Test("modal particles survive the deterministic pass untouched")
    func modalParticlesKept() {
        #expect(clean("das ist halt doch ganz gut") == "Das ist halt doch ganz gut.")
        #expect(clean("das ist eh klar und halt so") == "Das ist eh klar und halt so.")
        #expect(clean("komm doch mal her") == "Komm doch mal her.")
    }

    // MARK: Spoken punctuation

    @Test("spoken mark names render, absorbing whatever the engine already punctuated")
    func spokenPunctuation() {
        #expect(clean("kommt er morgen Fragezeichen") == "Kommt er morgen?")
        #expect(clean("das ist super Ausrufezeichen") == "Das ist super!")
        #expect(clean("wir brauchen Doppelpunkt Kaffee und Tee")
            == "Wir brauchen: Kaffee und Tee.")
    }

    @Test("spoken punctuation is idempotent when the engine already rendered the mark")
    func spokenPunctuationIdempotent() {
        #expect(clean("kommt er morgen? Fragezeichen") == "Kommt er morgen?")
        #expect(clean("kommt er morgen, Fragezeichen") == "Kommt er morgen?")
    }

    @Test("brackets render in the German word order, noun before direction")
    func spokenBrackets() {
        #expect(clean("das Ergebnis Klammer auf ungefähr Klammer zu ist gut")
            == "Das Ergebnis (ungefähr) ist gut.")
        #expect(clean("nimm eckige Klammer auf drei eckige Klammer zu")
            == "Nimm [drei]")
    }

    @Test("Punkt and Komma stay nouns in ordinary prose")
    func ambiguousNounsKept() {
        #expect(clean("das bringt es auf den Punkt") == "Das bringt es auf den Punkt.")
        #expect(clean("Punkt zwölf gehen wir los") == "Punkt zwölf gehen wir los.")
        #expect(clean("setz da bitte ein Komma") == "Setz da bitte ein Komma.")
        #expect(clean("ein Strich durch die Rechnung") == "Ein Strich durch die Rechnung.")
        #expect(clean("ich will das unterstreichen") == "Ich will das unterstreichen.")
    }

    // MARK: Numbers, units, currency

    @Test("decimals use a comma and survive the shared spacing pass")
    func decimals() {
        #expect(clean("pi ist ungefähr 3 Komma 14") == "Pi ist ungefähr 3,14.")
        #expect(clean("wir haben 5 Komma 5 Prozent mehr Umsatz")
            == "Wir haben 5,5 Prozent mehr Umsatz.")
        // The transcriber already got it right: it must not be split apart.
        #expect(clean("das kostet 12,50 Euro") == "Das kostet 12,50 Euro.")
    }

    @Test("a number and its unit sign are separated; the currency sign follows the amount")
    func unitsAndCurrency() {
        #expect(clean("die Auslastung liegt bei 80%") == "Die Auslastung liegt bei 80 %.")
        #expect(clean("das kostet €12,50") == "Das kostet 12,50 €.")
        #expect(clean("draußen sind 20°C") == "Draußen sind 20 °C.")
    }

    // MARK: Abbreviations and capitalization

    @Test("multi-part abbreviations get their space and their casing back")
    func abbreviations() {
        #expect(clean("wir brauchen z.b. mehr Zeit") == "Wir brauchen z. B. mehr Zeit.")
        #expect(clean("das heißt d.h. wir warten") == "Das heißt d. h. wir warten.")
        #expect(clean("das gilt i.d.r. nicht") == "Das gilt i. d. R. nicht.")
    }

    @Test("an abbreviation no longer forces a capital onto a following function word")
    func noFalseCapitalAfterAbbreviation() {
        #expect(clean("ca. mehr als die Hälfte") == "Ca. mehr als die Hälfte.")
        #expect(clean("wir warten bzw. wir gehen") == "Wir warten bzw. wir gehen.")
        // A noun after the abbreviation is capitalized in German and stays so.
        #expect(clean("z.b. Autos sind teuer") == "Z. B. Autos sind teuer.")
        // "usw." routinely ends a sentence, so it is deliberately not in the
        // list: the next sentence keeps its capital.
        #expect(clean("Äpfel Birnen usw. Der Rest kommt später")
            == "Äpfel Birnen usw. Der Rest kommt später.")
    }

    @Test("weekdays and months are capitalized; their derived adverbs are not")
    func closedClassCapitals() {
        #expect(clean("wir treffen uns am montag") == "Wir treffen uns am Montag.")
        #expect(clean("der Urlaub beginnt im august") == "Der Urlaub beginnt im August.")
        // "montags" is an adverb — lowercase mid-sentence.
        #expect(clean("wir haben montags immer frei") == "Wir haben montags immer frei.")
        // …and a file name is not a weekday.
        #expect(clean("die Datei heißt montag.md") == "Die Datei heißt montag.md")
    }

    @Test("a bare day before a month name becomes an ordinal")
    func ordinalDates() {
        #expect(clean("der Termin ist am 5 mai") == "Der Termin ist am 5. Mai.")
        // Idempotent, and a year is never an ordinal.
        #expect(clean("der Termin ist am 5. Mai") == "Der Termin ist am 5. Mai.")
    }

    // MARK: Typography

    @Test("German quotation marks, apostrophe and Gedankenstrich")
    func typography() {
        #expect(clean("er sagte \"das passt schon\"") == "Er sagte „das passt schon“.")
        #expect(clean("mal sehen wie's läuft") == "Mal sehen wie’s läuft.")
        #expect(clean("das war — ehrlich gesagt — zu spät")
            == "Das war – ehrlich gesagt – zu spät.")
    }

    @Test("dictated line breaks fire as commands but not as noun phrases")
    func lineBreaks() {
        #expect(clean("erste Zeile neue Zeile zweite Zeile") == "Erste Zeile\nZweite Zeile.")
        #expect(clean("schreib weiter neuer Absatz das war es")
            == "Schreib weiter\n\nDas war es.")
        // A determiner in front means it is an ordinary noun phrase.
        #expect(clean("ich brauche eine neue Zeile im Dokument")
            == "Ich brauche eine neue Zeile im Dokument.")
    }

    // MARK: Questions and terminal punctuation

    @Test("inverted verbs and interrogatives gain a question mark")
    func questions() {
        #expect(clean("hast du das schon gemacht") == "Hast du das schon gemacht?")
        #expect(clean("wann fängt die Besprechung an") == "Wann fängt die Besprechung an?")
        #expect(clean("wir machen das so oder") == "Wir machen das so oder?")
        #expect(clean("das machen wir morgen") == "Das machen wir morgen.")
    }

    // MARK: Code, identifiers, terminal

    @Test("spoken identifiers and file names render; the surrounding prose does not")
    func spokenSymbols() {
        #expect(clean("schick mir bitte haupt Punkt py") == "Schick mir bitte haupt.py")
        #expect(clean("max Unterstrich retries auf zehn setzen")
            == "max_retries auf zehn setzen.")
        #expect(clean("schreib an hans Punkt meier at firma Punkt de")
            == "Schreib an hans.meier@firma.de")
    }

    @Test("embedded English technical vocabulary survives untouched")
    func embeddedEnglish() {
        #expect(clean("ich habe den Pull Request gemerged")
            == "Ich habe den Pull Request gemerged.")
        #expect(clean("die Version ist 2.14 und läuft seit Januar")
            == "Die Version ist 2.14 und läuft seit Januar.")
    }

    @Test("terminal category stays command-safe: no capital, no period, no typography")
    func terminalCategory() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("git push Strich Strich force", category: .terminal)
            == "git push --force")
        #expect(clean("cd tilde Schrägstrich code Schrägstrich voicetype", category: .terminal)
            == "cd ~/code/voicetype")
        // No quotation-mark or apostrophe rewriting inside a shell command.
        #expect(clean("echo \"hallo welt\"", category: .terminal) == "echo \"hallo welt\"")
    }

    @Test("the code editor keeps quotes, percent signs and bare identifiers as code")
    func codeEditorCategory() {
        #expect(clean("print \"hallo\"", category: .codeEditor) == "Print \"hallo\".")
        #expect(clean("wenn x 50% ist", category: .codeEditor) == "Wenn x 50% ist.")
        #expect(clean("die Variable montag zählt", category: .codeEditor)
            == "Die Variable montag zählt.")
    }

    @Test("cleanup is idempotent — running clean output through again changes nothing")
    func idempotence() {
        for text in ["Wir treffen uns am Montag.",
                     "Das kostet 12,50 €.",
                     "Wir brauchen z. B. mehr Zeit.",
                     "Er sagte „das passt schon“.",
                     "Das war – ehrlich gesagt – zu spät.",
                     "Der Termin ist am 5. Mai.",
                     "Hast du das schon gemacht?"] {
            #expect(clean(text) == text, "\(text)")
        }
    }
}

@Suite("Cleanup polish — German model output")
struct GermanPolishTests {
    private func polish(_ text: String, category: AppCategory = .general) -> String {
        CleanupPolish.apply(text, options: .default,
                            context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                            locale: "de-DE")
    }

    @Test("the pack's orthography holds on model output too")
    func rulesRunInBothPaths() {
        #expect(polish("das war — kurz gesagt — zu spät")
            == "Das war – kurz gesagt – zu spät")
        #expect(polish("er sagte \"das passt\"") == "Er sagte „das passt“")
        #expect(polish("wir brauchen z.b. mehr Zeit") == "Wir brauchen z. B. mehr Zeit")
    }

    @Test("an unpunctuated inverted question gains a German question mark")
    func questionMark() {
        #expect(polish("hast du das schon gemacht") == "Hast du das schon gemacht?")
    }

    @Test("full-width marks the model drifts into are repaired to ASCII")
    func foreignPunctuationRepaired() {
        #expect(polish("Alles klar！").contains("!"))
    }

    @Test("terminal output is left alone")
    func terminalUntouched() {
        #expect(polish("git status", category: .terminal) == "git status")
    }
}
