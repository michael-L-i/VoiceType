import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Language pack — Danish policy")
struct DanishPackPolicyTests {
    @Test("only pure hesitation sounds are deterministic fillers")
    func fillers() {
        let da = LanguagePack.danish
        #expect(da.fillers.contains("øh"))
        #expect(da.fillers.contains("øhm"))
        #expect(!da.fillers.contains("altså"))
        #expect(!da.fillers.contains("ligesom"))
        #expect(!da.fillers.contains("jo"))
        #expect(!da.fillers.contains("hmm"))
    }

    @Test("spoken symbols are owned by local rules, not the English-only pack field")
    func localSymbols() {
        let da = LanguagePack.danish
        #expect(da.symbols == nil)
        #expect(da.spokenPunctuation.isEmpty)
        #expect(da.rules.count >= 8)
        #expect(da.spokenSymbolWords.contains("understregning"))
    }

    @Test("Danish prompt guidance is complete and ships no unvalidated few-shot")
    func promptPolicy() {
        let prompt = LanguagePack.danish.prompt
        #expect(prompt.fillerExamples?.contains("ligesom") == true)
        #expect(prompt.capitalizationRule?.contains(#""I""#) == true)
        #expect(prompt.codeRendering?.contains("punktum py") == true)
        #expect(prompt.terminalGuidance?.contains("--verbose") == true)
        #expect(prompt.codeEditorGuidance != nil)
        #expect(prompt.selfCorrectionRule?.contains("nej vent") == true)
        #expect(prompt.addendum?.contains("3,14") == true)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Danish")
struct DanishRuleCleanupTests {
    private func clean(
        _ text: String,
        category: AppCategory = .general,
        options: CleanupOptions = .default
    ) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(category: category),
            locale: "da-DK")
    }

    @Test("pure Danish hesitation sounds are removed")
    func fillers() {
        #expect(clean("øh, jeg synes øhm det virker") == "Jeg synes det virker.")
        #expect(clean("æh vi prøver igen") == "Vi prøver igen.")
    }

    @Test("meaningful discourse words are never removed deterministically")
    func ambiguousFillersStay() {
        let out = clean("altså jo det er ligesom sådan det er hmm")
        #expect(out == "Altså jo det er ligesom sådan det er hmm.")
    }

    @Test("spoken Danish punctuation renders with Danish spacing")
    func spokenPunctuation() {
        #expect(clean("hej komma hvordan går det spørgsmålstegn")
            == "Hej, hvordan går det?")
        #expect(clean("først kolon derefter semikolon til sidst")
            == "Først: derefter; til sidst.")
    }

    @Test("spoken punctuation rendering is idempotent")
    func spokenPunctuationIdempotence() {
        #expect(clean("det virker? spørgsmålstegn") == "Det virker?")
        #expect(clean("første, komma anden") == "Første, anden.")
    }

    @Test("obvious metalinguistic punctuation nouns stay words")
    func punctuationWordsStay() {
        #expect(clean("vi taler om et komma og et punktum")
            == "Vi taler om et komma og et punktum.")
        #expect(clean("vi taler om en bindestreg og en ellipse")
            == "Vi taler om en bindestreg og en ellipse.")
    }

    @Test("verb-first and interrogative-word questions gain a question mark")
    func questionHeuristic() {
        #expect(clean("kan du komme i morgen") == "Kan du komme i morgen?")
        #expect(clean("hvornår begynder mødet") == "Hvornår begynder mødet?")
        #expect(clean("kom hjem nu") == "Kom hjem nu.")
        #expect(clean("gør det nu") == "Gør det nu.")
    }

    @Test("decimal commas and Danish grouping points survive shared spacing")
    func decimalComma() {
        #expect(clean("beløbet er 1.234,56 kr.") == "Beløbet er 1.234,56 kr.")
        #expect(clean("temperaturen er 20,5 grader") == "Temperaturen er 20,5 grader.")
    }

    @Test("abbreviation periods do not capitalize the following word")
    func abbreviationCapitalization() {
        #expect(clean("det sker bl.a. i morgen") == "Det sker bl.a. i morgen.")
        #expect(clean("vi mødes kl. fem ved stationen")
            == "Vi mødes kl. fem ved stationen.")
        #expect(clean("tag papir, blyanter osv.") == "Tag papir, blyanter osv.")
    }

    @Test("high-context currency and clock abbreviations are completed")
    func abbreviationCompletion() {
        #expect(clean("prisen er 100kr") == "Prisen er 100 kr.")
        #expect(clean("mødet begynder kl 14.30")
            == "Mødet begynder kl. 14.30")
    }

    @Test("spoken line and paragraph breaks survive the Latin whitespace pass")
    func lineBreaks() {
        #expect(clean("første linje ny linje anden linje")
            == "Første linje\nanden linje.")
        #expect(clean("første afsnit nyt afsnit andet afsnit")
            == "Første afsnit\n\nandet afsnit.")
        #expect(clean("skriv det på en ny linje")
            == "Skriv det på en ny linje.")
    }

    @Test("dictated file names, identifiers, email, and paired marks render compactly")
    func technicalSymbols() {
        #expect(clean("send config punktum json og bruger understregning id til mig")
            == "Send config.json og bruger_id til mig.")
        #expect(clean("skriv til anna punktum hansen snabel-a eksempel punktum dk")
            == "Skriv til anna.hansen@eksempel.dk")
        #expect(clean("kald startparentes navn komma alder slutparentes")
            == "Kald (navn, alder)")
    }

    @Test("ordinary embedded English and identifiers survive untouched")
    func embeddedEnglish() {
        #expect(clean("vi bruger VoiceType med parseRequest og main.py")
            == "Vi bruger VoiceType med parseRequest og main.py")
    }

    @Test("terminal dictation renders explicit flags and paths without prose repairs")
    func terminalCategory() {
        #expect(clean("git log bindestreg bindestreg oneline", category: .terminal)
            == "git log --oneline")
        #expect(clean("cd tilde skråstreg projekter skråstreg VoiceType",
                      category: .terminal)
            == "cd ~/projekter/VoiceType")
        #expect(clean("git status", category: .terminal) == "git status")
    }
}

@Suite("Cleanup polish — Danish model output")
struct DanishPolishTests {
    @Test("Danish orthography rules repair model output too")
    func orthographyRepair() {
        let out = CleanupPolish.apply(
            "beløbet er 3,14 og vi mødes bl.a. i morgen.",
            options: .default,
            locale: "da-DK")
        #expect(out == "Beløbet er 3,14 og vi mødes bl.a. i morgen.")
    }

    @Test("spoken code names left by the model are rendered")
    func spokenCodeRepair() {
        let out = CleanupPolish.apply(
            "send config punktum json til mig",
            options: .default,
            locale: "da-DK")
        #expect(out == "Send config.json til mig")
    }

    @Test("Danish model lead-ins are stripped conservatively")
    func leadInSanitizer() {
        #expect(CleanupSanitizer.strip(
            "Klart, her er den rensede tekst: Vi ses i morgen.",
            locale: "da-DK") == "Vi ses i morgen.")
        #expect(CleanupSanitizer.strip(
            "Her er planen: Vi ses i morgen.",
            locale: "da-DK") == "Her er planen: Vi ses i morgen.")
    }
}
