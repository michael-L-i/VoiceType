import Foundation
import Testing
@testable import VoiceTypeKit

@Suite("Language pack — Lithuanian policy")
struct LithuanianPackPolicyTests {
    @Test("keeps deterministic fillers to pure hesitation vowels")
    func fillers() {
        let lt = LanguagePack.lithuanian
        #expect(lt.fillers == ["ėėė", "ėėėė", "eee", "eeee"])
        for meaningful in ["na", "nu", "žodžiu", "ta prasme", "tipo", "žinai", "hmm", "mmm"] {
            #expect(!lt.fillers.contains(meaningful))
        }
    }

    @Test("keeps ambiguous taškas out of unconditional punctuation")
    func ambiguousPunctuation() {
        let lt = LanguagePack.lithuanian
        #expect(lt.spokenPunctuation["taškas"] == nil)
        #expect(lt.spokenPunctuation["kablelis"] == ",")
        #expect(lt.spokenPunctuation["klaustukas"] == "?")
    }

    @Test("uses a local symbol rule without claiming the English-only pack field")
    func localSymbols() {
        let lt = LanguagePack.lithuanian
        #expect(lt.symbols == nil)
        #expect(lt.capitalizedStandalonePronoun == nil)
        #expect(lt.rules.contains { $0.name == "render Lithuanian technical symbols" })
    }

    @Test("ships complete Lithuanian prompt guidance without few-shot leakage")
    func promptGuidance() {
        let prompt = LanguagePack.lithuanian.prompt
        #expect(prompt.fillerExamples?.contains("ėėė") == true)
        #expect(prompt.capitalizationRule?.contains("month names lowercase") == true)
        #expect(prompt.codeRendering?.contains("pabraukimo brūkšnys") == true)
        #expect(prompt.terminalGuidance?.contains("--verbose") == true)
        #expect(prompt.codeEditorGuidance?.contains("Lithuanian comments") == true)
        #expect(prompt.selfCorrectionRule?.contains("trečiadienį") == true)
        #expect(prompt.addendum?.contains("decimal comma") == true)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Lithuanian")
struct LithuanianRuleCleanupTests {
    private let nbsp = "\u{00A0}"

    private func clean(
        _ text: String,
        category: AppCategory = .general
    ) -> String {
        RuleBasedCleanup.process(
            text,
            options: .default,
            context: CleanupContext(
                appBundleID: nil,
                appName: nil,
                category: category),
            locale: "lt-LT")
    }

    @Test("removes pure hesitation vowels at sentence and clause boundaries")
    func fillers() {
        #expect(clean("ėėė, šiandien susitinkame") == "Šiandien susitinkame.")
        #expect(clean("manau, eee, šis planas veiks") == "Manau, šis planas veiks.")
    }

    @Test("retains meaningful discourse words and expressive sounds")
    func ambiguousFillersRemain() {
        let out = clean("na, nu, žodžiu, hmm, šį planą dar aptarsime")
        for token in ["Na", "nu", "žodžiu", "hmm"] {
            #expect(out.contains(token))
        }
    }

    @Test("renders punctuation-only command words")
    func spokenPunctuation() {
        #expect(clean("pirmas kablelis antras") == "Pirmas, antras.")
        #expect(clean("ar ateisi klaustukas") == "Ar ateisi?")
        #expect(clean("tikrai šauktukas") == "Tikrai!")
    }

    @Test("spoken punctuation is idempotent after an engine-rendered mark")
    func spokenPunctuationIdempotent() {
        #expect(clean("puiku! šauktukas") == "Puiku!")
    }

    @Test("renders spoken and straight quotation marks as Lithuanian quotes")
    func quotationMarks() {
        #expect(
            clean("jis pasakė atidaromosios kabutės labas uždaromosios kabutės")
                == "Jis pasakė „labas“.")
        #expect(clean(#"jis pasakė "labas""#) == "Jis pasakė „labas“.")
    }

    @Test("protects written and spoken decimal commas from shared spacing")
    func decimalComma() {
        #expect(clean("temperatūra yra 20,5 laipsnio") == "Temperatūra yra 20,5 laipsnio.")
        #expect(clean("versija 3 kablelis 14 veikia") == "Versija 3,14 veikia.")
    }

    @Test("uses Lithuanian grouping and number-symbol spacing")
    func numberSpacing() {
        #expect(
            clean("biudžetas yra 12 500 Eur")
                == "Biudžetas yra 12\(nbsp)500\(nbsp)Eur.")
        #expect(clean("nuolaida yra 50%") == "Nuolaida yra 50\(nbsp)%.")
        #expect(clean("siunta sveria 12kg") == "Siunta sveria 12\(nbsp)kg.")
    }

    @Test("preserves lowercase after abbreviations and formats long dates")
    func abbreviationsAndDates() {
        #expect(clean("naudokite pvz. šį failą") == "Naudokite pvz. šį failą.")
        #expect(
            clean("susitinkame 2026 m. liepos 26 d.")
                == "Susitinkame 2026\(nbsp)m. liepos 26\(nbsp)d.")
        #expect(clean("data yra 2026 - 07 - 26") == "Data yra 2026-07-26.")
    }

    @Test("uses an en dash for a prose parenthetical")
    func proseDash() {
        #expect(clean("sprendimas - bent kol kas - veikia") == "Sprendimas – bent kol kas – veikia.")
    }

    @Test("explicit interrogative particles gain a question mark")
    func questionParticle() {
        #expect(clean("ar rytoj susitinkame") == "Ar rytoj susitinkame?")
        #expect(clean("nejaugi tai tiesa") == "Nejaugi tai tiesa?")
    }

    @Test("ordinary taškas remains content")
    func ordinaryPoint() {
        #expect(clean("šis taškas svarbus") == "Šis taškas svarbus.")
    }

    @Test("embedded English, files, and identifiers keep exact spelling")
    func embeddedTechnicalText() {
        #expect(
            clean("atidaryk config.json ir paleisk VoiceType")
                == "Atidaryk config.json ir paleisk VoiceType.")
        #expect(clean("atidaryk config taškas json") == "Atidaryk config.json")
        #expect(
            clean("paleisk max pabraukimo brūkšnys retries")
                == "Paleisk max_retries")
    }

    @Test("renders a Lithuanian-dictated email only when a TLD anchors it")
    func email() {
        #expect(
            clean("jonas taškas jonaitis ženklas eta gmail taškas com")
                == "jonas.jonaitis@gmail.com")
    }

    @Test("terminal category renders flags and paths but remains command-safe")
    func terminalCategory() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(
            clean("git commit brūkšnelis m", category: .terminal)
                == "git commit -m")
        #expect(
            clean(
                "cd tildė pasvirasis brūkšnys projektai pasvirasis brūkšnys voice",
                category: .terminal)
                == "cd ~/projektai/voice")
        #expect(clean("printf 3,14", category: .terminal) == "printf 3,14")
    }

    @Test("code-editor category keeps source quotes untouched")
    func codeEditorSafety() {
        #expect(clean(#"let value = "labas""#, category: .codeEditor) == #"let value = "labas""#)
    }
}

@Suite("Cleanup polish — Lithuanian model output")
struct LithuanianPolishTests {
    @Test("local rules repair decimal commas, quotes, and technical symbols")
    func polish() {
        let prose = CleanupPolish.apply(
            #"temperatūra 20,5 ir žodis "labas""#,
            options: .default,
            locale: "lt-LT")
        #expect(prose == "Temperatūra 20,5 ir žodis „labas“")

        let technical = CleanupPolish.apply(
            "atidaryk config taškas json",
            options: .default,
            locale: "lt-LT")
        #expect(technical == "Atidaryk config.json")
    }

    @Test("Lithuanian assistant lead-ins are stripped")
    func leadIn() {
        let out = CleanupSanitizer.strip(
            "Žinoma, štai sutvarkytas tekstas: Labas.",
            locale: "lt-LT")
        #expect(out == "Labas.")
    }
}

@Suite("Cleanup prompt — Lithuanian")
struct LithuanianPromptTests {
    @Test("instructions include every Lithuanian guidance section and no examples")
    func instructions() {
        let instructions = CleanupPrompt.instructions(
            for: .default,
            context: CleanupContext(
                appBundleID: nil,
                appName: nil,
                category: .terminal),
            locale: "lt-LT")
        #expect(instructions.contains("The dictation is in Lithuanian"))
        #expect(instructions.contains("month names lowercase"))
        #expect(instructions.contains("pabraukimo brūkšnys"))
        #expect(instructions.contains("brūkšnelis brūkšnelis verbose"))
        #expect(instructions.contains("trečiadienį"))
        #expect(instructions.contains("Use a decimal comma"))
        #expect(!instructions.contains("Examples (left = spoken"))
    }
}
