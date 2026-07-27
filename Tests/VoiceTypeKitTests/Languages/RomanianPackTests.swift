import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Language pack — Romanian policy")
struct RomanianPackPolicyTests {
    @Test("only non-lexical central-vowel hesitations are deterministic fillers")
    func fillers() {
        let ro = LanguagePack.romanian
        #expect(ro.fillers.contains("ăăă"))
        #expect(ro.fillers.contains("îîî"))
        #expect(ro.fillers.contains("ăm"))
        for meaningful in ["deci", "păi", "adică", "gen", "mă rog", "mhm", "hm", "mmm"] {
            #expect(!ro.fillers.contains(meaningful), "\(meaningful)")
        }
    }

    @Test("bare punctuation nouns stay lexical and shared symbol opt-ins remain English-only")
    func punctuationPolicy() {
        let ro = LanguagePack.romanian
        #expect(ro.spokenPunctuation["punct"] == nil)
        #expect(ro.spokenPunctuation["virgulă"] == nil)
        #expect(ro.spokenPunctuation["două puncte"] == nil)
        #expect(ro.spokenPunctuation["semnul întrebării"] == "?")
        #expect(ro.symbols == nil)
        #expect(ro.capitalizedStandalonePronoun == nil)
    }

    @Test("Romanian owns complete prompt guidance without unvalidated few-shot examples")
    func promptGuidance() {
        let guidance = LanguagePack.romanian.prompt
        #expect(guidance.fillerExamples?.contains("păi") == true)
        #expect(guidance.capitalizationRule?.contains("month names lowercase") == true)
        #expect(guidance.codeRendering?.contains("main punct pai") == true)
        #expect(guidance.terminalGuidance?.contains("minus minus verbose") == true)
        #expect(guidance.codeEditorGuidance != nil)
        #expect(guidance.selfCorrectionRule?.contains("de fapt miercuri") == true)
        #expect(guidance.addendum?.contains("sa/s-a") == true)
        #expect(guidance.fewShot.isEmpty)
        #expect(guidance.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Romanian")
struct RomanianRuleCleanupTests {
    private func clean(_ text: String,
                       category: AppCategory = .general,
                       options: CleanupOptions = .default) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(category: category),
            locale: "ro-RO")
    }

    @Test("pure hesitation sounds are removed cleanly")
    func fillers() {
        #expect(clean("ăăă, cred că îîî putem începe") == "Cred că putem începe.")
        #expect(clean("ăm alegem varianta a doua") == "Alegem varianta a doua.")
    }

    @Test("meaningful discourse markers and lookalike interjections are retained")
    func ambiguousFillersStay() {
        let out = clean("păi deci acesta este un gen de exemplu și mhm înseamnă că sunt de acord")
        for word in ["Păi", "deci", "gen", "mhm"] {
            #expect(out.contains(word), "\(word)")
        }
    }

    @Test("legacy cedilla diacritics normalize to Romanian comma-below forms")
    func diacritics() {
        #expect(clean("Ştiinţa foloseşte măsurători") == "Știința folosește măsurători.")
    }

    @Test("explicit spoken punctuation renders and remains idempotent")
    func spokenPunctuation() {
        #expect(clean("unde mergem semnul întrebării") == "Unde mergem?")
        #expect(clean("atenție semnul exclamării") == "Atenție!")
        #expect(clean("unu punct și virgulă doi") == "Unu; doi.")
        #expect(clean("mai așteaptă puncte de suspensie") == "Mai așteaptă…")
        #expect(clean("unde mergem? semnul întrebării") == "Unde mergem?")
    }

    @Test("safe interrogative openers gain a question mark while ambiguous ce/de do not")
    func questions() {
        #expect(clean("unde mergem mâine") == "Unde mergem mâine?")
        #expect(clean("câte exemplare trimitem") == "Câte exemplare trimitem?")
        #expect(clean("ce frumos este aici") == "Ce frumos este aici.")
        #expect(clean("de luni lucrăm aici") == "De luni lucrăm aici.")
    }

    @Test("decimal commas survive shared punctuation spacing and currency stays attached")
    func numbersAndCurrency() {
        #expect(clean("costă 1.234,56 RON") == "Costă 1.234,56\u{00A0}RON.")
        #expect(clean("procentul este 13,6 și suma este 25 €")
                == "Procentul este 13,6 și suma este 25\u{00A0}€.")
    }

    @Test("Romanian prose typography normalizes smart quotes, ellipses, and year apostrophes")
    func proseTypography() {
        #expect(clean("“acesta este citatul”") == "„acesta este citatul”.")
        #expect(clean("mai așteaptă...") == "Mai așteaptă…")
        #expect(clean("anii '90 au schimbat multe") == "Anii ’90 au schimbat multe.")
    }

    @Test("abbreviation periods do not trigger false sentence capitalization")
    func abbreviations() {
        #expect(clean("consultați nr. trei și str. principală")
                == "Consultați nr. trei și str. principală.")
        #expect(clean("etc. rămâne o abreviere") == "Etc. rămâne o abreviere.")
    }

    @Test("unambiguously spaced clitics and prepositional compounds regain hyphens")
    func hyphens() {
        #expect(clean("s a întors și n a mai plecat dintr un motiv")
                == "S-a întors și n-a mai plecat dintr-un motiv.")
        #expect(clean("m am întâlnit cu el într o cafenea")
                == "M-am întâlnit cu el într-o cafenea.")
    }

    @Test("constrained Romanian symbol words render file names, identifiers, mail, and parens")
    func spokenSymbols() {
        #expect(clean("trimite main punct pai") == "Trimite main.py")
        #expect(clean("variabila max underscore retries este setată")
                == "Variabila max_retries este setată.")
        #expect(clean("scrie la ion arond exemplu punct ro") == "Scrie la ion@exemplu.ro")
        #expect(clean("apelează print deschide paranteză x virgulă y închide paranteză")
                == "Apelează print(x, y)")
    }

    @Test("ordinary uses of punct and minus remain prose")
    func ambiguousSymbolsStay() {
        #expect(clean("acesta este un punct important") == "Acesta este un punct important.")
        #expect(clean("rezultatul este x minus valoarea anterioară")
                == "Rezultatul este x minus valoarea anterioară.")
    }

    @Test("embedded English and identifiers survive Romanian cleanup")
    func embeddedTechnicalText() {
        #expect(clean("config.json rămâne neschimbat") == "config.json rămâne neschimbat.")
        #expect(clean("folosim VoiceType și APIClient") == "Folosim VoiceType și APIClient.")
    }

    @Test("terminal dictation renders only command-safe symbols and never gains prose punctuation")
    func terminal() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("git log minus minus oneline", category: .terminal)
                == "git log --oneline")
        #expect(clean("python app punct pai minus v", category: .terminal)
                == "python app.py -v")
        #expect(clean("echo 13,6", category: .terminal) == "echo 13,6")
    }

    @Test("code-editor context keeps ASCII typography syntax")
    func codeEditorTypography() {
        #expect(clean("let name = 'api_client'", category: .codeEditor)
                == "Let name = 'api_client'")
        #expect(clean("“quoted”", category: .codeEditor) == "“quoted”.")
    }
}

@Suite("Cleanup polish — Romanian model output")
struct RomanianPolishTests {
    @Test("model output receives the same mechanical orthography repairs")
    func orthography() {
        #expect(CleanupPolish.apply("costă 13,6 lei.", options: .default, locale: "ro-RO")
                == "Costă 13,6\u{00A0}lei.")
        #expect(CleanupPolish.apply("ştiinţa continuă.", options: .default, locale: "ro-RO")
                == "Știința continuă.")
        #expect(CleanupPolish.apply("trimite main punct pai", options: .default, locale: "ro-RO")
                == "Trimite main.py")
    }

    @Test("Romanian model lead-ins are stripped without changing real content")
    func sanitizer() {
        #expect(CleanupSanitizer.strip(
            "Sigur, iată transcrierea corectată: Ne vedem mâine.",
            locale: "ro-RO") == "Ne vedem mâine.")
        #expect(CleanupSanitizer.strip(
            "Iată planul meu: plecăm mâine.",
            locale: "ro-RO") == "Iată planul meu: plecăm mâine.")
    }
}

@Suite("Cleanup prompt — Romanian")
struct RomanianPromptTests {
    @Test("instructions carry Romanian ambiguity and formatting policy")
    func instructions() {
        let prompt = CleanupPrompt.instructions(
            for: .default,
            context: CleanupContext(category: .terminal),
            locale: "ro-RO")
        #expect(prompt.contains("deci"))
        #expect(prompt.contains("sa/s-a"))
        #expect(prompt.contains("31.12.2026"))
        #expect(prompt.contains("minus minus verbose"))
        #expect(prompt.contains("Romanian"))
        #expect(!prompt.contains("Examples (left = spoken"))
    }
}
