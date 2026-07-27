import Foundation
import Testing
@testable import VoiceTypeKit

@Suite("Language pack — Slovenian policy")
struct SlovenianPackPolicyTests {
    @Test("only a non-lexical hesitation is a deterministic filler")
    func fillers() {
        let sl = LanguagePack.slovenian
        #expect(sl.fillers == ["eee"])
        for meaningful in ["hm", "mhm", "no", "pa", "torej", "mislim", "v bistvu"] {
            #expect(!sl.fillers.contains(meaningful))
        }
    }

    @Test("ambiguous punctuation words do not use the unconditional table")
    func punctuationPolicy() {
        let sl = LanguagePack.slovenian
        #expect(sl.spokenPunctuation.isEmpty)
        #expect(sl.symbols == nil)
        #expect(sl.rules.contains { $0.name == "render guarded Slovenian spoken symbols" })
    }

    @Test("prompt guidance is complete and examples stay disabled")
    func promptPolicy() {
        let prompt = LanguagePack.slovenian.prompt
        #expect(prompt.fillerExamples?.contains("\"eee\"") == true)
        #expect(prompt.capitalizationRule?.contains("weekdays") == true)
        #expect(prompt.codeRendering?.contains("main pika swift") == true)
        #expect(prompt.terminalGuidance?.contains("vezaj vezaj verbose") == true)
        #expect(prompt.codeEditorGuidance?.contains("code editor") == true)
        #expect(prompt.selfCorrectionRule?.contains("v petek, ne, v soboto") == true)
        #expect(prompt.addendum?.contains("decimal comma") == true)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Slovenian")
struct SlovenianRuleCleanupTests {
    private let nbsp = "\u{00A0}"

    private func clean(
        _ text: String,
        category: AppCategory = .general,
        options: CleanupOptions = .default
    ) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(category: category),
            locale: "sl-SI"
        )
    }

    @Test("pure filled pause is removed without eating punctuation")
    func filler() {
        #expect(clean("eee, danes končamo poročilo") == "Danes končamo poročilo.")
        #expect(clean("danes eee končamo poročilo") == "Danes končamo poročilo.")
    }

    @Test("meaningful filler lookalikes are retained")
    func ambiguousFillers() {
        #expect(clean("no pa začnimo") == "No pa začnimo.")
        #expect(clean("mislim da je prav") == "Mislim da je prav.")
        #expect(clean("mhm strinjam se") == "Mhm strinjam se.")
    }

    @Test("explicit interrogative openers gain a question mark")
    func questions() {
        #expect(clean("kdaj prideš") == "Kdaj prideš?")
        #expect(clean("ali lahko začneva") == "Ali lahko začneva?")
        #expect(clean("čigava je ta knjiga") == "Čigava je ta knjiga?")
    }

    @Test("ambiguous colloquial question particles never guess")
    func ambiguousQuestions() {
        #expect(clean("a zdaj greva") == "A zdaj greva.")
        #expect(clean("mar mi je za rezultat") == "Mar mi je za rezultat.")
    }

    @Test("decimal commas survive shared punctuation spacing")
    func decimalComma() {
        #expect(clean("vrednost je 3 , 14") == "Vrednost je 3,14.")
        #expect(clean("temperatura je 18,5 °C") == "Temperatura je 18,5\(nbsp)°C.")
    }

    @Test("abbreviation periods do not capitalize the following word")
    func abbreviations() {
        #expect(clean("to je npr. prvi primer") == "To je npr. prvi primer.")
        #expect(clean("gre za t. i. slepi preizkus") == "Gre za t. i. slepi preizkus.")
        #expect(clean("podjetje d. o. o. posluje normalno") == "Podjetje d. o. o. posluje normalno.")
    }

    @Test("ellipsis forms survive and remain idempotent")
    func ellipses() {
        #expect(clean("počakaj ... potem nadaljuj") == "Počakaj ... potem nadaljuj.")
        #expect(clean("morda …") == "Morda …")
        let once = clean("počakaj ... potem nadaljuj")
        #expect(clean(once) == once)
    }

    @Test("computer-set prose quotes use Slovenian guillemets")
    func quotationMarks() {
        #expect(clean(#"beseda "test" ostane nespremenjena"#)
            == "Beseda »test« ostane nespremenjena.")
        #expect(clean("beseda » test « ostane") == "Beseda »test« ostane.")
        let once = clean(#"beseda "test" ostane nespremenjena"#)
        #expect(clean(once) == once)
    }

    @Test("percent currency and temperature symbols take a non-breaking space")
    func measuredValues() {
        #expect(clean("rast je 5%") == "Rast je 5\(nbsp)%.")
        #expect(clean("cena je 20€") == "Cena je 20\(nbsp)€.")
        #expect(clean("zunaj je 18 ° C") == "Zunaj je 18\(nbsp)°C.")
    }

    @Test("anchored dates and times use Slovenian separators")
    func datesAndTimes() {
        #expect(clean("dobimo se ob 8:30") == "Dobimo se ob 8.30.")
        #expect(clean("podpisano dne 1.5.2026") == "Podpisano dne 1. 5. 2026.")
        #expect(clean("različica 1.5.2026 ostane taka") == "Različica 1.5.2026 ostane taka.")
    }

    @Test("guarded file identifier and email symbols render compactly")
    func codeSymbols() {
        #expect(clean("odpri main pika swift") == "Odpri main.swift")
        #expect(clean("nastavi uporabnik podčrtaj id") == "Nastavi uporabnik_id")
        #expect(clean("pošlji na ime pika priimek afna primer pika si")
            == "Pošlji na ime.priimek@primer.si")
    }

    @Test("spoken brackets render only from explicit phrases")
    func brackets() {
        #expect(clean("pokliči print odpri oklepaj x vejica y zapri oklepaj")
            == "Pokliči print(x, y)")
        #expect(clean("seznam odpri oglati oklepaj nič zapri oglati oklepaj")
            == "seznam[nič]")
        #expect(clean("blok odpri zaviti oklepaj x zapri zaviti oklepaj")
            == "blok{x}")
    }

    @Test("ordinary uses of symbol lookalikes stay prose")
    func proseSymbolGuards() {
        #expect(clean("to je pika na i") == "To je pika na i.")
        #expect(clean("podčrtaj pomembno besedo") == "Podčrtaj pomembno besedo.")
        #expect(clean("dodaj vejico peteršilja") == "Dodaj vejico peteršilja.")
    }

    @Test("embedded English and identifiers preserve spelling and casing")
    func embeddedTechnicalText() {
        #expect(clean("uporabljam VoiceType in datoteko APIClient.swift")
            == "Uporabljam VoiceType in datoteko APIClient.swift")
        #expect(clean("get_user ostane enak") == "get_user ostane enak.")
    }

    @Test("terminal rules render explicit flags and paths but add no prose repairs")
    func terminalSafety() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("git commit vezaj m popravi napako", category: .terminal)
            == "git commit -m popravi napako")
        #expect(clean("npm run build vezaj vezaj verbose", category: .terminal)
            == "npm run build --verbose")
        #expect(clean("cd tilda poševnica projekti poševnica voice", category: .terminal)
            == "cd ~/projekti/voice")
    }

    @Test("code editor keeps code punctuation free of prose typography")
    func codeEditorSafety() {
        #expect(clean(#"let value="test""#, category: .codeEditor) == #"Let value="test"."#)
        #expect(clean("tuple 1,2", category: .codeEditor) == "Tuple 1,2.")
    }
}

@Suite("Cleanup polish — Slovenian model output")
struct SlovenianPolishTests {
    @Test("mechanical Slovenian orthography also repairs model output")
    func modelRepair() {
        let out = CleanupPolish.apply(
            #"vrednost "pi" je 3 , 14"#,
            options: .default,
            locale: "sl-SI"
        )
        #expect(out == "Vrednost »pi« je 3,14")
    }

    @Test("Slovenian model lead-ins are stripped")
    func leadIn() {
        let out = CleanupSanitizer.strip(
            "Seveda, tukaj je očiščeno besedilo: Danes končamo.",
            pack: .slovenian
        )
        #expect(out == "Danes končamo.")
    }
}

@Suite("Cleanup prompt — Slovenian")
struct SlovenianPromptTests {
    @Test("guidance replaces English assumptions in every app category")
    func instructions() {
        let general = CleanupPrompt.instructions(for: .default, locale: "sl-SI")
        #expect(general.contains("The dictation is in Slovenian."))
        #expect(general.contains("non-lexical \"eee\""))
        #expect(general.contains("main pika swift"))
        #expect(general.contains("1. 5. 2026"))
        #expect(general.contains("the dual"))
        #expect(!general.contains("app dot pie"))

        let terminal = CleanupPrompt.instructions(
            for: .default,
            context: CleanupContext(category: .terminal),
            locale: "sl-SI"
        )
        #expect(terminal.contains("vezaj vezaj verbose"))
        #expect(terminal.contains("Do not translate or inflect"))
        #expect(!terminal.contains("dash dash verbose"))
    }
}
