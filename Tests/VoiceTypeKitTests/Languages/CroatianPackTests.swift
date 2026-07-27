import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Language pack — Croatian policy")
struct CroatianPackPolicyTests {
    @Test("only non-lexical sounds are deterministic fillers")
    func fillerPolicy() {
        let hr = LanguagePack.croatian
        #expect(hr.fillers.contains("eee"))
        #expect(hr.fillers.contains("hmm"))
        #expect(!hr.fillers.contains("ovaj"))
        #expect(!hr.fillers.contains("ono"))
        #expect(!hr.fillers.contains("znači"))
        #expect(!hr.fillers.contains("pa"))
        #expect(!hr.fillers.contains("zapravo"))
    }

    @Test("ambiguous točka is not a flat punctuation command")
    func punctuationPolicy() {
        let hr = LanguagePack.croatian
        #expect(hr.spokenPunctuation.isEmpty)
        #expect(hr.symbols == nil)
        #expect(hr.capitalizedStandalonePronoun == nil)
    }

    @Test("Croatian prompt supplies every language-specific section without few-shot leakage")
    func promptPolicy() {
        let prompt = LanguagePack.croatian.prompt
        #expect(prompt.fillerExamples?.contains("ovaj") == true)
        #expect(prompt.capitalizationRule?.contains("srpanj") == true)
        #expect(prompt.codeRendering?.contains("main točka pi") == true)
        #expect(prompt.terminalGuidance?.contains("--verbose") == true)
        #expect(prompt.codeEditorGuidance?.contains("identifier") == true)
        #expect(prompt.selfCorrectionRule?.contains("u subotu") == true)
        #expect(prompt.addendum?.contains("je li") == true)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Croatian")
struct CroatianRuleCleanupTests {
    private func clean(_ text: String,
                       category: AppCategory = .general,
                       options: CleanupOptions = .default) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(appBundleID: nil, appName: nil, category: category),
            locale: "hr-HR")
    }

    @Test("vocal hesitations are removed without touching lexical lookalikes")
    func fillers() {
        #expect(clean("Eee danas šaljemo novu verziju") == "Danas šaljemo novu verziju.")
        #expect(clean("Ovaj prijedlog znači velik napredak") ==
                "Ovaj prijedlog znači velik napredak.")
        #expect(clean("Pa ovaj dokument ostaje ovdje") ==
                "Pa ovaj dokument ostaje ovdje.")
    }

    @Test("specialized spoken punctuation commands render and are idempotent")
    func spokenPunctuation() {
        #expect(clean("Prvo zarez drugo uskličnik") == "Prvo, drugo!")
        #expect(clean("Je li gotovo upitnik") == "Je li gotovo?")
        #expect(clean("Dobro? upitnik") == "Dobro?")
        #expect(clean("Jedno dvotočka dva") == "Jedno: dva.")
        #expect(clean("Prvo točka sa zarezom drugo") == "Prvo; drugo.")
    }

    @Test("dictated line and paragraph breaks survive the shared whitespace pass")
    func lineBreaks() {
        #expect(clean("Prvi red novi redak drugi red") == "Prvi red\ndrugi red.")
        #expect(clean("Prvi odlomak novi odlomak drugi odlomak") ==
                "Prvi odlomak\n\ndrugi odlomak.")
    }

    @Test("ambiguous točka remains prose but joins a known file extension")
    func contextualDot() {
        #expect(clean("Ovo je ključna točka projekta") == "Ovo je ključna točka projekta.")
        #expect(clean("Otvori main točka pi") == "Otvori main.py")
        #expect(clean("Pošalji config točka json danas") == "Pošalji config.json danas.")
    }

    @Test("Croatian multi-word symbol names compact identifiers and brackets")
    func identifiersAndBrackets() {
        #expect(clean("Promijeni max donja crta retries") == "Promijeni max_retries")
        #expect(clean("Pozovi print otvori oblu zagradu x zarez y zatvori oblu zagradu") ==
                "Pozovi print(x, y)")
    }

    @Test("decimal comma is never split by generic punctuation spacing")
    func decimalComma() {
        #expect(clean("Cijena je 12,50 eura") == "Cijena je 12,50 eura.")
        #expect(clean("Rast je 3,14 puta veći") == "Rast je 3,14 puta veći.")
    }

    @Test("percent, promille and euro signs receive Croatian spacing")
    func units() {
        #expect(clean("Rast je 12,5%") == "Rast je 12,5 %.")
        #expect(clean("Udio je 3‰") == "Udio je 3 ‰.")
        #expect(clean("Cijena je 99,90€") == "Cijena je 99,90 €.")
    }

    @Test("plausible numeric dates receive ordinal dots and spaces")
    func dates() {
        #expect(clean("Sastanak je 24.12.2026. u podne") ==
                "Sastanak je 24. 12. 2026. u podne.")
        #expect(clean("Rok je 1.2.2027") == "Rok je 1. 2. 2027.")
        #expect(clean("Verzija release-1.2.2027 ostaje ista") ==
                "Verzija release-1.2.2027 ostaje ista.")
    }

    @Test("Croatian quotation marks attach correctly")
    func quotationMarks() {
        #expect(clean("Rekao je “dolazim sutra”") == "Rekao je „dolazim sutra”.")
        #expect(clean("Rekao je navodnik za početak citata dolazim navodnik za kraj citata") ==
                "Rekao je „dolazim”.")
    }

    @Test("common abbreviation periods do not trigger false sentence capitalization")
    func abbreviations() {
        #expect(clean("Npr. danas šaljemo paket") == "Npr. danas šaljemo paket.")
        #expect(clean("Dr. Horvat dolazi danas") == "Dr. Horvat dolazi danas.")
        #expect(clean("Pogledaj str. 12 dokumenta") == "Pogledaj str. 12 dokumenta.")
    }

    @Test("direct interrogatives and the auxiliary plus li frame gain a question mark")
    func questions() {
        #expect(clean("Gdje je sastanak") == "Gdje je sastanak?")
        #expect(clean("Je li sastanak potvrđen") == "Je li sastanak potvrđen?")
        #expect(clean("Možete li poslati datoteku") == "Možete li poslati datoteku?")
        #expect(clean("Prvo provjeri status. Je li servis dostupan.") ==
                "Prvo provjeri status. Je li servis dostupan?")
    }

    @Test("declarative lookalikes do not gain a question mark")
    func declarativeQuestionLookalikes() {
        #expect(clean("Što se mene tiče sve je spremno") ==
                "Što se mene tiče sve je spremno.")
        #expect(clean("Kako bilo nastavljamo sutra") == "Kako bilo nastavljamo sutra.")
        #expect(clean("Je li došao, ne znam") == "Je li došao, ne znam.")
    }

    @Test("embedded English, paths and identifiers survive untouched")
    func embeddedTechnicalText() {
        #expect(clean("VoiceType koristi main.swift i get_user") ==
                "VoiceType koristi main.swift i get_user")
        #expect(clean("Datoteka APIClient.swift ostaje ista") ==
                "Datoteka APIClient.swift ostaje ista.")
    }

    @Test("terminal rendering is useful but command-safe")
    func terminal() {
        #expect(clean("git status crtica crtica short", category: .terminal) ==
                "git status --short")
        #expect(clean("cd tilda kosa crta projekti kosa crta VoiceType",
                      category: .terminal) == "cd ~/projekti/VoiceType")
        #expect(clean("echo 12,50", category: .terminal) == "echo 12,50")
        #expect(clean("echo zarez", category: .terminal) == "echo zarez")
    }

    @Test("disabled punctuation and capitalization options stay disabled")
    func optionsRespected() {
        let options = CleanupOptions(
            removeFillers: false,
            addPunctuation: false,
            fixCapitalization: false)
        #expect(clean("eee gdje je sastanak", options: options) == "eee gdje je sastanak")
    }
}

@Suite("Cleanup polish — Croatian model output")
struct CroatianPolishTests {
    @Test("model output receives Croatian mechanical repairs too")
    func repairs() {
        let options = CleanupOptions.default
        #expect(CleanupPolish.apply("cijena je 12,50€", options: options,
                                    locale: "hr-HR") == "Cijena je 12,50 €")
        #expect(CleanupPolish.apply("otvori main točka pi", options: options,
                                    locale: "hr-HR") == "Otvori main.py")
        #expect(CleanupPolish.apply("rekao je “dolazim”", options: options,
                                    locale: "hr-HR") == "Rekao je „dolazim”")
        #expect(CleanupPolish.apply("je li gotovo.", options: options,
                                    locale: "hr-HR") == "Je li gotovo?")
    }

    @Test("Croatian model lead-ins are stripped")
    func leadIn() {
        #expect(CleanupSanitizer.strip(
            "Evo očišćenog teksta: Sastanak je sutra.",
            locale: "hr-HR") == "Sastanak je sutra.")
    }
}
