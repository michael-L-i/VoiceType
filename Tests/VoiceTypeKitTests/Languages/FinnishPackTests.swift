import Foundation
import Testing
@testable import VoiceTypeKit

@Suite("Language pack — Finnish policy")
struct FinnishPackPolicyTests {
    @Test("only nonlexical hesitation sounds are deterministic fillers")
    func fillersAreConservative() {
        let fi = LanguagePack.finnish
        #expect(fi.fillers.contains("öö"))
        #expect(fi.fillers.contains("ää"))
        #expect(fi.fillers.contains("hmm"))
        for meaningful in ["tota", "tuota", "niinku", "siis", "no", "mhm", "eiku"] {
            #expect(!fi.fillers.contains(meaningful))
        }
    }

    @Test("ambiguous short punctuation nouns are not unconditional replacements")
    func spokenPunctuationIsConservative() {
        let punctuation = LanguagePack.finnish.spokenPunctuation
        #expect(punctuation["kysymysmerkki"] == "?")
        #expect(punctuation["avaa kaarisulku"] == "(")
        #expect(punctuation["piste"] == nil)
        #expect(punctuation["pilkku"] == nil)
        #expect(punctuation["viiva"] == nil)
    }

    @Test("question vocabulary covers Finnish interrogatives and selected ko-kö forms")
    func questionVocabulary() {
        let words = LanguagePack.finnish.questionPrefixWords
        #expect(words.contains("mitä"))
        #expect(words.contains("milloin"))
        #expect(words.contains("onko"))
        #expect(words.contains("eivätkö"))
        #expect(!words.contains("koko"))
        #expect(!words.contains("pakko"))
    }

    @Test("symbol rendering is pack-owned and prompt guidance is complete without few-shot")
    func guidance() {
        let fi = LanguagePack.finnish
        #expect(fi.symbols == nil)
        #expect(fi.prompt.fillerExamples?.contains("tuota") == true)
        #expect(fi.prompt.capitalizationRule?.contains("weekdays") == true)
        #expect(fi.prompt.codeRendering?.contains("main piste py") == true)
        #expect(fi.prompt.terminalGuidance?.contains("viiva viiva verbose") == true)
        #expect(fi.prompt.codeEditorGuidance != nil)
        #expect(fi.prompt.selfCorrectionRule?.contains("eiku") == true)
        #expect(fi.prompt.addendum?.contains("3,14") == true)
        #expect(fi.prompt.fewShot.isEmpty)
        #expect(fi.prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Finnish")
struct FinnishRuleCleanupTests {
    private func clean(
        _ text: String,
        category: AppCategory = .general,
        options: CleanupOptions = .default
    ) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(category: category),
            locale: "fi-FI")
    }

    @Test("pure hesitation sounds are removed but meaningful lookalikes survive")
    func fillers() {
        #expect(clean("öö tämä toimii") == "Tämä toimii.")
        #expect(clean("ää, kokeillaan uudelleen") == "Kokeillaan uudelleen.")
        #expect(clean("tota tämä ja tuota vaihtoehto") == "Tota tämä ja tuota vaihtoehto.")
        #expect(clean("no se toimii siis hyvin") == "No se toimii siis hyvin.")
    }

    @Test("unambiguous spoken punctuation renders and is idempotent")
    func spokenPunctuation() {
        #expect(clean("mitä kuuluu kysymysmerkki") == "Mitä kuuluu?")
        #expect(clean("varo huutomerkki") == "Varo!")
        #expect(clean("otsikko kaksoispiste asia") == "Otsikko: asia.")
        #expect(clean("mitä kuuluu? kysymysmerkki") == "Mitä kuuluu?")
    }

    @Test("Finnish question openers gain a question mark without ko-suffix overreach")
    func questions() {
        #expect(clean("onko tämä valmis") == "Onko tämä valmis?")
        #expect(clean("milloin kokous alkaa") == "Milloin kokous alkaa?")
        #expect(clean("koko suunnitelma toimii") == "Koko suunnitelma toimii.")
        #expect(clean("pakko tämä on tehdä") == "Pakko tämä on tehdä.")
    }

    @Test("Finnish quotation marks and punctuation spacing are repaired in prose")
    func quotationSpacing() {
        #expect(
            clean("hän sanoi aloita lainaus hei lopeta lainaus , sitten lähti")
                == "Hän sanoi ”hei”, sitten lähti.")
        #expect(
            clean("hän kysyi aloita lainaus tuletko lopeta lainaus kysymysmerkki")
                == "Hän kysyi ”tuletko”?"
        )
    }

    @Test("decimal commas stay compact and quantities gain their required space")
    func quantities() {
        #expect(
            clean("hinta on 29,90€ ja osuus 12,5%")
                == "Hinta on 29,90 € ja osuus 12,5 %.")
        #expect(
            clean("lämpötila on 14,6°C ja matka 2,5km")
                == "Lämpötila on 14,6 °C ja matka 2,5 km.")
    }

    @Test("abbreviation periods do not trigger false sentence capitalization or double")
    func abbreviations() {
        #expect(
            clean("esim. tämä toimii ja mm. tuo toimii")
                == "Esim. tämä toimii ja mm. tuo toimii.")
        #expect(clean("luettelossa on kyniä ym.") == "Luettelossa on kyniä ym.")
    }

    @Test("numeric Finnish dates and prose clock times still receive sentence punctuation")
    func datesAndTimes() {
        #expect(clean("kokous on 26.7.2026") == "Kokous on 26.7.2026.")
        #expect(clean("kokous alkaa klo 9.15") == "Kokous alkaa klo 9.15.")
    }

    @Test("Finnish apostrophe is typographic in prose")
    func apostrophe() {
        #expect(clean("raa'an omenan hinta laski") == "Raa’an omenan hinta laski.")
    }

    @Test("explicit line and paragraph commands survive shared whitespace cleanup")
    func lineBreaks() {
        #expect(clean("ensimmäinen uusi rivi toinen") == "Ensimmäinen\ntoinen.")
        #expect(clean("ensimmäinen uusi kappale toinen") == "Ensimmäinen\n\ntoinen.")
    }

    @Test("contextual spoken symbols render files, identifiers, and email")
    func contextualSymbols() {
        #expect(clean("avaa main piste pyy") == "Avaa main.py")
        #expect(
            clean("aseta max alaviiva yritykset viiteen")
                == "Aseta max_yritykset viiteen.")
        #expect(
            clean("osoite on matti piste meikalainen ät esimerkki piste fi")
                == "Osoite on matti.meikalainen@esimerkki.fi")
    }

    @Test("ambiguous symbol nouns remain ordinary Finnish prose")
    func symbolProseGuards() {
        #expect(clean("tässä piste on tärkeä") == "Tässä piste on tärkeä.")
        #expect(clean("piirrä suora viiva tähän") == "Piirrä suora viiva tähän.")
        #expect(clean("lisää pilkkujen määrää") == "Lisää pilkkujen määrää.")
    }

    @Test("terminal dictation renders Finnish flags and paths without prose changes")
    func terminal() {
        #expect(
            clean("npm run build viiva viiva verbose", category: .terminal)
                == "npm run build --verbose")
        #expect(
            clean("cd tilde kauttaviiva projektit kauttaviiva voice", category: .terminal)
                == "cd ~/projektit/voice")
        #expect(
            clean("python script.py viiva n 3,14", category: .terminal)
                == "python script.py -n 3,14")
        #expect(clean("git status", category: .terminal) == "git status")
    }

    @Test("disabled cleanup options do not turn lexical guidance into blind rewriting")
    func optionsRemainScoped() {
        let none = CleanupOptions(
            removeFillers: false,
            addPunctuation: false,
            fixCapitalization: false)
        #expect(clean("tota mä tulen", options: none) == "tota mä tulen")
    }
}

@Suite("Cleanup polish — Finnish model output")
struct FinnishPolishTests {
    @Test("Finnish mechanical rules repair model output too")
    func polishRules() {
        #expect(
            CleanupPolish.apply("hinta on 3,50€", options: .default, locale: "fi-FI")
                == "Hinta on 3,50 €")
        #expect(
            CleanupPolish.apply("avaa main piste pyy", options: .default, locale: "fi-FI")
                == "Avaa main.py")
        #expect(
            CleanupPolish.apply("esim. tämä toimii", options: .default, locale: "fi-FI")
                == "Esim. tämä toimii")
    }

    @Test("Finnish question repair and capitalization apply to model output")
    func question() {
        #expect(
            CleanupPolish.apply("onko tämä valmis", options: .default, locale: "fi-FI")
                == "Onko tämä valmis?")
    }
}

@Suite("Cleanup sanitizer — Finnish model lead-ins")
struct FinnishSanitizerTests {
    @Test("a Finnish cleaned-text preamble is removed but ordinary prose survives")
    func leadIn() {
        #expect(
            CleanupSanitizer.strip(
                "Tässä on siistitty teksti: Kokous alkaa huomenna.",
                locale: "fi-FI")
                == "Kokous alkaa huomenna.")
        #expect(
            CleanupSanitizer.strip(
                "Tässä on suunnitelma: kokous alkaa huomenna.",
                locale: "fi-FI")
                == "Tässä on suunnitelma: kokous alkaa huomenna.")
    }
}
