import Testing
import Foundation
@testable import VoiceTypeKit

/// Everything specific to the Italian pack. Lives beside the other per-language
/// suites so a contributor working on it touches exactly one source directory
/// and one test file — see docs/LOCALIZATION.md.
@Suite("Language pack — Italian policy")
struct ItalianPackPolicyTests {
    @Test("fillers are breath noises only; meaningful interjections are excluded")
    func fillers() {
        let it = LanguagePack.italian
        #expect(it.fillers.contains("ehm"))
        #expect(it.fillers.contains("uhm"))
        #expect(it.fillers.contains("mmm"))
        // Every one of these is a real Italian word or a meaning-bearing
        // interjection, so no blind rule may remove them.
        for word in ["eh", "beh", "boh", "mah", "ah", "allora", "cioè",
                     "diciamo", "tipo", "insomma", "niente", "quindi"] {
            #expect(!it.fillers.contains(word), "\(word)")
        }
        // "mm" is the millimetre, not a hesitation.
        #expect(!it.fillers.contains("mm"))
    }

    @Test("no unconditional spoken-punctuation table: punto and virgola are nouns")
    func noFlatPunctuationTable() {
        #expect(LanguagePack.italian.spokenPunctuation.isEmpty)
    }

    @Test("question openers are interrogative words only — no verbs, no 'che'")
    func questionOpeners() {
        let it = LanguagePack.italian
        #expect(it.questionPrefixWords.contains("cosa"))
        #expect(it.questionPrefixWords.contains("perché"))
        #expect(it.questionPrefixWords.contains("dov'è"))
        // Italian yes/no questions don't invert, so a verb opener would fire on
        // ordinary statements and imperatives.
        for word in ["è", "sono", "hai", "puoi", "vieni", "che"] {
            #expect(!it.questionPrefixWords.contains(word), "\(word)")
        }
    }

    @Test("ships prompt guidance but no few-shot examples")
    func prompt() {
        let prompt = LanguagePack.italian.prompt
        #expect(prompt.fillerExamples != nil)
        #expect(prompt.capitalizationRule != nil)
        #expect(prompt.codeRendering != nil)
        #expect(prompt.terminalGuidance != nil)
        #expect(prompt.codeEditorGuidance != nil)
        #expect(prompt.selfCorrectionRule != nil)
        #expect(prompt.addendum != nil)
        // Examples leak; none ship until an --engine model run earns them.
        #expect(prompt.fewShot.isEmpty)
        #expect(prompt.terminalFewShot.isEmpty)
    }

    @Test("only unaccented spellings that are not themselves words are restored")
    func accentTableIsConservative() {
        let fixes = LanguagePack.italianAccentFixes
        #expect(fixes["perche"] == "perché")
        #expect(fixes["citta"] == "città")
        #expect(fixes["pò"] == "po'")
        // Homographs: the bare spelling is a real word, so only the
        // apostrophe form may be rewritten.
        for word in ["pero", "meta", "papa", "sara", "unita", "necessita",
                     "facilita", "giacche", "li", "la", "si", "ne", "se", "e"] {
            #expect(fixes[word] == nil, "\(word)")
        }
        #expect(fixes["pero'"] == "però")
        #expect(fixes["meta'"] == "metà")
    }
}

@Suite("Rule-based cleanup — Italian")
struct ItalianRuleCleanupTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(text, options: .default,
                                 context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                                 locale: "it-IT")
    }

    // MARK: Fillers

    @Test("breath-noise fillers go, discourse markers stay")
    func fillers() {
        #expect(clean("ehm allora il lancio slitta di una settimana")
            == "Allora il lancio slitta di una settimana.")
        #expect(clean("allora cioe diciamo tipo il punto e' che non lo so")
            == "Allora cioè diciamo tipo il punto è che non lo so.")
        #expect(clean("boh, mah, eh, non saprei") == "Boh, mah, eh, non saprei.")
    }

    // MARK: Accents and apostrophes

    @Test("accents are restored on spellings that exist only accented")
    func accents() {
        #expect(clean("la citta e' bellissima perchè piu tranquilla")
            == "La città è bellissima perché più tranquilla.")
        #expect(clean("E' importante che tu venga") == "È importante che tu venga.")
        #expect(clean("c'e' un problema con il deploy") == "C'è un problema con il deploy.")
        // Elided article: the fix applies to the stem behind the apostrophe.
        #expect(clean("l'universita di Bologna e' la piu antica")
            == "L'università di Bologna è la più antica.")
    }

    @Test("normative apostrophes: pò → po', qual'è → qual è, un'altro → un altro")
    func apostropheNorms() {
        #expect(clean("ci vuole un pò di pazienza") == "Ci vuole un po' di pazienza.")
        #expect(clean("qual'è il problema") == "Qual è il problema?")
        #expect(clean("ho comprato un'altro libro e un'altra rivista")
            == "Ho comprato un altro libro e un'altra rivista.")
    }

    @Test("the space a transcriber leaves after an elision is closed")
    func elisionSpacing() {
        #expect(clean("l' altro giorno ho visto del codice")
            == "L'altro giorno ho visto del codice.")
        #expect(clean("dell' acqua fresca, per favore") == "Dell'acqua fresca, per favore.")
    }

    @Test("troncamento keeps its following space — po', va', fa' are not elisions")
    func troncamento() {
        #expect(clean("abbiamo un po' di tempo, va' pure avanti")
            == "Abbiamo un po' di tempo, va' pure avanti.")
    }

    // MARK: Spoken punctuation

    @Test("compound punctuation names render; bare punto and virgola do not")
    func spokenPunctuation() {
        #expect(clean("sei pronto punto interrogativo") == "Sei pronto?")
        #expect(clean("che disastro punto esclamativo") == "Che disastro!")
        #expect(clean("abbiamo finito il lavoro punto e virgola domani si parte")
            == "Abbiamo finito il lavoro; domani si parte.")
        // The ambiguity policy in action: these stay words.
        #expect(clean("ho segnato due punti nel secondo tempo")
            == "Ho segnato due punti nel secondo tempo.")
        #expect(clean("sposta la virgola di due posizioni")
            == "Sposta la virgola di due posizioni.")
    }

    @Test("brackets and quotation marks are rendered tight against their content")
    func bracketsAndQuotes() {
        #expect(clean("il totale parentesi aperta tasse incluse parentesi chiusa e' di cento euro")
            == "Il totale (tasse incluse) è di cento euro.")
        #expect(clean("ha detto aperte virgolette non lo so chiuse virgolette e se n'e' andato")
            == "Ha detto “non lo so” e se n'è andato.")
        // Caporali the speaker typed themselves are tightened, never rewritten.
        #expect(clean("il testo dice « ciao a tutti » e poi finisce")
            == "Il testo dice «ciao a tutti» e poi finisce.")
    }

    @Test("spoken punctuation is idempotent when the mark is already there")
    func idempotence() {
        #expect(clean("Sei pronto?") == "Sei pronto?")
        #expect(clean("Non so… forse domani.") == "Non so… forse domani.")
        #expect(clean(clean("sei pronto punto interrogativo")) == "Sei pronto?")
    }

    @Test("suspension points survive as a single … instead of collapsing to a full stop")
    func ellipsis() {
        #expect(clean("non so... forse domani") == "Non so… forse domani.")
    }

    @Test("line-break commands render, and their ordinary readings don't")
    func lineBreaks() {
        #expect(clean("titolo a capo contenuto") == "Titolo\ncontenuto.")
        #expect(clean("nuovo paragrafo questo e' il secondo blocco")
            == "Questo è il secondo blocco.")
        #expect(clean("il responsabile a capo del progetto e' Marco")
            == "Il responsabile a capo del progetto è Marco.")
        #expect(clean("abbiamo bisogno di una nuova riga di prodotti")
            == "Abbiamo bisogno di una nuova riga di prodotti.")
    }

    // MARK: Numbers and dates

    @Test("the decimal separator is a comma, and the shared pass can't split it")
    func decimals() {
        #expect(clean("il totale e' 3 virgola 5") == "Il totale è 3,5.")
        #expect(clean("3,14 e' il pi greco") == "3,14 è il pi greco.")
        // An enumeration of numerals is not a decimal.
        #expect(clean("il 5, 6 e 7 maggio siamo chiusi") == "Il 5, 6 e 7 maggio siamo chiusi.")
        // The thousands point is left alone.
        #expect(clean("costa 1.000 euro in tutto") == "Costa 1.000 euro in tutto.")
    }

    @Test("months and weekdays lowercase inside a date, and only there")
    func dateCasing() {
        #expect(clean("la riunione e' il 5 Gennaio 2027") == "La riunione è il 5 gennaio 2027.")
        #expect(clean("il rilascio e' previsto per il 12 Marzo 2027 alle 15:30")
            == "Il rilascio è previsto per il 12 marzo 2027 alle 15:30.")
        // A surname and a named occasion both survive.
        #expect(clean("Marco Di Gennaio ha firmato il contratto")
            == "Marco Di Gennaio ha firmato il contratto.")
        #expect(clean("il Venerdì santo e' festa") == "Il Venerdì santo è festa.")
    }

    // MARK: Code, identifiers, embedded English

    @Test("a spoken file extension joins; the ordinary noun punto does not")
    func fileNames() {
        #expect(clean("apri main punto py") == "Apri main.py")
        #expect(clean("apri il file config punto json e cambia il timeout")
            == "Apri il file config.json e cambia il timeout.")
        #expect(clean("a un certo punto ci siamo fermati")
            == "A un certo punto ci siamo fermati.")
    }

    @Test("identifiers join on trattino basso; prose about a dash does not")
    func identifiers() {
        #expect(clean("chiamalo max trattino basso tentativi") == "Chiamalo max_tentativi")
        #expect(clean("chiamiamolo test trattino basso client trattino basso nuovo")
            == "Chiamiamolo test_client_nuovo")
        #expect(clean("metti un trattino qui") == "Metti un trattino qui.")
    }

    @Test("a dictated address renders; embedded English is left exactly as spoken")
    func emailAndEmbeddedEnglish() {
        #expect(clean("scrivimi a mario punto rossi chiocciola gmail punto com")
            == "Scrivimi a mario.rossi@gmail.com")
        // A path-shaped ending keeps its bare form — no period glued on.
        #expect(clean("ho fatto il commit sul branch feature/login")
            == "Ho fatto il commit sul branch feature/login")
        #expect(clean("guarda il README punto md nel repo")
            == "Guarda il README.md nel repo.")
    }

    // MARK: Question heuristic

    @Test("an interrogative opener with no terminal mark gains a question mark")
    func questions() {
        #expect(clean("come stai") == "Come stai?")
        #expect(clean("quanti sono i partecipanti") == "Quanti sono i partecipanti?")
        #expect(clean("perche non e' ancora pronto") == "Perché non è ancora pronto?")
    }

    @Test("'che' opens exclamations as often as questions, so it never triggers one")
    func cheIsNotAQuestionWord() {
        #expect(clean("che bello vedervi") == "Che bello vedervi.")
    }

    // MARK: Terminal

    @Test("terminal category stays command-safe")
    func terminalCategory() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("npm run build", category: .terminal) == "npm run build")
    }

    @Test("spoken options and paths render only inside a terminal")
    func terminalOptionsAndPaths() {
        #expect(clean("git commit trattino m ciao", category: .terminal) == "git commit -m ciao")
        #expect(clean("git push origin trattino trattino force", category: .terminal)
            == "git push origin --force")
        #expect(clean("cd tilde barra progetti barra voicetype", category: .terminal)
            == "cd ~/progetti/voicetype")
        // Outside a terminal "barra" is a word, so the path rule sits out.
        #expect(clean("la barra laterale e' troppo larga")
            == "La barra laterale è troppo larga.")
    }
}

@Suite("Cleanup polish — Italian model output")
struct ItalianPolishTests {
    private func polish(_ text: String, category: AppCategory = .general) -> String {
        CleanupPolish.apply(text, options: .default,
                            context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                            locale: "it-IT")
    }

    /// The polish path deliberately does not append a terminal period for a
    /// Latin pack — punctuating is the model's job there — so these expect the
    /// orthography to be repaired and nothing else to be invented.
    @Test("Italian orthography holds on model output too, not just on the rules floor")
    func orthographyOnModelOutput() {
        #expect(polish("La citta e' bellissima perchè piu tranquilla")
            == "La città è bellissima perché più tranquilla")
        #expect(polish("ci vuole un pò di pazienza") == "Ci vuole un po' di pazienza")
        #expect(polish("il testo dice « ciao » e finisce") == "Il testo dice «ciao» e finisce")
    }

    @Test("an unpunctuated interrogative gains its mark and a capital")
    func questionAndCapital() {
        #expect(polish("come stai") == "Come stai?")
    }

    @Test("rules sit out the terminal in the polish path as well")
    func terminalUntouched() {
        #expect(polish("git status", category: .terminal) == "git status")
        #expect(polish("cat file.txt", category: .terminal) == "cat file.txt")
    }
}

@Suite("Cleanup sanitizer — Italian lead-ins")
struct ItalianSanitizerTests {
    @Test("an Italian conversational preamble is stripped")
    func leadIn() {
        let out = CleanupSanitizer.strip("Certo, ecco il testo pulito: il lancio slitta.",
                                         pack: .italian)
        #expect(out == "il lancio slitta.")
    }

    @Test("ordinary dictated prose with a colon survives")
    func prosePreserved() {
        let text = "Ecco il piano: comprare il latte e tornare a casa."
        #expect(CleanupSanitizer.strip(text, pack: .italian) == text)
    }
}
