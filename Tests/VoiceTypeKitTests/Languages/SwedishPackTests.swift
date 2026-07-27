import Testing
import Foundation
@testable import VoiceTypeKit

/// Everything specific to the Swedish pack. Lives beside the other
/// per-language suites so a contributor working on sv touches exactly one
/// source directory and one test file — see docs/LOCALIZATION.md.
@Suite("Language pack — Swedish policy")
struct SwedishPackPolicyTests {
    @Test("fillers are hesitation vowels only; meaning-bearing lookalikes stay out")
    func fillers() {
        let sv = LanguagePack.swedish
        #expect(sv.fillers.contains("öh"))
        #expect(sv.fillers.contains("hmm"))
        // Every one of these can be content, so none of them is a blind filler.
        for word in ["liksom", "typ", "alltså", "ju", "väl", "nog", "då", "va", "äh", "mm"] {
            #expect(!sv.fillers.contains(word), "\(word)")
        }
    }

    @Test("no spoken-punctuation table: Swedish renders names positionally instead")
    func noFlatPunctuationTable() {
        // "punkt" and "komma" are everyday words; the flat table replaces
        // unconditionally, so Swedish opts out of it entirely.
        #expect(LanguagePack.swedish.spokenPunctuation.isEmpty)
    }

    @Test("question openers exclude the verbs whose imperative is spelled the same")
    func questionOpeners() {
        let sv = LanguagePack.swedish
        #expect(sv.questionPrefixWords.contains("vad"))
        #expect(sv.questionPrefixWords.contains("är"))
        #expect(sv.questionPrefixWords.contains("kan"))
        // "Gör det nu!" and "Kom hit!" are commands, and "Var snäll!" is a
        // request — none of them may collect a question mark.
        for word in ["gör", "kom", "var", "se", "gå", "ta"] {
            #expect(!sv.questionPrefixWords.contains(word), "\(word)")
        }
    }

    @Test("owns its stopwords and its spoken-symbol words rather than English's")
    func lexicons() {
        let sv = LanguagePack.swedish
        #expect(sv.stopwords.contains("och"))
        #expect(sv.stopwords.contains("förlåt"))
        #expect(!sv.stopwords.contains("deploy"))
        #expect(sv.spokenSymbolWords.contains("understreck"))
        #expect(!sv.spokenSymbolWords.contains("underscore"))
    }

    @Test("every rule is named, and the pack's lead-in patterns compile")
    func ruleHygiene() {
        #expect(!LanguagePack.swedish.rules.isEmpty)
        for pattern in LanguagePack.swedish.modelLeadInPatterns {
            #expect((try? NSRegularExpression(pattern: pattern)) != nil, "\(pattern)")
        }
    }
}

@Suite("Rule-based cleanup — Swedish")
struct SwedishRuleCleanupTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(text, options: .default,
                                 context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                                 locale: "sv-SE")
    }

    // MARK: Fillers

    @Test("hesitation vowels are removed, ambiguous discourse words are not")
    func fillers() {
        #expect(clean("eh vi ses på måndag") == "Vi ses på måndag.")
        #expect(clean("jag tror öhm att det stämmer") == "Jag tror att det stämmer.")
        // liksom / typ / ju / alltså are meaning-bearing: the rules floor keeps
        // them and the LLM pass decides.
        #expect(clean("alltså jag menar ju att typ hälften är klar")
            == "Alltså jag menar ju att typ hälften är klar.")
    }

    @Test("mm survives, because it is also the unit millimetre")
    func millimetres() {
        #expect(clean("vi har 5 mm marginal kvar") == "Vi har 5 mm marginal kvar.")
    }

    // MARK: Spoken punctuation

    @Test("unambiguous mark names render and the following sentence capitalizes")
    func unambiguousMarks() {
        #expect(clean("är du klar frågetecken vi måste gå utropstecken")
            == "Är du klar? Vi måste gå!")
        #expect(clean("kommer du imorgon frågetecken") == "Kommer du imorgon?")
    }

    @Test("citattecken renders the Swedish ” at both ends of the quote")
    func quotationMarks() {
        #expect(clean("han sa citattecken det är klart citattecken igår")
            == "Han sa ”det är klart” igår.")
    }

    @Test("a line break renders and the next sentence capitalizes")
    func lineBreak() {
        #expect(clean("första punkten ny rad andra punkten")
            == "Första punkten\nAndra punkten.")
    }

    @Test("bindestreck joins two content words but never a function word")
    func hyphen() {
        #expect(clean("vi skriver ett svensk bindestreck engelskt lexikon")
            == "Vi skriver ett svensk-engelskt lexikon.")
        #expect(clean("sätt ett bindestreck där") == "Sätt ett bindestreck där.")
    }

    // MARK: "punkt" — the positional period

    @Test("punkt renders a period where the noun reading is impossible")
    func punktAsPeriod() {
        #expect(clean("det var allt punkt tack för idag") == "Det var allt. Tack för idag.")
        #expect(clean("vi är klara punkt nu kör vi") == "Vi är klara. Nu kör vi.")
    }

    @Test("punkt stays a noun after a determiner, a preposition, or before a numeral")
    func punktAsNoun() {
        #expect(clean("han har en svag punkt") == "Han har en svag punkt.")
        #expect(clean("vi glömde en punkt") == "Vi glömde en punkt.")
        #expect(clean("vi tar punkt tre först") == "Vi tar punkt tre först.")
        #expect(clean("vi går igenom det punkt för punkt")
            == "Vi går igenom det punkt för punkt.")
    }

    @Test("a mark the transcriber already emitted is absorbed, not doubled")
    func idempotentPeriod() {
        #expect(clean("det var bra. punkt") == "Det var bra.")
    }

    // MARK: Numbers and typography

    @Test("Swedish sets a space between a figure and % or °")
    func symbolSpacing() {
        #expect(clean("öka gränsen till 50 procenttecken") == "Öka gränsen till 50 %.")
        #expect(clean("andelen ökade till 12,5% i år") == "Andelen ökade till 12,5 % i år.")
        #expect(clean("temperaturen är 20°C ute") == "Temperaturen är 20 °C ute.")
    }

    @Test("the decimal comma survives the shared spacing pass; an enumeration is untouched")
    func decimalComma() {
        #expect(clean("det kostar 3,14 kronor") == "Det kostar 3,14 kronor.")
        #expect(clean("vi köpte för 1 500,50 kronor") == "Vi köpte för 1 500,50 kronor.")
        // Already spaced in the transcript → a list of numbers, left alone.
        #expect(clean("se kapitel 3, 4 och 5") == "Se kapitel 3, 4 och 5.")
    }

    @Test("English curly quotes become the Swedish ”")
    func curlyQuotes() {
        #expect(clean("han sa \u{201C}hej\u{201D} till mig") == "Han sa ”hej” till mig.")
    }

    // MARK: Capitalization

    @Test("weekdays and months keep a lowercase initial mid-sentence")
    func calendarCase() {
        #expect(clean("mötet är på Fredag i Juli") == "Mötet är på fredag i juli.")
        #expect(clean("det står i rapporten från Onsdagen")
            == "Det står i rapporten från onsdagen.")
        // A compound keeps its capital: the boundary after the inflection fails.
        #expect(clean("vi hade Fredagsmys igår") == "Vi hade Fredagsmys igår.")
    }

    @Test("an abbreviation's period does not start a sentence")
    func abbreviations() {
        #expect(clean("vi behöver t.ex. det andra alternativet")
            == "Vi behöver t.ex. det andra alternativet.")
        #expect(clean("vi diskuterade budget osv. och sedan gick vi")
            == "Vi diskuterade budget osv. och sedan gick vi.")
    }

    @Test("the repair after an abbreviation can never lowercase a name")
    func abbreviationsSpareNames() {
        #expect(clean("jag tar med bl.a. Anna och Erik")
            == "Jag tar med bl.a. Anna och Erik.")
    }

    // MARK: Questions

    @Test("interrogatives and inverted verbs gain a question mark")
    func questions() {
        #expect(clean("vad heter filen") == "Vad heter filen?")
        #expect(clean("kan du kolla det") == "Kan du kolla det?")
        #expect(clean("hur mycket kostar det") == "Hur mycket kostar det?")
        #expect(clean("är det här rätt") == "Är det här rätt?")
    }

    @Test("\"var\" is a question only when a finite verb follows it")
    func whereQuestion() {
        #expect(clean("var ligger filen") == "Var ligger filen?")
        #expect(clean("var är mina nycklar") == "Var är mina nycklar?")
        // Imperative, past tense and the quantifier must all stay statements.
        #expect(clean("var snäll och skicka rapporten") == "Var snäll och skicka rapporten.")
        #expect(clean("var och en får bestämma själv") == "Var och en får bestämma själv.")
    }

    @Test("a command whose imperative matches the present tense stays a statement")
    func imperativesAreNotQuestions() {
        #expect(clean("gör det nu") == "Gör det nu.")
    }

    // MARK: Code, identifiers and embedded English

    @Test("spoken file names and identifiers render compactly")
    func spokenSymbols() {
        #expect(clean("spara det som main punkt paj") == "Spara det som main.py")
        #expect(clean("filen heter config punkt json och den ligger i roten")
            == "Filen heter config.json och den ligger i roten.")
        #expect(clean("max understreck försök är satt till fem")
            == "max_försök är satt till fem.")
    }

    @Test("a spoken email address renders, with the Swedish snabel-a")
    func email() {
        #expect(clean("skicka till anna punkt svensson snabel-a exempel punkt se")
            == "Skicka till anna.svensson@exempel.se")
    }

    @Test("embedded English and version numbers survive untouched")
    func embeddedEnglish() {
        #expect(clean("kolla version 2.5.1 av paketet") == "Kolla version 2.5.1 av paketet.")
        #expect(clean("vi kör npm run build lokalt") == "Vi kör npm run build lokalt.")
    }

    // MARK: Terminal

    @Test("terminal category stays command-safe")
    func terminalCategory() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("vi behöver t.ex. det andra", category: .terminal)
            == "vi behöver t.ex. det andra")
    }

    @Test("spoken flags and paths render in a terminal")
    func terminalFlags() {
        #expect(clean("git commit streck m fixar buggen", category: .terminal)
            == "git commit -m fixar buggen")
        #expect(clean("kör npm run build streck streck watch", category: .terminal)
            == "kör npm run build --watch")
        #expect(clean("cd tilde snedstreck projekt snedstreck voicetype", category: .terminal)
            == "cd ~/projekt/voicetype")
    }

    @Test("\"streck\" stays a noun outside the terminal")
    func strokeIsANounInProse() {
        #expect(clean("drar ett streck i sanden") == "Drar ett streck i sanden.")
    }
}

/// The pack's rules run in the model path too, which is the point of declaring
/// them as `CleanupRule`s rather than filling in `LanguagePack.symbols`: the
/// shared symbol pipeline never ran over model output before.
@Suite("Cleanup polish — Swedish model output")
struct SwedishPolishTests {
    private func polish(_ text: String, category: AppCategory = .general) -> String {
        CleanupPolish.apply(text, options: .default,
                            context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                            locale: "sv-SE")
    }

    /// The polish path deliberately does not append terminal punctuation for a
    /// Latin pack — the model already punctuates — so these expectations end
    /// where the model's own sentence ended.
    @Test("Swedish orthography is repaired in model output as well")
    func orthography() {
        #expect(polish("andelen ökade till 12,5% i år") == "Andelen ökade till 12,5 % i år")
        #expect(polish("han sa \u{201C}hej\u{201D} till mig.") == "Han sa ”hej” till mig.")
        #expect(polish("mötet är på Fredag i Juli.") == "Mötet är på fredag i juli.")
        #expect(polish("vi behöver t.ex. Det andra.") == "Vi behöver t.ex. det andra.")
    }

    @Test("spoken symbols the model left as words are rendered")
    func spokenSymbols() {
        #expect(polish("spara det som main punkt paj") == "Spara det som main.py")
    }

    @Test("an unpunctuated inverted question gains a Swedish question mark")
    func question() {
        #expect(polish("kan du kolla det") == "Kan du kolla det?")
    }

    @Test("the positional period rule holds in the model path too")
    func positionalPeriod() {
        #expect(polish("det var allt punkt tack för idag") == "Det var allt. Tack för idag")
        #expect(polish("han har en svag punkt.") == "Han har en svag punkt.")
    }

    @Test("a terminal command is left exactly as the model produced it")
    func terminalUntouched() {
        #expect(polish("git status", category: .terminal) == "git status")
    }
}

@Suite("Model lead-in stripping — Swedish")
struct SwedishSanitizerTests {
    @Test("a Swedish conversational preamble is stripped")
    func swedishLeadIn() {
        let stripped = CleanupSanitizer.strip(
            "Här är den rensade texten: Vi ses på måndag.", locale: "sv-SE")
        #expect(stripped == "Vi ses på måndag.")
    }

    @Test("ordinary dictation that merely contains a colon survives")
    func plainDictationKept() {
        let text = "Här är min plan: köpa mjölk och bröd."
        #expect(CleanupSanitizer.strip(text, locale: "sv-SE") == text)
    }
}
