import Foundation
import Testing
@testable import VoiceTypeKit

@Suite("Language pack — Estonian policy")
struct EstonianPackPolicyTests {
    @Test("only the unlexicalized hesitation is a deterministic filler")
    func fillerPolicy() {
        let et = LanguagePack.estonian
        #expect(et.fillers == ["õõ"])
        for meaningful in ["aa", "ää", "ee", "öö", "mm", "noh", "nagu", "siis", "see"] {
            #expect(!et.fillers.contains(meaningful))
        }
    }

    @Test("bare punctuation nouns stay out of unconditional replacement")
    func punctuationPolicy() {
        #expect(LanguagePack.estonian.spokenPunctuation.isEmpty)
        #expect(LanguagePack.estonian.symbols == nil)
        #expect(LanguagePack.estonian.spokenSymbolWords.contains("alakriips"))
        #expect(LanguagePack.estonian.spokenSymbolWords.contains("punkt"))
    }

    @Test("prompt owns every Estonian-specific guidance section without few-shot leakage")
    func promptPolicy() {
        let prompt = LanguagePack.estonian.prompt
        #expect(prompt.fillerExamples?.contains("õõ") == true)
        #expect(prompt.capitalizationRule?.contains("weekdays") == true)
        #expect(prompt.codeRendering?.contains("main punkt py") == true)
        #expect(prompt.terminalGuidance?.contains("kriips kriips verbose") == true)
        #expect(prompt.codeEditorGuidance != nil)
        #expect(prompt.selfCorrectionRule?.contains("kolmapäeval") == true)
        #expect(prompt.addendum?.contains("24.01.2017") == true)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Estonian")
struct EstonianRuleCleanupTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(
            text,
            options: .default,
            context: CleanupContext(category: category),
            locale: "et-EE")
    }

    @Test("õõ is removed without disturbing its sentence")
    func fillerRemoval() {
        #expect(clean("õõ ma tulen homme") == "Ma tulen homme.")
        #expect(clean("me õõ kohtume homme") == "Me kohtume homme.")
    }

    @Test("meaningful filler lookalikes are retained")
    func ambiguousFillersStay() {
        let out = clean("öö oli vaikne ja noh see oli hea")
        #expect(out == "Öö oli vaikne ja noh see oli hea.")
    }

    @Test("explicit punctuation commands render, while bare nouns stay prose")
    func explicitPunctuation() {
        #expect(clean("tere kirjuta koma kuidas läheb kirjuta küsimärk")
            == "Tere, kuidas läheb?")
        #expect(clean("punkt ja koma on kirjavahemärgid")
            == "Punkt ja koma on kirjavahemärgid.")
    }

    @Test("explicit punctuation rendering is idempotent")
    func punctuationIdempotence() {
        let once = clean("tere kirjavahemärk koma Mari")
        #expect(once == "Tere, Mari.")
        #expect(clean(once) == once)
    }

    @Test("kas questions are marked sentence by sentence")
    func questions() {
        #expect(clean("kas sa tuled homme") == "Kas sa tuled homme?")
        #expect(clean("homme on koosolek. kas sa saad tulla")
            == "Homme on koosolek. Kas sa saad tulla?")
        #expect(clean("kas see sobib. järgmine lause jääb väiteks")
            == "Kas see sobib? Järgmine lause jääb väiteks.")
    }

    @Test("decimal commas survive shared punctuation spacing")
    func decimalComma() {
        #expect(clean("hind on 3,50€") == "Hind on 3,50 €.")
        #expect(clean("tulemus oli 12,75 protsenti") == "Tulemus oli 12,75 protsenti.")
    }

    @Test("percent, euro, and Celsius spacing follows Estonian typography")
    func units() {
        #expect(clean("kasv oli 9 % ja hind 10 €") == "Kasv oli 9% ja hind 10 €.")
        #expect(clean("väljas on 20° c") == "Väljas on 20 °C.")
    }

    @Test("a numeric day does not falsely capitalize a following month")
    func dateCapitalization() {
        #expect(clean("kohtume 24. detsembril kell 10.30")
            == "Kohtume 24. detsembril kell 10.30.")
        #expect(clean("tähtaeg on 07.07.2027") == "Tähtaeg on 07.07.2027.")
    }

    @Test("prose quotes use Estonian marks and tight inner spacing")
    func quotationMarks() {
        #expect(clean(#"ta ütles " tere tulemast ""#)
            == "Ta ütles „tere tulemast“.")
        #expect(clean("ta nimetas seda “heaks plaaniks”")
            == "Ta nimetas seda „heaks plaaniks“.")
    }

    @Test("prose ellipses become one typographic mark")
    func ellipsis() {
        #expect(clean("ma ei tea... võib-olla homme") == "Ma ei tea… võib-olla homme.")
    }

    @Test("spoken file extensions and identifiers render conservatively")
    func technicalSymbols() {
        #expect(clean("ava main punkt py") == "Ava main.py")
        #expect(clean("muutuja on kasutaja alakriips id")
            == "Muutuja on kasutaja_id")
        #expect(clean("saada aadressile mari punkt tamm ätt gmail punkt com")
            == "Saada aadressile mari.tamm@gmail.com")
    }

    @Test("existing English brands, file names, and identifiers survive")
    func embeddedTechnicalText() {
        #expect(clean("VoiceType avab faili config.json")
            == "VoiceType avab faili config.json")
        #expect(clean("muutuja request_id jääb samaks")
            == "Muutuja request_id jääb samaks.")
    }

    @Test("code editor keeps literal spread syntax and straight code quotes")
    func codeEditorSafety() {
        #expect(clean(#"const args = "...args""#, category: .codeEditor)
            == #"Const args = "...args"."#)
    }

    @Test("terminal flags, paths, decimals, and casing stay command-safe")
    func terminalSafety() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("git log kriips kriips oneline", category: .terminal)
            == "git log --oneline")
        #expect(clean("cd tilde kaldkriips projektid kaldkriips VoiceType",
                      category: .terminal)
            == "cd ~/projektid/VoiceType")
        #expect(clean("echo 3,14", category: .terminal) == "echo 3,14")
    }
}

@Suite("Cleanup polish — Estonian model output")
struct EstonianPolishTests {
    @Test("model output receives Estonian number and quote repair")
    func orthographicRepair() {
        let out = CleanupPolish.apply(
            #"hind on 3,50€ ja nimi on "proov""#,
            options: .default,
            locale: "et-EE")
        #expect(out == "Hind on 3,50 € ja nimi on „proov“")
    }

    @Test("Estonian model lead-ins are stripped")
    func leadInRemoval() {
        #expect(CleanupSanitizer.strip(
            "Muidugi! Siin on parandatud tekst: Tere tulemast.",
            locale: "et-EE") == "Tere tulemast.")
    }
}
