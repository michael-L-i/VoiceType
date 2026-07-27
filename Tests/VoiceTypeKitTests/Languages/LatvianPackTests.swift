import Foundation
import Testing
@testable import VoiceTypeKit

@Suite("Language pack — Latvian policy")
struct LatvianPackPolicyTests {
    @Test("only non-lexical elongated hesitations are deterministic fillers")
    func conservativeFillers() {
        let lv = LanguagePack.latvian
        #expect(lv.fillers.contains("ēē"))
        #expect(lv.fillers.contains("emm"))
        #expect(!lv.fillers.contains("ē"))
        #expect(!lv.fillers.contains("em"))
        #expect(!lv.fillers.contains("nu"))
        #expect(!lv.fillers.contains("tā"))
        #expect(!lv.fillers.contains("respektīvi"))
    }

    @Test("spoken symbols are supplied through Latvian-owned rules")
    func contextualSymbols() {
        let lv = LanguagePack.latvian
        #expect(lv.symbols == nil)
        #expect(lv.spokenPunctuation.isEmpty)
        #expect(lv.rules.contains { $0.name == "render contextual Latvian tech symbols" })
        #expect(lv.spokenSymbolWords.contains("punkts"))
        #expect(lv.stopwords.contains("un"))
    }

    @Test("prompt guidance is complete without risky few-shot examples")
    func promptGuidance() {
        let prompt = LanguagePack.latvian.prompt
        #expect(prompt.fillerExamples?.contains("\"nu\"") == true)
        #expect(prompt.capitalizationRule?.contains("month names") == true)
        #expect(prompt.codeRendering?.contains("config punkts json") == true)
        #expect(prompt.terminalGuidance?.contains("defise defise verbose") == true)
        #expect(prompt.codeEditorGuidance != nil)
        #expect(prompt.selfCorrectionRule?.contains("piecas, nē, sešas") == true)
        #expect(prompt.addendum?.contains("decimal comma") == true)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Latvian")
struct LatvianRuleCleanupTests {
    private func clean(
        _ text: String,
        category: AppCategory = .general,
        options: CleanupOptions = .default
    ) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(category: category),
            locale: "lv-LV")
    }

    @Test("elongated hesitation sounds are removed")
    func fillers() {
        #expect(clean("ēē, šodien pabeigsim darbu") == "Šodien pabeigsim darbu.")
        #expect(clean("mēs emm turpināsim rīt") == "Mēs turpināsim rīt.")
    }

    @Test("meaningful filler lookalikes are retained")
    func ambiguousFillersStay() {
        #expect(clean("nu tā mēs turpināsim") == "Nu tā mēs turpināsim.")
        #expect(clean("tā kā līst paliksim mājās") == "Tā kā līst paliksim mājās.")
        #expect(clean("tas ir respektīvi otrais variants")
            == "Tas ir respektīvi otrais variants.")
    }

    @Test("unambiguous spoken punctuation renders and spaces correctly")
    func spokenPunctuation() {
        #expect(clean("pirmais komats otrais") == "Pirmais, otrais.")
        #expect(clean("virsraksts kols ievads") == "Virsraksts: ievads.")
        #expect(clean("vai tu nāksi jautājuma zīme") == "Vai tu nāksi?")
        #expect(clean("viņš teica atverošās pēdiņas labrīt aizverošās pēdiņas")
            == "Viņš teica „labrīt”.")
    }

    @Test("spoken punctuation is idempotent when ASR emitted the mark too")
    func spokenPunctuationIdempotent() {
        #expect(clean("labi, komats turpinām") == "Labi, turpinām.")
        #expect(clean("vai tu nāksi jautājuma zīme?")
            == "Vai tu nāksi?")
    }

    @Test("interrogative openers gain a question mark")
    func questionHeuristic() {
        #expect(clean("vai tu nāksi") == "Vai tu nāksi?")
        #expect(clean("kāpēc vilciens kavējas") == "Kāpēc vilciens kavējas?")
        #expect(clean("kur ir mana atslēga") == "Kur ir mana atslēga?")
    }

    @Test("decimal commas and ellipses survive shared punctuation cleanup")
    func decimalAndEllipsis() {
        #expect(clean("cena ir 12,50 eiro") == "Cena ir 12,50 eiro.")
        #expect(clean("es vēl domāju...") == "Es vēl domāju...")
    }

    @Test("straight and foreign smart quote pairs become Latvian quotes")
    func quotationMarks() {
        #expect(clean(#"viņš teica "labrīt""#) == "Viņš teica „labrīt”.")
        #expect(clean("nosaukums ir “Baltais kuģis”")
            == "Nosaukums ir „Baltais kuģis”.")
    }

    @Test("worded dates and clock times receive required non-breaking spaces")
    func datesAndTimes() {
        #expect(clean("tikšanās ir 2026.gada 26.jūlijā plkst.18.00.")
            == "Tikšanās ir 2026.\u{00A0}gada 26.\u{00A0}jūlijā plkst.\u{00A0}18.00.")
        #expect(clean("atbilde jāsniedz 2027.gadā")
            == "Atbilde jāsniedz 2027.\u{00A0}gadā.")
    }

    @Test("currency and percent designators follow Latvian order and spacing")
    func currencyAndPercent() {
        #expect(clean("budžets ir EUR 1 250,50 un pieaugums 10%")
            == "Budžets ir 1 250,50\u{00A0}EUR un pieaugums 10\u{00A0}%.")
        #expect(clean("biļete maksā €25")
            == "Biļete maksā 25\u{00A0}€.")
    }

    @Test("multi-part abbreviations use protected spaces without false capitalization")
    func abbreviations() {
        #expect(clean("tas ir t.i. vienkāršs piemērs")
            == "Tas ir t.\u{00A0}i. vienkāršs piemērs.")
        #expect(clean("vajag maizi u.c. produktus")
            == "Vajag maizi u.\u{00A0}c. produktus.")
    }

    @Test("file names, identifiers, and embedded English survive untouched")
    func embeddedTechnicalText() {
        #expect(clean("atver config.json un pārbaudi timeout")
            == "Atver config.json un pārbaudi timeout.")
        #expect(clean("main_test") == "main_test")
        #expect(clean("VoiceType izmanto Swift")
            == "VoiceType izmanto Swift.")
    }

    @Test("contextual Latvian symbol words render only in technical shapes")
    func techSymbols() {
        #expect(clean("atver config punkts json") == "Atver config.json")
        #expect(clean("main pasvītra test") == "main_test")
        #expect(clean("tas ir svarīgs punkts") == "Tas ir svarīgs punkts.")
        #expect(clean("janis punkts berzins et example punkts lv")
            == "janis.berzins@example.lv")
    }

    @Test("terminal rendering creates flags and paths without prose typography")
    func terminalSafety() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("git defise defise verbose", category: .terminal)
            == "git --verbose")
        #expect(clean("cd tilde slīpsvītra projekti slīpsvītra VoiceType",
                      category: .terminal)
            == "cd ~/projekti/VoiceType")
        #expect(clean("echo 12,50", category: .terminal) == "echo 12,50")
    }
}

@Suite("Cleanup polish — Latvian model output")
struct LatvianPolishTests {
    @Test("mechanical Latvian typography repairs model output too")
    func typography() {
        #expect(CleanupPolish.apply(
            #"cena ir 12,50 EUR un viņš teica "labi""#,
            options: .default,
            locale: "lv-LV")
            == "Cena ir 12,50\u{00A0}EUR un viņš teica „labi”")
    }

    @Test("spoken punctuation and contextual tech symbols repair model output")
    func spokenRendering() {
        #expect(CleanupPolish.apply(
            "atver config punkts json komats tad turpini",
            options: .default,
            locale: "lv-LV")
            == "Atver config.json, tad turpini")
    }

    @Test("Latvian conversational model preamble is removed")
    func sanitizerLeadIn() {
        let wrapped = "Protams, lūk, attīrītais teksts: Šodien strādājam."
        #expect(CleanupSanitizer.strip(wrapped, locale: "lv-LV")
            == "Šodien strādājam.")
    }
}
