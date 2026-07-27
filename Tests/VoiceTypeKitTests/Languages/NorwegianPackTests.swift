import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Language pack — Norwegian Bokmål policy")
struct NorwegianPackPolicyTests {
    @Test("only non-lexical hesitation sounds are deterministic fillers")
    func fillerPolicy() {
        let nb = LanguagePack.norwegian
        #expect(nb.fillers.contains("ehm"))
        #expect(nb.fillers.contains("øh"))
        for word in [
            "hm", "hmm", "mm", "mhm", "altså", "liksom", "bare", "egentlig",
            "sånn", "vel", "jo", "ikke sant", "du vet",
        ] {
            #expect(!nb.fillers.contains(word), "\(word)")
        }
    }

    @Test("ambiguous punctuation names are not unconditional replacements")
    func punctuationPolicy() {
        let nb = LanguagePack.norwegian
        #expect(nb.spokenPunctuation.isEmpty)
        #expect(nb.symbols == nil)
        #expect(nb.capitalizedStandalonePronoun == nil)
    }

    @Test("question prefixes are unambiguous interrogatives, not bare finite verbs")
    func questionPolicy() {
        let nb = LanguagePack.norwegian
        for word in ["hva", "hvem", "hvilken", "hvor", "hvordan", "hvorfor", "når"] {
            #expect(nb.questionPrefixWords.contains(word), "\(word)")
        }
        for word in ["er", "kan", "vil", "kommer", "trenger", "sender", "går", "snakker"] {
            #expect(!nb.questionPrefixWords.contains(word), "\(word)")
        }
        #expect(nb.questionSuffixParticles == ["ikke sant"])
    }

    @Test("all Norwegian rules are named and masking pairs share terminal policy")
    func namedRulesAndPairs() {
        let rules = LanguagePack.norwegian.rules
        #expect(rules.allSatisfy { !$0.name.isEmpty })
        for (maskName, restoreName) in [
            ("mask Norwegian abbreviation periods", "restore Norwegian abbreviation periods"),
            ("mask Norwegian date periods", "restore Norwegian date periods"),
            ("mask Norwegian decimal comma", "restore Norwegian decimal comma"),
        ] {
            let mask = rules.first { $0.name == maskName }
            let restore = rules.first { $0.name == restoreName }
            #expect(mask != nil, "\(maskName)")
            #expect(restore != nil, "\(restoreName)")
            #expect(mask?.runsInTerminal == restore?.runsInTerminal)
        }
    }
}

@Suite("Rule-based cleanup — Norwegian Bokmål")
struct NorwegianRuleCleanupTests {
    private func clean(_ text: String,
                       category: AppCategory = .general,
                       options: CleanupOptions = .default) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(category: category),
            locale: "nb-NO")
    }

    // MARK: Fillers

    @Test("Norwegian hesitation sounds are removed")
    func fillers() {
        #expect(clean("øh jeg tror vi bør vente") == "Jeg tror vi bør vente.")
        #expect(clean("vi bør ehm vente til mandag") == "Vi bør vente til mandag.")
    }

    @Test("meaningful discourse words and backchannels survive")
    func ambiguousFillersSurvive() {
        #expect(clean("altså dette er egentlig bare sånn det virker")
            == "Altså dette er egentlig bare sånn det virker.")
        #expect(clean("jo vi kommer vel på mandag")
            == "Jo vi kommer vel på mandag.")
        #expect(clean("mhm det høres riktig ut")
            == "Mhm det høres riktig ut.")
    }

    // MARK: Numbers, dates and punctuation

    @Test("decimal commas survive shared punctuation spacing")
    func decimalComma() {
        #expect(clean("temperaturen er 21,5 grader")
            == "Temperaturen er 21,5 grader.")
        #expect(clean("pi er omtrent 3,14159")
            == "Pi er omtrent 3,14159.")
        #expect(clean("det var 30, 40 personer")
            == "Det var 30, 40 personer.")
    }

    @Test("Norwegian quantity designators take a space")
    func quantitySpacing() {
        #expect(clean("det koster 250kr og rabatten er 10%")
            == "Det koster 250 kr og rabatten er 10 %.")
        #expect(clean("billetten koster €25")
            == "Billetten koster € 25.")
        #expect(clean("pakken veier 5kg og det er 18°C ute")
            == "Pakken veier 5 kg og det er 18 °C ute.")
    }

    @Test("code-editor arithmetic and compact literals are not respaced")
    func codeEditorQuantitySafety() {
        #expect(clean("value%2", category: .codeEditor) == "value%2.")
        #expect(clean("$10", category: .codeEditor) == "$10.")
    }

    @Test("day-month dates keep lowercase month names")
    func dateMonthCapitalization() {
        #expect(clean("vi møtes 17. mai 2026")
            == "Vi møtes 17. mai 2026.")
        #expect(clean("fristen er 1. Juli")
            == "Fristen er 1. juli.")
        #expect(clean("mai er en fin måned")
            == "Mai er en fin måned.")
    }

    @Test("abbreviation periods do not create false sentence capitals")
    func abbreviationCapitalization() {
        #expect(clean("vi trenger f.eks. kaffe og te")
            == "Vi trenger f.eks. kaffe og te.")
        #expect(clean("møtet starter kl. ni")
            == "Møtet starter kl. ni.")
        #expect(clean("se bl.a. vedleggene")
            == "Se bl.a. vedleggene.")
    }

    @Test("ellipsis is preserved instead of collapsed to a period")
    func ellipsis() {
        #expect(clean("jeg vet ikke... kanskje i morgen")
            == "Jeg vet ikke… kanskje i morgen.")
        #expect(clean("er du sikker ...")
            == "Er du sikker …")
    }

    @Test("masking placeholders never leak")
    func placeholdersNeverLeak() {
        let inputs = [
            "vi trenger f.eks. kaffe",
            "vi møtes 17. mai",
            "temperaturen er 21,5 grader",
        ]
        for input in inputs {
            let output = clean(input)
            #expect(!output.contains(NorwegianOrthography.abbreviationDot), "\(output)")
            #expect(!output.contains(NorwegianOrthography.dateDot), "\(output)")
            #expect(!output.contains(NorwegianOrthography.decimalComma), "\(output)")
        }
    }

    // MARK: Questions

    @Test("interrogatives and auxiliary-first questions gain a question mark")
    func initialQuestions() {
        #expect(clean("hvor er nærmeste togstasjon")
            == "Hvor er nærmeste togstasjon?")
        #expect(clean("kan vi møtes i morgen")
            == "Kan vi møtes i morgen?")
        #expect(clean("du kommer i morgen ikke sant")
            == "Du kommer i morgen ikke sant?")
    }

    @Test("a content question after another sentence is repaired")
    func nonInitialContentQuestion() {
        #expect(clean("vi er klare. hvor skal vi begynne")
            == "Vi er klare. Hvor skal vi begynne?")
    }

    @Test("common subject-omitted messages are not guessed to be questions")
    func lexicalFragmentsStayStatements() {
        #expect(clean("kommer i morgen") == "Kommer i morgen.")
        #expect(clean("trenger hjelp med rapporten")
            == "Trenger hjelp med rapporten.")
        #expect(clean("er på vei") == "Er på vei.")
        #expect(clean("kan møte i morgen") == "Kan møte i morgen.")
    }

    // MARK: Spoken code

    @Test("known file extensions and Norwegian identifier symbols render")
    func filesAndIdentifiers() {
        #expect(clean("åpne main punktum py og config punktum json")
            == "Åpne main.py og config.json")
        #expect(clean("sett maks understrek forsøk til fem")
            == "Sett maks_forsøk til fem.")
        #expect(clean("åpne src skråstrek index punktum ts")
            == "Åpne src/index.ts")
    }

    @Test("a Norwegian-spoken email address renders compactly")
    func email() {
        #expect(clean("send det til ola krøllalfa eksempel punktum no")
            == "Send det til ola@eksempel.no")
    }

    @Test("symbol words stay prose when no code shape makes them safe")
    func symbolWordsStayProse() {
        #expect(clean("nå setter vi punktum for saken")
            == "Nå setter vi punktum for saken.")
        #expect(clean("ordet bindestrek brukes her")
            == "Ordet bindestrek brukes her.")
        #expect(clean("skriv en skråstrek mellom ordene")
            == "Skriv en skråstrek mellom ordene.")
        #expect(clean("tre komma fem er et desimaltall")
            == "Tre komma fem er et desimaltall.")
    }

    @Test("embedded English names and existing identifiers survive")
    func embeddedEnglish() {
        #expect(clean("vi bruker Docker og Kubernetes i produksjon")
            == "Vi bruker Docker og Kubernetes i produksjon.")
        #expect(clean("feilen ligger i main.py") == "Feilen ligger i main.py")
        #expect(clean("variabelen max_retries er satt")
            == "Variabelen max_retries er satt.")
    }

    // MARK: Terminal

    @Test("terminal dictation remains command-safe")
    func terminalCommandSafety() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("temperaturen er 21,5 grader", category: .terminal)
            == "temperaturen er 21,5 grader")
    }

    @Test("Norwegian-spoken flags and paths render only in terminal context")
    func terminalSymbols() {
        #expect(clean("git commit bindestrek m første versjon", category: .terminal)
            == "git commit -m første versjon")
        #expect(clean("npm run build bindestrek bindestrek verbose",
                      category: .terminal)
            == "npm run build --verbose")
        #expect(clean("git status minus minus short", category: .terminal)
            == "git status --short")
        #expect(clean("cd tilde skråstrek prosjekter", category: .terminal)
            == "cd ~/prosjekter")
        #expect(clean("punktum skråstrek build", category: .terminal)
            == "./build")
    }

    @Test("an unmatched terminal slash phrase is restored")
    func unmatchedSlashRestored() {
        #expect(clean("skriv skrå strek", category: .terminal)
            == "skriv skrå strek")
    }
}

@Suite("Cleanup polish — Norwegian Bokmål model output")
struct NorwegianPolishTests {
    private func polish(_ text: String,
                        category: AppCategory = .general) -> String {
        CleanupPolish.apply(
            text,
            options: .default,
            context: CleanupContext(category: category),
            locale: "nb-NO")
    }

    @Test("mechanical Bokmål rules also repair model output")
    func orthographyRepairs() {
        #expect(polish("møtet er 17. Mai og billetten koster €25.")
            == "Møtet er 17. mai og billetten koster € 25.")
        #expect(polish("vi trenger f.eks. kaffe.") == "Vi trenger f.eks. kaffe.")
        #expect(polish("hva skjer nå.") == "Hva skjer nå?")
    }

    @Test("spoken code words left by the model still render")
    func spokenCodeRepair() {
        #expect(polish("åpne main punktum py.") == "Åpne main.py.")
        #expect(polish("send til ola krøllalfa eksempel punktum no.")
            == "Send til ola@eksempel.no.")
    }

    @Test("terminal polish preserves commands while rendering flags")
    func terminalPolish() {
        #expect(polish("git status", category: .terminal) == "git status")
        #expect(polish("git status bindestrek bindestrek short",
                       category: .terminal)
            == "git status --short")
    }
}

@Suite("Cleanup sanitizer — Norwegian Bokmål")
struct NorwegianSanitizerTests {
    @Test("Norwegian model lead-ins are stripped")
    func norwegianLeadIn() {
        let nb = LanguagePack.norwegian
        #expect(CleanupSanitizer.strip(
            "Klart! Her er den renskrevne teksten: Jeg kommer i morgen.",
            pack: nb) == "Jeg kommer i morgen.")
        #expect(CleanupSanitizer.strip(
            "Her er transkripsjonen: Jeg kommer i morgen.",
            pack: nb) == "Jeg kommer i morgen.")
    }

    @Test("ordinary prose ending in a colon is preserved")
    func prosePreserved() {
        let text = "Teksten i e-posten: jeg kommer i morgen."
        #expect(CleanupSanitizer.strip(text, pack: .norwegian) == text)
    }
}

@Suite("Cleanup prompt — Norwegian Bokmål")
struct NorwegianPromptTests {
    private var instructions: String {
        CleanupPrompt.instructions(
            for: .default,
            context: .general,
            locale: "nb-NO")
    }

    @Test("prompt supplies every language-specific guidance field")
    func promptCoverage() {
        let guidance = LanguagePack.norwegian.prompt
        #expect(guidance.fillerExamples != nil)
        #expect(guidance.capitalizationRule != nil)
        #expect(guidance.codeRendering != nil)
        #expect(guidance.terminalGuidance != nil)
        #expect(guidance.codeEditorGuidance != nil)
        #expect(guidance.selfCorrectionRule != nil)
        #expect(guidance.addendum != nil)
    }

    @Test("instructions contain Bokmål mechanics and conservative ambiguity policy")
    func norwegianSubstance() {
        let text = instructions
        #expect(text.contains("Norwegian Bokmål"))
        #expect(text.contains("øhm"))
        #expect(text.contains("17. mai 2026"))
        #expect(text.contains("krøllalfa"))
        #expect(text.contains("When in doubt"))
        #expect(!text.contains("\"um\""))
        #expect(!text.contains("the pronoun \"I\""))
    }

    @Test("terminal and code-editor guidance are category-specific")
    func categoryGuidance() {
        let terminal = CleanupPrompt.instructions(
            for: .default,
            context: CleanupContext(category: .terminal),
            locale: "nb-NO")
        #expect(terminal.contains("--verbose"))
        #expect(terminal.contains("~/prosjekter"))

        let editor = CleanupPrompt.instructions(
            for: .default,
            context: CleanupContext(category: .codeEditor),
            locale: "nb-NO")
        #expect(editor.contains("API names"))
        #expect(editor.contains("identifier casing"))
    }

    @Test("no few-shot examples ship without model evaluation")
    func noFewShot() {
        #expect(LanguagePack.norwegian.prompt.fewShot.isEmpty)
        #expect(LanguagePack.norwegian.prompt.terminalFewShot.isEmpty)
    }
}
