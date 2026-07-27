import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Language pack — Czech policy")
struct CzechPackPolicyTests {
    @Test("only unmistakable hesitation spellings are deterministic fillers")
    func fillerPolicy() {
        let cs = LanguagePack.czech
        #expect(cs.fillers.contains("ehm"))
        #expect(cs.fillers.contains("eee"))
        for word in ["no", "jako", "prostě", "vlastně", "tedy", "takže",
                     "jakoby", "hm", "mhm", "aha", "jo", "em", "ee"] {
            #expect(!cs.fillers.contains(word), "\(word)")
        }
    }

    @Test("ambiguous punctuation nouns never enter unconditional replacement")
    func noBlindSpokenPunctuation() {
        let cs = LanguagePack.czech
        #expect(cs.spokenPunctuation.isEmpty)
        #expect(cs.symbols == nil)
    }

    @Test("question openers are interrogatives, not ambiguous finite verbs")
    func questionPolicy() {
        let cs = LanguagePack.czech
        #expect(cs.questionPrefixWords.contains("proč"))
        #expect(cs.questionPrefixWords.contains("kterým"))
        #expect(cs.questionSuffixParticles.contains("viď"))
        for word in ["je", "jsou", "může", "chce", "máš", "jestli"] {
            #expect(!cs.questionPrefixWords.contains(word), "\(word)")
        }
    }

    @Test("every masking pair has matching terminal behavior")
    func maskingPairsAgree() {
        let rules = LanguagePack.czech.rules
        let abbreviationMask = rules.first { $0.name == "mask abbreviation periods" }
        let abbreviationRestore = rules.first { $0.name == "restore abbreviation periods" }
        let decimalMask = rules.first { $0.name == "mask decimal comma" }
        let decimalRestore = rules.first { $0.name == "restore decimal comma" }
        let fillerMask = rules.first { $0.name == "protect fillers in terminal" }
        let fillerRestore = rules.first { $0.name == "restore protected terminal fillers" }

        #expect(abbreviationMask?.runsInTerminal == abbreviationRestore?.runsInTerminal)
        #expect(decimalMask?.runsInTerminal == decimalRestore?.runsInTerminal)
        #expect(fillerMask?.runsInTerminal == fillerRestore?.runsInTerminal)
    }
}

@Suite("Rule-based cleanup — Czech")
struct CzechRuleCleanupTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(
            text,
            options: .default,
            context: CleanupContext(category: category),
            locale: "cs-CZ")
    }

    // MARK: Fillers

    @Test("hesitation sounds are removed")
    func fillers() {
        #expect(clean("ehm myslím že to stihneme") == "Myslím že to stihneme.")
        #expect(clean("to je, eee, dobrý nápad") == "To je, dobrý nápad.")
    }

    @Test("meaningful discourse words and responses are retained")
    func ambiguousFillersStay() {
        #expect(clean("no takže to je vlastně prostě hotové")
            == "No takže to je vlastně prostě hotové.")
        #expect(clean("mhm to dává smysl") == "Mhm to dává smysl.")
    }

    // MARK: Numbers and abbreviations

    @Test("a tight Czech decimal comma survives punctuation spacing")
    func decimalComma() {
        #expect(clean("teplota je 21,5 stupně") == "Teplota je 21,5 stupně.")
        #expect(clean("pí je přibližně 3,14159") == "Pí je přibližně 3,14159.")
        #expect(clean("bylo tam 30, 40 lidí") == "Bylo tam 30, 40 lidí.")
    }

    @Test("abbreviation periods do not start phantom sentences")
    func abbreviations() {
        #expect(clean("potřebujeme např. nový server")
            == "Potřebujeme např. nový server.")
        #expect(clean("jde o tzv. slepou uličku")
            == "Jde o tzv. slepou uličku.")
        #expect(clean("firma je s. r. o. se sídlem v Brně")
            == "Firma je s. r. o. se sídlem v Brně.")
    }

    @Test("a sentence-final abbreviation receives exactly one period")
    func abbreviationAtEnd() {
        #expect(clean("podrobnosti najdeš např.") == "Podrobnosti najdeš např.")
        #expect(clean("a tak dále atd.") == "A tak dále atd.")
    }

    // MARK: Typography

    @Test("straight and English quotes normalize to Czech primary quotes")
    func quotationMarks() {
        #expect(clean(#"řekl "ahoj světe""#) == "Řekl „ahoj světe“.")
        #expect(clean("označil to “pracovní verzí”")
            == "Označil to „pracovní verzí“.")
        #expect(clean("to je „ správně “") == "To je „správně“.")
    }

    @Test("three periods become the single Czech ellipsis mark")
    func ellipsis() {
        #expect(clean("počkej...") == "Počkej…")
        #expect(clean("já nevím... možná zítra") == "Já nevím… možná zítra.")
    }

    // MARK: Questions

    @Test("interrogative words and Czech tags gain a question mark")
    func questions() {
        #expect(clean("proč to nefunguje") == "Proč to nefunguje?")
        #expect(clean("kterým vlakem pojedeme") == "Kterým vlakem pojedeme?")
        #expect(clean("přijdeš zítra viď") == "Přijdeš zítra viď?")
    }

    @Test("preposition-led and later questions are detected")
    func questionCoverage() {
        #expect(clean("za jak dlouho to bude hotové")
            == "Za jak dlouho to bude hotové?")
        #expect(clean("to funguje. kdy začneme")
            == "To funguje. Kdy začneme?")
    }

    @Test("verb-initial statements stay statements")
    func statementsStayStatements() {
        #expect(clean("je pondělí") == "Je pondělí.")
        #expect(clean("může přijít zítra") == "Může přijít zítra.")
    }

    // MARK: Spoken technical symbols

    @Test("guarded file names, identifiers, and e-mail render in prose")
    func spokenIdentifiers() {
        #expect(clean("otevři main tečka py") == "Otevři main.py")
        #expect(clean("max podtržítko retries je pět")
            == "max_retries je pět.")
        #expect(clean("pošli to na jan zavináč example tečka cz")
            == "Pošli to na jan@example.cz")
    }

    @Test("symbol nouns remain prose without technical neighbors")
    func spokenSymbolGuards() {
        #expect(clean("desetinná čárka odděluje celou část")
            == "Desetinná čárka odděluje celou část.")
        #expect(clean("nad termínem zůstává otazník")
            == "Nad termínem zůstává otazník.")
        #expect(clean("to je důležitá tečka v textu")
            == "To je důležitá tečka v textu.")
    }

    @Test("code editor enables dictated parentheses and comma")
    func codeEditorSymbols() {
        #expect(clean("print otevřená závorka x čárka y uzavřená závorka",
                      category: .codeEditor) == "print(x, y)")
    }

    // MARK: Embedded English and terminal safety

    @Test("embedded English and existing identifiers survive")
    func embeddedEnglish() {
        #expect(clean("používáme Docker a Kubernetes v produkci")
            == "Používáme Docker a Kubernetes v produkci.")
        #expect(clean("chyba je v config.json") == "Chyba je v config.json")
    }

    @Test("terminal commands stay byte-conscious while spoken syntax renders")
    func terminal() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("git commit pomlčka m oprava chyby", category: .terminal)
            == "git commit -m oprava chyby")
        #expect(clean("npm run build pomlčka pomlčka verbose", category: .terminal)
            == "npm run build --verbose")
        #expect(clean("cd tilda lomítko projekty", category: .terminal)
            == "cd ~/projekty")
    }

    @Test("terminal literals are protected from filler and decimal cleanup")
    func terminalLiteralSafety() {
        #expect(clean("echo ehm", category: .terminal) == "echo ehm")
        #expect(clean("printf 3,14", category: .terminal) == "printf 3,14")
    }

    @Test("no internal placeholder can leak")
    func noPlaceholderLeak() {
        for text in ["potřebujeme např. nový server", "hodnota je 3,14",
                     "echo ehm"] {
            let category: AppCategory = text.hasPrefix("echo") ? .terminal : .general
            let output = clean(text, category: category)
            #expect(!output.contains(CzechOrthography.abbreviationDot), "\(output)")
            #expect(!output.contains(CzechOrthography.decimalComma), "\(output)")
            #expect(!output.contains(CzechOrthography.terminalFillerShield), "\(output)")
        }
    }
}

@Suite("Cleanup polish — Czech model output")
struct CzechPolishTests {
    private func polish(_ text: String, category: AppCategory = .general) -> String {
        CleanupPolish.apply(
            text,
            options: .default,
            context: CleanupContext(category: category),
            locale: "cs-CZ")
    }

    @Test("Czech orthography repairs model output too")
    func orthography() {
        #expect(polish(#"řekl "ahoj""#) == "Řekl „ahoj“")
        #expect(polish("hodnota je 3,14.") == "Hodnota je 3,14.")
        #expect(polish("potřebujeme např. nový server.")
            == "Potřebujeme např. nový server.")
    }

    @Test("later and preposition-led questions repair after model output")
    func questions() {
        #expect(polish("za jak dlouho to bude hotové.")
            == "Za jak dlouho to bude hotové?")
        #expect(polish("to funguje. kdy začneme.")
            == "To funguje. Kdy začneme?")
    }
}

@Suite("Cleanup prompt — Czech guidance")
struct CzechPromptTests {
    @Test("prompt supplies Czech-specific cleanup substance")
    func substance() {
        let text = CleanupPrompt.instructions(
            for: .default, context: .general, locale: "cs-CZ")
        #expect(text.contains("Czech"))
        #expect(text.contains("ehm"))
        #expect(text.contains("pondělí"))
        #expect(text.contains("„…“"))
        #expect(text.contains("main.py"))
        #expect(text.contains("bysme"))
        #expect(!text.contains("the pronoun \"I\""))
        #expect(!text.contains(#": "um", "uh""#))
    }

    @Test("terminal guidance is Czech and examples remain empty")
    func terminalAndFewShot() {
        let text = CleanupPrompt.instructions(
            for: .default,
            context: CleanupContext(category: .terminal),
            locale: "cs-CZ")
        #expect(text.contains("pomlčka pomlčka verbose"))
        #expect(text.contains("~/projekty"))
        #expect(LanguagePack.czech.prompt.fewShot.isEmpty)
        #expect(LanguagePack.czech.prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Cleanup sanitizer — Czech lead-ins")
struct CzechSanitizerTests {
    @Test("Czech model wrappers are stripped without eating ordinary prose")
    func leadIns() {
        let pack = LanguagePack.czech
        #expect(CleanupSanitizer.strip(
            "Jasně! Tady je vyčištěný text: Přijdu zítra.", pack: pack)
            == "Přijdu zítra.")
        #expect(CleanupSanitizer.strip(
            "Zde je upravený přepis: Přijdu zítra.", pack: pack)
            == "Přijdu zítra.")

        let ordinary = "Text zprávy: přijdu zítra."
        #expect(CleanupSanitizer.strip(ordinary, pack: pack) == ordinary)
    }
}
