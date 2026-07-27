import Testing
import Foundation
@testable import VoiceTypeKit

/// Everything specific to the Dutch pack. Lives beside the other per-language
/// suites so a contributor working on nl touches exactly one source directory
/// and one test file — see docs/LOCALIZATION.md.
@Suite("Language pack — Dutch policy")
struct DutchPackPolicyTests {
    @Test("fillers are hesitation sounds only; Dutch content words are excluded")
    func fillerPolicy() {
        let nl = LanguagePack.dutch
        #expect(nl.fillers.contains("uhm"))
        #expect(nl.fillers.contains("ehm"))
        // "er" is a pronoun in Dutch ("er is", "er staat"), not English's filler.
        #expect(!nl.fillers.contains("er"))
        // "mm" is the millimetre abbreviation; only "mmm" is a hesitation.
        #expect(!nl.fillers.contains("mm"))
        for word in ["nou", "dus", "gewoon", "eigenlijk", "even", "toch", "ja", "hè"] {
            #expect(!nl.fillers.contains(word), "\(word)")
        }
    }

    @Test("spoken punctuation stays empty — punt/komma are everyday Dutch words")
    func noSpokenPunctuation() {
        #expect(LanguagePack.dutch.spokenPunctuation.isEmpty)
    }

    @Test("question openers exclude imperatives and words with a common statement reading")
    func questionOpenerPolicy() {
        let nl = LanguagePack.dutch
        #expect(nl.questionPrefixWords.contains("waarom"))
        #expect(nl.questionPrefixWords.contains("kunnen"))
        // Bare stems double as imperatives: "Ga naar huis" is not a question.
        for word in ["ga", "kom", "doe", "laat", "zie", "weet"] {
            #expect(!nl.questionPrefixWords.contains(word), "\(word)")
        }
        // "was" is also the imperative of wassen, "zijn" also means "his",
        // "wilde" is also the adjective "wild".
        for word in ["was", "zijn", "wilde"] {
            #expect(!nl.questionPrefixWords.contains(word), "\(word)")
        }
    }

    @Test("tag particles keep the accent on hè so they can't fire on -he words")
    func tagParticles() {
        #expect(LanguagePack.dutch.questionSuffixParticles.contains("hè"))
        #expect(!LanguagePack.dutch.questionSuffixParticles.contains("he"))
        #expect(!LanguagePack.dutch.questionSuffixParticles.contains("toch"))
    }

    @Test("every rule is named and the masking pairs share their terminal policy")
    func maskingPairsAgree() {
        let rules = LanguagePack.dutch.rules
        let mask = rules.first { $0.name == "mask abbreviation periods" }
        let restore = rules.first { $0.name == "restore abbreviation periods" }
        #expect(mask != nil)
        #expect(restore != nil)
        // If one ran in a terminal and the other didn't, a placeholder would leak.
        #expect(mask?.runsInTerminal == restore?.runsInTerminal)
    }
}

@Suite("Rule-based cleanup — Dutch")
struct DutchRuleCleanupTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(text, options: .default,
                                 context: CleanupContext(category: category),
                                 locale: "nl-NL")
    }

    // MARK: - Fillers

    @Test("hesitation sounds are removed, wherever they sit")
    func fillers() {
        #expect(clean("uh ik denk dat we het morgen moeten doen")
            == "Ik denk dat we het morgen moeten doen.")
        #expect(clean("we moeten, ehm, de release uitstellen")
            == "We moeten, de release uitstellen.")
    }

    @Test("ambiguous Dutch words are never removed deterministically")
    func ambiguousWordsKept() {
        #expect(clean("dus dat is eigenlijk gewoon toch even wachten")
            == "Dus dat is eigenlijk gewoon toch even wachten.")
        // "er" would have been destroyed by English's filler list.
        #expect(clean("er staat nog een fout in de tekst")
            == "Er staat nog een fout in de tekst.")
    }

    // MARK: - Numbers, money, percentages

    @Test("the decimal comma survives the shared punctuation-spacing pass")
    func decimalComma() {
        #expect(clean("de temperatuur is 21,5 graden") == "De temperatuur is 21,5 graden.")
        #expect(clean("pi is ongeveer 3,14159") == "Pi is ongeveer 3,14159.")
        // A comma the speaker actually meant as a comma keeps its space.
        #expect(clean("er waren 30, 40 mensen") == "Er waren 30, 40 mensen.")
    }

    @Test("the euro sign takes a space and the percent sign takes none")
    func euroAndPercent() {
        #expect(clean("het kost €15,50") == "Het kost € 15,50.")
        #expect(clean("het kost € 15,50") == "Het kost € 15,50.")
        #expect(clean("de omzet steeg met 12 %") == "De omzet steeg met 12%.")
    }

    @Test("a thousands separator is left exactly as spoken")
    func thousandsSeparator() {
        #expect(clean("we hebben 1.250 euro nodig") == "We hebben 1.250 euro nodig.")
    }

    // MARK: - Abbreviations

    @Test("an abbreviation period does not start a new sentence")
    func abbreviationDoesNotCapitalize() {
        #expect(clean("we hebben bijv. koffie en thee nodig")
            == "We hebben bijv. koffie en thee nodig.")
        #expect(clean("dat betekent d.w.z. dat we opnieuw moeten beginnen")
            == "Dat betekent d.w.z. dat we opnieuw moeten beginnen.")
    }

    @Test("a proper noun after an abbreviation keeps its capital")
    func abbreviationKeepsProperNoun() {
        #expect(clean("we bezoeken o.a. Amsterdam en Utrecht")
            == "We bezoeken o.a. Amsterdam en Utrecht.")
        #expect(clean("stuur het naar dhr. Jansen") == "Stuur het naar dhr. Jansen.")
    }

    @Test("a sentence ending in an abbreviation gets one period, not two")
    func abbreviationEndsSentence() {
        #expect(clean("meer informatie staat op blz.") == "Meer informatie staat op blz.")
    }

    @Test("the masking placeholder never reaches the output")
    func noPlaceholderLeak() {
        for text in ["we hebben bijv. koffie nodig", "meer staat op blz.",
                     "de prijs is ca. 20 euro", "de temperatuur is 21,5 graden"] {
            let out = clean(text)
            #expect(!out.contains(DutchOrthography.abbreviationDot), "\(out)")
            #expect(!out.contains(DutchOrthography.decimalComma), "\(out)")
        }
    }

    // MARK: - Capitalization

    @Test("a word starting with the ij digraph takes two capitals")
    func ijDigraph() {
        #expect(clean("ijsland is een prachtig land") == "IJsland is een prachtig land.")
        #expect(clean("ijmuiden ligt aan zee") == "IJmuiden ligt aan zee.")
        // A word merely containing "ij" is untouched.
        #expect(clean("mijn fiets is kapot") == "Mijn fiets is kapot.")
    }

    @Test("the capital moves past a sentence-initial 's / 't / 'n")
    func sentenceInitialClitic() {
        #expect(clean("'s ochtends regent het vaak") == "'s Ochtends regent het vaak.")
        #expect(clean("'t is bijna klaar") == "'t Is bijna klaar.")
        #expect(clean("'n vriend van me komt langs") == "'n Vriend van me komt langs.")
    }

    // MARK: - Questions

    @Test("an interrogative opener gains a question mark")
    func questionOpener() {
        #expect(clean("wat is de status van de release")
            == "Wat is de status van de release?")
        #expect(clean("kunnen we dit morgen bespreken")
            == "Kunnen we dit morgen bespreken?")
    }

    @Test("a Dutch tag question ending in hè gains a question mark")
    func tagQuestion() {
        #expect(clean("je komt morgen toch hè") == "Je komt morgen toch hè?")
        #expect(clean("dat werkt niet waar") == "Dat werkt niet waar?")
    }

    @Test("statements and imperatives are left as statements")
    func statementsStayStatements() {
        #expect(clean("ga naar huis en rust uit") == "Ga naar huis en rust uit.")
        #expect(clean("zijn moeder komt morgen langs") == "Zijn moeder komt morgen langs.")
        #expect(clean("ik ga morgen naar de dokter") == "Ik ga morgen naar de dokter.")
    }

    // MARK: - Spoken identifiers

    @Test("apenstaartje and punt build an e-mail address")
    func spokenEmail() {
        #expect(clean("stuur het naar jan apenstaartje voorbeeld punt nl")
            == "Stuur het naar jan@voorbeeld.nl")
    }

    @Test("punt joins a known file extension, and underscore joins an identifier")
    func spokenFileAndIdentifier() {
        #expect(clean("open main punt py en pas de config aan")
            == "Open main.py en pas de config aan.")
        #expect(clean("max underscore retries moet omhoog")
            == "max_retries moet omhoog.")
    }

    @Test("the trigger words stay words in ordinary prose")
    func triggersStayProse() {
        #expect(clean("dat is een goed punt van je") == "Dat is een goed punt van je.")
        #expect(clean("de underscore van het bestand klopt niet")
            == "De underscore van het bestand klopt niet.")
    }

    // MARK: - Embedded English

    @Test("embedded English and identifiers survive untouched")
    func embeddedEnglish() {
        #expect(clean("we gebruiken Docker en Kubernetes in productie")
            == "We gebruiken Docker en Kubernetes in productie.")
        #expect(clean("de fout zit in main.py") == "De fout zit in main.py")
    }

    // MARK: - Terminal

    @Test("terminal dictation stays command-safe")
    func terminalCategory() {
        #expect(clean("git status", category: .terminal) == "git status")
        // No capital, no period, and no prose rules fire.
        #expect(clean("we hebben bijv. koffie nodig", category: .terminal)
            == "we hebben bijv. koffie nodig")
    }

    @Test("spoken flags and paths render in a terminal")
    func terminalSymbols() {
        #expect(clean("git commit streepje m eerste versie", category: .terminal)
            == "git commit -m eerste versie")
        #expect(clean("npm run build streepje streepje verbose", category: .terminal)
            == "npm run build --verbose")
        #expect(clean("cd tilde schuine streep projecten", category: .terminal)
            == "cd ~/projecten")
    }

    @Test("an unrecognized 'schuine streep' phrase is restored, never mangled")
    func slashSentinelRestored() {
        #expect(clean("zet er een schuine streep", category: .terminal)
            == "zet er een schuine streep")
    }
}

@Suite("Cleanup polish — Dutch model output")
struct DutchPolishTests {
    private func polish(_ text: String, category: AppCategory = .general) -> String {
        CleanupPolish.apply(text, options: .default,
                            context: CleanupContext(category: category),
                            locale: "nl-NL")
    }

    @Test("an unpunctuated interrogative gains a capital and a question mark")
    func questionAndCapital() {
        #expect(polish("wat is de status van de release")
            == "Wat is de status van de release?")
    }

    @Test("the pack's orthography rules also repair model output")
    func orthographyRepairs() {
        #expect(polish("Ijsland is prachtig.") == "IJsland is prachtig.")
        #expect(polish("'t is bijna klaar.") == "'t Is bijna klaar.")
        #expect(polish("het kost €15,50.") == "Het kost € 15,50.")
    }

    @Test("model output is never left holding a masking placeholder")
    func noPlaceholderLeak() {
        let out = polish("we hebben bijv. koffie nodig en het kost 21,5 euro.")
        #expect(!out.contains(DutchOrthography.abbreviationDot))
        #expect(!out.contains(DutchOrthography.decimalComma))
        #expect(out.contains("bijv. koffie"))
        #expect(out.contains("21,5"))
    }
}

@Suite("Cleanup sanitizer — Dutch lead-ins")
struct DutchSanitizerTests {
    @Test("a Dutch conversational preamble is stripped")
    func dutchLeadIn() {
        let pack = LanguagePack.dutch
        #expect(CleanupSanitizer.strip("Natuurlijk! Hier is de opgeschoonde tekst: Ik kom morgen langs.",
                                       pack: pack)
            == "Ik kom morgen langs.")
        #expect(CleanupSanitizer.strip("Hier is de opgeschoonde transcriptie: Ik kom morgen langs.",
                                       pack: pack)
            == "Ik kom morgen langs.")
    }

    @Test("ordinary Dutch prose with a colon is left alone")
    func prosePreserved() {
        let pack = LanguagePack.dutch
        let text = "De tekst van de mail: ik kom morgen langs."
        #expect(CleanupSanitizer.strip(text, pack: pack) == text)
    }
}

@Suite("Cleanup prompt — Dutch guidance")
struct DutchPromptTests {
    private var instructions: String {
        CleanupPrompt.instructions(for: .default, context: .general, locale: "nl-NL")
    }

    @Test("the prompt is written for Dutch, with Dutch fillers and capitalization")
    func dutchSubstance() {
        let text = instructions
        #expect(text.contains("Dutch"))
        #expect(text.contains("uhm"))
        #expect(text.contains("IJsland"))
        #expect(text.contains("maandag"))
        // Never English's hesitation examples or pronoun rule.
        #expect(!text.contains("\"um\""))
        #expect(!text.contains("the pronoun \"I\""))
    }

    @Test("terminal guidance replaces the generic instruction")
    func terminalGuidance() {
        let text = CleanupPrompt.instructions(
            for: .default,
            context: CleanupContext(category: .terminal),
            locale: "nl-NL")
        #expect(text.contains("--verbose"))
        #expect(text.contains("~/projecten"))
    }

    @Test("no few-shot examples ship until an eval battery earns them")
    func noFewShot() {
        #expect(LanguagePack.dutch.prompt.fewShot.isEmpty)
        #expect(LanguagePack.dutch.prompt.terminalFewShot.isEmpty)
    }
}
