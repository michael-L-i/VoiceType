import Foundation
import Testing
@testable import VoiceTypeKit

@Suite("Language pack — Slovak policy")
struct SlovakPackPolicyTests {
    @Test("only never-content hesitation spellings are deterministic fillers")
    func fillerPolicy() {
        let sk = LanguagePack.slovak
        #expect(sk.fillers == ["ehm", "éé", "ééé", "éééé"])
        for meaningful in ["hm", "mhm", "no", "teda", "vlastne", "proste", "akože", "oné", "tento"] {
            #expect(!sk.fillers.contains(meaningful), "\(meaningful) must stay contextual")
        }
    }

    @Test("lexical punctuation nouns are not unconditional replacements")
    func spokenPunctuationPolicy() {
        let sk = LanguagePack.slovak
        #expect(sk.spokenPunctuation.isEmpty)
        #expect(sk.symbols == nil)
        #expect(sk.spokenSymbolWords.contains("podčiarkovník"))
        #expect(sk.spokenSymbolWords.contains("zavináč"))
    }

    @Test("the Slovak prompt fills every language-specific guidance field without few-shot leakage")
    func promptPolicy() {
        let prompt = LanguagePack.slovak.prompt
        #expect(prompt.fillerExamples?.contains("ehm") == true)
        #expect(prompt.capitalizationRule?.contains("weekdays") == true)
        #expect(prompt.codeRendering?.contains("podčiarkovník") == true)
        #expect(prompt.terminalGuidance?.contains("--verbose") == true)
        #expect(prompt.codeEditorGuidance?.contains("snake case") == true)
        #expect(prompt.selfCorrectionRule?.contains("šesť položiek") == true)
        #expect(prompt.addendum?.contains("3,14") == true)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Slovak")
struct SlovakRuleCleanupTests {
    private let fixedSpace = "\u{00A0}"

    private func clean(
        _ text: String,
        category: AppCategory = .general,
        options: CleanupOptions = .default
    ) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(appBundleID: nil, appName: nil, category: category),
            locale: "sk-SK")
    }

    @Test("pure hesitation spellings are removed cleanly")
    func fillers() {
        #expect(clean("ehm dnes prídem") == "Dnes prídem.")
        #expect(clean("dnes ééé prídem neskôr") == "Dnes prídem neskôr.")
    }

    @Test("meaningful filler lookalikes always survive the deterministic floor")
    func ambiguousFillersStay() {
        let out = clean("no teda vlastne proste tento návrh platí")
        #expect(out == "No teda vlastne proste tento návrh platí.")
    }

    @Test("decimal commas survive shared punctuation spacing and remain idempotent")
    func decimalComma() {
        let once = clean("výsledok je 3,14")
        #expect(once == "Výsledok je 3,14.")
        #expect(clean(once) == once)
    }

    @Test("abbreviation and ordinal periods do not capitalize the following common word")
    func nonSentencePeriods() {
        #expect(clean("napr. toto funguje") == "Napr. toto funguje.")
        #expect(clean("je to t. j. bežný prípad") == "Je to t. j. bežný prípad.")
        #expect(clean("získal 1. miesto v súťaži") == "Získal 1. miesto v súťaži.")
    }

    @Test("interrogative words gain a question mark while ambiguous openers do not")
    func questions() {
        #expect(clean("prečo to nefunguje") == "Prečo to nefunguje?")
        #expect(clean("koľko to stojí") == "Koľko to stojí?")
        #expect(clean("ako sme sa dohodli prídem zajtra") == "Ako sme sa dohodli prídem zajtra.")
    }

    @Test("Slovak prose marks and spacing normalize mechanically")
    func proseTypography() {
        #expect(clean(#"povedal "prídem zajtra""#) == "Povedal „prídem zajtra“.")
        #expect(clean(#"povedal: "Prídem zajtra.""#) == "Povedal: „Prídem zajtra.“")
        #expect(clean("neviem... možno zajtra") == "Neviem… možno zajtra.")
        #expect(clean("to je - myslím - dobré") == "To je – myslím – dobré.")
        #expect(clean("možnosť áno / nie platí") == "Možnosť áno/nie platí.")
        #expect(clean("text ( poznámka ).") == "Text (poznámka).")
        #expect(clean("festival '89 bol úspešný") == "Festival ’89 bol úspešný.")
    }

    @Test("percent, currency, and temperature use a fixed space")
    func measurementSpacing() {
        #expect(clean("zľava je 20%") == "Zľava je 20\(fixedSpace)%.")
        #expect(clean("cena je 50 EUR") == "Cena je 50\(fixedSpace)EUR.")
        #expect(clean("teplota je 9 ° C") == "Teplota je 9\(fixedSpace)°C.")
    }

    @Test("technical symbols render only when their neighbors anchor the meaning")
    func spokenTechnicalSymbols() {
        #expect(clean("otvor main bodka py") == "Otvor main.py")
        #expect(clean("nastav max podčiarkovník retries") == "Nastav max_retries")
        #expect(clean("napíš jana bodka novakova zavináč example bodka sk")
            == "Napíš jana.novakova@example.sk")
        #expect(clean("volaj otvorená zátvorka test zatvorená zátvorka")
            == "volaj(test)")
    }

    @Test("ordinary punctuation nouns and embedded identifiers remain ordinary text")
    func ordinaryPunctuationAndIdentifiers() {
        #expect(clean("bodka je interpunkčné znamienko") == "Bodka je interpunkčné znamienko.")
        #expect(clean("pomlčka môže oddeľovať vsuvku") == "Pomlčka môže oddeľovať vsuvku.")
        #expect(clean("súbor main.py používa max_retries")
            == "Súbor main.py používa max_retries")
    }

    @Test("code-editor prose rules leave ASCII code punctuation untouched")
    func codeEditorSafety() {
        #expect(clean(#"let_value = "text";"#, category: .codeEditor)
            == #"let_value = "text";"#)
    }

    @Test("terminal symbols render but prose orthography never mutates the command")
    func terminalSafety() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("git log pomlčka pomlčka oneline", category: .terminal)
            == "git log --oneline")
        #expect(clean("cd tilda lomka projekty lomka VoiceType", category: .terminal)
            == "cd ~/projekty/VoiceType")
        #expect(clean("printf 3,14", category: .terminal) == "printf 3,14")
    }
}

@Suite("Cleanup polish — Slovak model output")
struct SlovakPolishTests {
    private let fixedSpace = "\u{00A0}"

    @Test("model output receives the same mechanical Slovak repairs")
    func orthographicRepair() {
        #expect(CleanupPolish.apply("výsledok je 3,14", options: .default, locale: "sk-SK")
            == "Výsledok je 3,14")
        #expect(CleanupPolish.apply(#"povedal "áno"."#, options: .default, locale: "sk-SK")
            == "Povedal „áno“.")
        #expect(CleanupPolish.apply("cena je 20%", options: .default, locale: "sk-SK")
            == "Cena je 20\(fixedSpace)%")
    }

    @Test("context-anchored symbols also repair model output")
    func symbolRepair() {
        #expect(CleanupPolish.apply(
            "otvor main bodka py",
            options: .default,
            locale: "sk-SK") == "Otvor main.py")
    }
}

@Suite("Cleanup prompt — Slovak")
struct SlovakPromptTests {
    @Test("instructions are language-specific and contain no examples block")
    func instructions() {
        let instructions = CleanupPrompt.instructions(
            for: .default,
            context: CleanupContext(
                appBundleID: "com.apple.Terminal",
                appName: "Terminal",
                category: .terminal),
            locale: "sk-SK")
        #expect(instructions.contains("The dictation is in Slovak."))
        #expect(instructions.contains("pomlčka pomlčka verbose"))
        #expect(instructions.contains("d. m. rrrr"))
        #expect(instructions.contains("päť, nie, šesť položiek"))
        #expect(!instructions.contains("Examples (left = spoken"))
    }
}
