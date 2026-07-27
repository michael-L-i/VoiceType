import Testing
import Foundation
@testable import VoiceTypeKit

/// Everything specific to the French pack. Lives beside the other per-language
/// suites so a contributor working on fr touches exactly one source directory
/// and one test file — see docs/LOCALIZATION.md.
private let narrow = FrenchTypography.narrowSpace
private let nbsp = FrenchTypography.noBreakSpace

@Suite("Language pack — French policy")
struct FrenchPackPolicyTests {
    @Test("fillers are non-lexical filled pauses only")
    func fillers() {
        let fr = LanguagePack.french
        #expect(fr.fillers.contains("euh"))
        #expect(fr.fillers.contains("hum"))
        // Lexical discourse markers hesitate AND mean something. They belong to
        // the LLM pass, never to a blind rule.
        for marker in ["ben", "bah", "bon", "quoi", "voilà", "hein", "genre", "enfin"] {
            #expect(!fr.fillers.contains(marker), "\(marker) is not a pure disfluency")
        }
    }

    @Test("the flat spoken-punctuation table is unused; rules carry it instead")
    func spokenPunctuationIsRuleBased() {
        #expect(LanguagePack.french.spokenPunctuation.isEmpty)
        #expect(!LanguagePack.french.rules.isEmpty)
    }

    @Test("French has no capitalized standalone pronoun and writes ASCII marks")
    func writingConventions() {
        let fr = LanguagePack.french
        #expect(fr.capitalizedStandalonePronoun == nil)
        #expect(fr.separatesWordsWithSpaces)
        #expect(!fr.usesFullWidthPunctuation)
        #expect(fr.terminalPeriod == ".")
        #expect(fr.questionMark == "?")
    }

    @Test("symbol rendering is driven by the pack's own rule, not the field")
    func symbolRenderingIsRuleDriven() {
        // The field's call site lives in RuleBasedCleanup only; French runs the
        // renderer from `frenchSpokenSymbolRule` so model output is repaired
        // too, and so it is ordered after the "tiret bas" phrase rule.
        #expect(LanguagePack.french.symbols == nil)
        #expect(LanguagePack.french.rules.contains { $0.name == "fr spoken symbols" })
    }

    @Test("the symbol vocabulary keeps single-letter extensions out")
    func symbolVocabulary() {
        let symbols = SpokenSymbolVocabulary.french
        #expect(symbols.dot == ["point"])
        // "point c" / "point h" would fire on prose far more often than on a C
        // header, so French drops the one-letter extensions English keeps.
        #expect(!symbols.fileExtensions.contains("c"))
        #expect(!symbols.fileExtensions.contains("h"))
        // French says "ouvrez LA parenthèse": the adjacent-token renderer can't
        // see the article, so the phrase is a pack rule instead.
        #expect(symbols.openers.isEmpty)
        #expect(symbols.parenNouns.isEmpty)
    }
}

@Suite("Rule-based cleanup — French typography")
struct FrenchTypographyTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(text, options: .default,
                                 context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                                 locale: "fr-FR")
    }

    @Test("a fine no-break space precedes ; ! ?")
    func fineSpace() {
        #expect(clean("bonjour tout le monde!") == "Bonjour tout le monde\(narrow)!")
        #expect(clean("c'est fini; on rentre") == "C’est fini\(narrow); on rentre.")
        #expect(clean("vraiment?") == "Vraiment\(narrow)?")
    }

    @Test("a full no-break space precedes the colon")
    func colonSpace() {
        #expect(clean("voici la liste: du pain") == "Voici la liste\(nbsp): du pain.")
    }

    @Test("the colon rule spares times, URLs and ratios")
    func colonGuards() {
        #expect(clean("le train est à 14:30") == "Le train est à 14:30.")
        #expect(clean("va sur https://exemple.fr") == "Va sur https://exemple.fr")
    }

    @Test("the spacing rules are idempotent — cleaning twice changes nothing")
    func spacingIdempotent() {
        let once = clean("est-ce que tu viens; oui ou non")
        #expect(clean(once) == once)
        #expect(once.contains("\(narrow);"))
    }

    @Test("a question gains its mark, and the appended mark gains its space")
    func questionMark() {
        #expect(clean("pourquoi tu ne réponds pas") == "Pourquoi tu ne réponds pas\(narrow)?")
        #expect(clean("est-ce que tu viens") == "Est-ce que tu viens\(narrow)?")
        #expect(clean("tu viens demain n'est-ce pas") == "Tu viens demain n’est-ce pas\(narrow)?")
        // A plain statement stays a statement.
        #expect(clean("je viens demain") == "Je viens demain.")
    }

    @Test("straight quotes become guillemets carrying their inner space")
    func guillemets() {
        #expect(clean("il a dit \"bonjour\" hier") == "Il a dit «\(nbsp)bonjour\(nbsp)» hier.")
        // Guillemets the transcriber already produced get the spacing too.
        #expect(clean("il a dit «bonjour» hier") == "Il a dit «\(nbsp)bonjour\(nbsp)» hier.")
    }

    @Test("elisions are closed up and take the typographic apostrophe")
    func apostrophes() {
        #expect(clean("j'ai vu l' homme qui parlait") == "J’ai vu l’homme qui parlait.")
        #expect(clean("aujourd'hui c'est lundi") == "Aujourd’hui c’est lundi.")
    }

    @Test("a number keeps a no-break space before its unit")
    func units() {
        #expect(clean("on a gagné 20% de temps") == "On a gagné 20\(nbsp)% de temps.")
        #expect(clean("ça coûte 50€") == "Ça coûte 50\(nbsp)€.")
    }

    @Test("known limitation: the shared spacing pass splits a decimal comma")
    func decimalCommaIsSplit() {
        // Documented in FrenchPack: every rejoin rule we could write would also
        // weld « les pages 10, 25 sont vides » into 10,25. Pinned here so the
        // day someone finds a safe repair, this test tells them what changed.
        #expect(clean("ça coûte 12,50€") == "Ça coûte 12, 50\(nbsp)€.")
    }

    @Test("ordinals, etc. and Mr take their correct French forms")
    func abbreviations() {
        #expect(clean("c'est la 2ème fois") == "C’est la 2e fois.")
        #expect(clean("la 1ère place et la 3ième") == "La 1re place et la 3e.")
        #expect(clean("du pain du lait etc...") == "Du pain du lait etc.")
        #expect(clean("j'ai vu Mr Dupont") == "J’ai vu M. Dupont.")
    }

    @Test("days and months lose the capital English gives them")
    func calendarCasing() {
        #expect(clean("on se voit le 3 Mai prochain") == "On se voit le 3 mai prochain.")
        #expect(clean("il part en Septembre") == "Il part en septembre.")
        #expect(clean("je viens le Lundi") == "Je viens le lundi.")
    }

    @Test("a sentence-initial month and the planet Mars keep their capital")
    func calendarCasingGuards() {
        #expect(clean("Mai est un beau mois") == "Mai est un beau mois.")
        #expect(clean("la planète Mars est rouge") == "La planète Mars est rouge.")
        // A given name is not preceded by a date figure or a preposition.
        #expect(clean("Avril Lavigne chante") == "Avril Lavigne chante.")
    }
}

@Suite("Rule-based cleanup — French fillers and spoken punctuation")
struct FrenchSpokenTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(text, options: .default,
                                 context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                                 locale: "fr-FR")
    }

    @Test("filled pauses are removed at word boundaries")
    func fillers() {
        #expect(clean("euh je pense que c'est bon") == "Je pense que c’est bon.")
        #expect(clean("je pense, euh, que c'est bon") == "Je pense, que c’est bon.")
        // Never inside a word.
        #expect(clean("l'humour est important") == "L’humour est important.")
    }

    @Test("lexical discourse markers are never removed deterministically")
    func ambiguousMarkersKept() {
        let out = clean("bah du coup on fait genre une pause voilà")
        for marker in ["Bah", "du coup", "genre", "voilà"] {
            #expect(out.contains(marker), "\(marker) was removed")
        }
    }

    @Test("spoken punctuation names render as marks")
    func spokenPunctuation() {
        #expect(clean("tu viens demain point d'interrogation") == "Tu viens demain\(narrow)?")
        #expect(clean("c'est génial point d'exclamation") == "C’est génial\(narrow)!")
        #expect(clean("il pleut point-virgule je reste") == "Il pleut\(narrow); je reste.")
        #expect(clean("il faut du pain virgule du lait") == "Il faut du pain, du lait.")
        #expect(clean("écris porte trait d'union manteau") == "Écris porte-manteau.")
        #expect(clean("et cetera points de suspension") == "Et cetera…")
    }

    @Test("spoken punctuation is idempotent when the engine already rendered it")
    func spokenPunctuationIdempotent() {
        #expect(clean("tu viens demain ? point d'interrogation") == "Tu viens demain\(narrow)?")
    }

    @Test("a determiner turns the name back into the noun it is")
    func determinerGuard() {
        #expect(clean("mets une virgule ici") == "Mets une virgule ici.")
        #expect(clean("il manque un point d'interrogation") == "Il manque un point d’interrogation.")
        #expect(clean("mets un trait d'union entre les deux")
                    == "Mets un trait d’union entre les deux.")
    }

    @Test("a virgule between numbers stays a decimal point")
    func numberGuard() {
        #expect(clean("la valeur est trois virgule quatorze")
                    == "La valeur est trois virgule quatorze.")
        #expect(clean("la valeur est 3 virgule 14") == "La valeur est 3 virgule 14.")
    }

    @Test("spoken parentheses and guillemets render as pairs")
    func pairs() {
        #expect(clean("le résultat ouvrez la parenthèse presque fermez la parenthèse est bon")
                    == "Le résultat (presque) est bon.")
        #expect(clean("il a dit ouvrez les guillemets bonjour fermez les guillemets")
                    == "Il a dit «\(nbsp)bonjour\(nbsp)».")
    }

    @Test("spoken paragraph commands break the line and capitalize what follows")
    func paragraphs() {
        #expect(clean("premier sujet nouveau paragraphe deuxième sujet")
                    == "Premier sujet\n\nDeuxième sujet.")
        #expect(clean("premier sujet à la ligne deuxième sujet")
                    == "Premier sujet\nDeuxième sujet.")
    }

    @Test("the paragraph commands keep their noun readings")
    func paragraphGuards() {
        #expect(clean("ils ont lancé une nouvelle ligne de produits")
                    == "Ils ont lancé une nouvelle ligne de produits.")
        #expect(clean("corrige à la ligne 42 du fichier") == "Corrige à la ligne 42 du fichier.")
        #expect(clean("va à la ligne de commande") == "Va à la ligne de commande.")
    }
}

@Suite("Rule-based cleanup — French code and identifiers")
struct FrenchCodeTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(text, options: .default,
                                 context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                                 locale: "fr-FR")
    }

    @Test("a spoken file name renders in the zero-latency path")
    func fileNames() {
        #expect(clean("ouvre main point py et regarde") == "Ouvre main.py et regarde.")
        #expect(clean("le fichier index point j s est cassé")
                    == "Le fichier index.js est cassé.")
    }

    @Test("\"point\" inside ordinary prose stays a word")
    func pointStaysProse() {
        #expect(clean("je ne partage pas ton point de vue")
                    == "Je ne partage pas ton point de vue.")
        #expect(clean("c'est un bon point pour toi") == "C’est un bon point pour toi.")
        #expect(clean("à quel point c'est grave") == "À quel point c’est grave.")
    }

    @Test("spoken identifiers join and keep their bare ending")
    func identifiers() {
        #expect(clean("renomme la variable max tiret bas retries")
                    == "Renomme la variable max_retries")
    }

    @Test("a spoken e-mail address renders, accented capital included")
    func email() {
        #expect(clean("écris à jean point dupont arobase gmail point com")
                    == "Écris à jean.dupont@gmail.com")
    }

    @Test("embedded English and identifiers survive untouched")
    func embeddedEnglish() {
        #expect(clean("il faut relancer le build sur GitHub")
                    == "Il faut relancer le build sur GitHub.")
        #expect(clean("le fichier config.json est vide") == "Le fichier config.json est vide.")
    }
}

@Suite("Rule-based cleanup — French app categories")
struct FrenchCategoryTests {
    private func clean(_ text: String, category: AppCategory) -> String {
        RuleBasedCleanup.process(text, options: .default,
                                 context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                                 locale: "fr-FR")
    }

    @Test("the terminal category stays command-safe")
    func terminalIsSafe() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("npm run build tiret tiret verbose", category: .terminal)
                    == "npm run build --verbose")
        #expect(clean("cd tilde slash projets", category: .terminal) == "cd ~/projets")
        // No French spacing, no capital, no terminal period on a command.
        #expect(clean("rm tiret r f build; echo fini", category: .terminal)
                    == "rm -r f build; echo fini")
    }

    @Test("\"tiret bas\" opts into the terminal, where it is the only reading")
    func underscoreInTerminal() {
        #expect(clean("export max tiret bas retries égal 5", category: .terminal)
                    == "export max_retries égal 5")
    }

    @Test("French typography sits out the code editor, where it would corrupt code")
    func codeEditorIsSafe() {
        #expect(clean("corrige la ligne timeout: 30 c'est urgent", category: .codeEditor)
                    == "Corrige la ligne timeout: 30 c'est urgent.")
    }
}

@Suite("Cleanup polish — French model output")
struct FrenchPolishTests {
    private func polish(_ text: String, category: AppCategory = .general) -> String {
        CleanupPolish.apply(text, options: .default,
                            context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                            locale: "fr-FR")
    }

    @Test("model output gains the French spacing it never produces reliably")
    func spacing() {
        #expect(polish("Bonjour tout le monde!") == "Bonjour tout le monde\(narrow)!")
        #expect(polish("Voici la liste: du pain.") == "Voici la liste\(nbsp): du pain.")
        // A breaking space the model DID write becomes the non-breaking one.
        #expect(polish("Vraiment ?") == "Vraiment\(narrow)?")
    }

    @Test("full-width marks the model drifts into are repaired, then spaced")
    func fullWidthDrift() {
        #expect(polish("C’est fini！") == "C’est fini\(narrow)!")
    }

    @Test("a sentence opening on an elision is capitalized despite its apostrophe")
    func elidedOpening() {
        // The shared capitalizer only accepts letters and ASCII "'", so a model
        // that already wrote the typographic apostrophe got no capital at all —
        // and half of French sentences open on an elision.
        #expect(polish("j’ai relu le document.") == "J’ai relu le document.")
        #expect(polish("l’équipe est prête.") == "L’équipe est prête.")
        // A leading file name still keeps its case.
        #expect(polish("main.py est cassé.") == "main.py est cassé.")
    }

    @Test("spoken names the model left as words are rendered in polish too")
    func spokenNames() {
        #expect(polish("Tu viens demain point d'interrogation") == "Tu viens demain\(narrow)?")
        #expect(polish("C'est la 2ème fois.") == "C’est la 2e fois.")
    }

    @Test("polish leaves a terminal command alone")
    func terminal() {
        #expect(polish("git status", category: .terminal) == "git status")
    }
}

@Suite("Cleanup sanitizer — French lead-ins")
struct FrenchSanitizerTests {
    @Test("a French conversational lead-in is stripped")
    func leadIn() {
        #expect(CleanupSanitizer.strip("Bien sûr, voici le texte nettoyé : Bonjour à tous.",
                                       locale: "fr-FR") == "Bonjour à tous.")
        #expect(CleanupSanitizer.strip("Voici la transcription corrigée : Il faut partir.",
                                       locale: "fr-FR") == "Il faut partir.")
    }

    @Test("ordinary French prose containing a colon is left alone")
    func prosePreserved() {
        let prose = "Voici mon plan : acheter du lait et rentrer."
        #expect(CleanupSanitizer.strip(prose, locale: "fr-FR") == prose)
    }
}
