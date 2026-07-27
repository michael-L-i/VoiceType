import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Language pack — Hungarian policy")
struct HungarianPackPolicyTests {
    @Test("only repeated non-lexical hesitations are deterministic fillers")
    func fillers() {
        let hu = LanguagePack.hungarian
        #expect(hu.fillers.contains("ööö"))
        #expect(hu.fillers.contains("őő"))
        #expect(!hu.fillers.contains("ö"))
        #expect(!hu.fillers.contains("ő"))
        #expect(!hu.fillers.contains("hát"))
        #expect(!hu.fillers.contains("izé"))
        #expect(!hu.fillers.contains("szóval"))
        #expect(!hu.fillers.contains("ugye"))
    }

    @Test("uses a local symbol rule without violating the English-only symbols contract")
    func localSymbols() {
        let hu = LanguagePack.hungarian
        #expect(hu.symbols == nil)
        #expect(hu.rules.contains { $0.name.contains("spoken symbols") })
        #expect(hu.spokenSymbolWords.contains("aláhúzásjel"))
        #expect(hu.spokenSymbolWords.contains("kukac"))
    }

    @Test("prompt guidance is complete but deliberately has no unvalidated few-shot")
    func promptPolicy() {
        let prompt = LanguagePack.hungarian.prompt
        #expect(prompt.fillerExamples != nil)
        #expect(prompt.capitalizationRule != nil)
        #expect(prompt.codeRendering != nil)
        #expect(prompt.terminalGuidance != nil)
        #expect(prompt.codeEditorGuidance != nil)
        #expect(prompt.selfCorrectionRule != nil)
        #expect(prompt.addendum != nil)
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }
}

@Suite("Rule-based cleanup — Hungarian")
struct HungarianRuleCleanupTests {
    private func clean(
        _ text: String,
        category: AppCategory = .general,
        options: CleanupOptions = .default
    ) -> String {
        RuleBasedCleanup.process(
            text,
            options: options,
            context: CleanupContext(
                appBundleID: nil, appName: nil, category: category),
            locale: "hu-HU")
    }

    @Test("repeated hesitation sounds are removed without touching ambiguous discourse words")
    func fillers() {
        #expect(clean("ööö, ezt hmm most befejezzük") == "Ezt most befejezzük.")
        #expect(clean("hát ezt izé módon oldjuk meg") == "Hát ezt izé módon oldjuk meg.")
    }

    @Test("single Hungarian letter names survive")
    func singleLetterNames() {
        #expect(clean("ö a magyar ábécé egyik betűje") == "Ö a magyar ábécé egyik betűje.")
        #expect(clean("ő elindult") == "Ő elindult.")
    }

    @Test("strong interrogative openers gain a question mark; statement-shaped questions stay conservative")
    func questions() {
        #expect(clean("miért késik a vonat") == "Miért késik a vonat?")
        #expect(clean("melyik fájlt nyissam meg") == "Melyik fájlt nyissam meg?")
        #expect(clean("elküldöd holnap") == "Elküldöd holnap.")
    }

    @Test("explicit punctuation commands render as whole tokens")
    func punctuationCommands() {
        #expect(clean("miért késik kérdőjel") == "Miért késik?")
        #expect(clean("megjegyzés kettőspont fontos") == "Megjegyzés: fontos.")
        #expect(clean("állj felkiáltójel") == "Állj!")
        #expect(clean("első pontosvessző második") == "Első; második.")
    }

    @Test("punctuation commands are idempotent and inflected symbol nouns stay content")
    func punctuationBoundaries() {
        #expect(clean("miért késik? kérdőjel") == "Miért késik?")
        #expect(clean("írj egy kérdőjelet") == "Írj egy kérdőjelet.")
        #expect(clean("a pont a kör középpontja") == "A pont a kör középpontja.")
        #expect(clean("a vessző vékony ág") == "A vessző vékony ág.")
    }

    @Test("decimal commas remain closed in both rules and model polish")
    func decimalComma() {
        #expect(clean("a pí értéke 3,14") == "A pí értéke 3,14.")
        #expect(
            CleanupPolish.apply(
                "a pí értéke 3,14.",
                options: .default,
                locale: "hu-HU")
            == "A pí értéke 3,14.")
    }

    @Test("measure, currency, temperature, and percent spacing follows Hungarian orthography")
    func numericSpacing() {
        #expect(clean("az ár 2500Ft és 20€") == "Az ár 2500 Ft és 20 €.")
        #expect(clean("a tömeg 25kg és a hőmérséklet 20°C") ==
            "A tömeg 25 kg és a hőmérséklet 20 °C.")
        #expect(clean("a növekedés 5 %") == "A növekedés 5%.")
    }

    @Test("paired prose quotes become Hungarian quotes, while code-editor strings stay ASCII")
    func quotationMarks() {
        #expect(clean(#"Azt mondta: "indulunk"."#) == "Azt mondta: „indulunk”.")
        let code = clean(#""value""#, category: .codeEditor)
        #expect(code.contains(#""value""#))
        #expect(!code.contains("„"))
    }

    @Test("spaces just inside parentheses disappear")
    func parentheses() {
        #expect(clean("ez ( fontos ) rész") == "Ez (fontos) rész.")
    }

    @Test("prose colon gains a following space while time remains compact")
    func colon() {
        #expect(clean("megjegyzés:fontos") == "Megjegyzés: fontos.")
        #expect(clean("a találkozó 10:35-kor kezdődik") ==
            "A találkozó 10:35-kor kezdődik.")
    }

    @Test("date year periods and internal abbreviations do not trigger false capitalization")
    func nonSentencePeriods() {
        #expect(clean("találkozunk 2026. július 26.") ==
            "Találkozunk 2026. július 26.")
        #expect(clean("kb. húsz ember érkezik") == "Kb. húsz ember érkezik.")
        #expect(clean("pl. alma is kell") == "Pl. alma is kell.")
    }

    @Test("three dots survive the shared repeated-punctuation pass as an ellipsis")
    func ellipsis() {
        #expect(clean("talán... mégsem") == "Talán… mégsem.")
        #expect(clean("talán...") == "Talán…")
    }

    @Test("Hungarian letter names render common file extensions")
    func fileExtensions() {
        #expect(clean("nyisd meg a main pont pé ipszilon fájlt") ==
            "Nyisd meg a main.py fájlt.")
        #expect(clean("ellenőrizd az index pont jé es fájlt") ==
            "Ellenőrizd az index.js fájlt.")
        #expect(clean("nyisd meg a config pont dzsézon fájlt") ==
            "Nyisd meg a config.json fájlt.")
    }

    @Test("explicit underscore and email vocabulary render compactly")
    func identifiersAndEmail() {
        #expect(clean("állítsd be a max aláhúzásjel retries értékét") ==
            "Állítsd be a max_retries értékét.")
        #expect(clean("írj a janos pont kovacs kukac gmail pont com címre") ==
            "Írj a janos.kovacs@gmail.com címre.")
    }

    @Test("terminal rendering handles Hungarian flags and paths without prose mutation")
    func terminal() {
        #expect(clean(
            "git commit kötőjel em javítás",
            category: .terminal) == "git commit -m javítás")
        #expect(clean(
            "npm run build kötőjel kötőjel verbose",
            category: .terminal) == "npm run build --verbose")
        #expect(clean(
            "cd tilde perjel projektek perjel VoiceType",
            category: .terminal) == "cd ~/projektek/VoiceType")
        #expect(clean("echo kérdőjel", category: .terminal) == "echo kérdőjel")
    }

    @Test("embedded English and identifiers survive Hungarian prose cleanup")
    func embeddedTechnicalText() {
        #expect(clean("a VoiceType megnyitja a main.py fájlt") ==
            "A VoiceType megnyitja a main.py fájlt.")
        #expect(clean("a getUser értéke változatlan") ==
            "A getUser értéke változatlan.")
    }
}

@Suite("Cleanup polish and prompt — Hungarian")
struct HungarianPolishAndPromptTests {
    @Test("model-output repair runs Hungarian punctuation, quotes, dates, and symbols")
    func polish() {
        #expect(CleanupPolish.apply(
            "miért késik kérdőjel",
            options: .default,
            locale: "hu-HU") == "Miért késik?")
        #expect(CleanupPolish.apply(
            #"azt mondta: "indulunk"."#,
            options: .default,
            locale: "hu-HU") == "Azt mondta: „indulunk”.")
        #expect(CleanupPolish.apply(
            "találkozunk 2026. július 26.",
            options: .default,
            locale: "hu-HU") == "Találkozunk 2026. július 26.")
        #expect(CleanupPolish.apply(
            "nyisd meg a main pont pé ipszilon fájlt.",
            options: .default,
            locale: "hu-HU") == "Nyisd meg a main.py fájlt.")
    }

    @Test("prompt contains Hungarian policy rather than English fallback examples")
    func prompt() {
        let instructions = CleanupPrompt.instructions(
            for: .default,
            context: .general,
            locale: "hu-HU")
        #expect(instructions.contains("öö"))
        #expect(instructions.contains("Hungarian capitalization"))
        #expect(instructions.contains("main pont pé ipszilon"))
        #expect(instructions.contains("öt, nem, hat példány"))
        #expect(instructions.contains("3,14"))
        #expect(!instructions.contains("\"five, no six copies\""))
    }

    @Test("Hungarian conversational model lead-ins are stripped")
    func sanitizerLeadIn() {
        #expect(CleanupSanitizer.strip(
            "Rendben, itt van a javított átirat: Holnap indulunk.",
            locale: "hu-HU") == "Holnap indulunk.")
        #expect(CleanupSanitizer.strip(
            "Itt a megtisztított diktálás: Holnap indulunk.",
            locale: "hu-HU") == "Holnap indulunk.")
    }
}
