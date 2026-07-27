import Testing
import Foundation
@testable import VoiceTypeKit

/// Everything specific to the Portuguese pack. Lives beside the other
/// per-language suites so a contributor working on pt touches exactly one
/// source directory and one test file — see docs/LOCALIZATION.md.
@Suite("Language pack — Portuguese policy")
struct PortuguesePackPolicyTests {
    @Test("only never-content disfluencies are fillers; the discourse markers are not")
    func fillerPolicy() {
        let pt = LanguagePack.portuguese
        #expect(pt.fillers.contains("hum"))
        #expect(pt.fillers.contains("ãh"))
        #expect(pt.fillers.contains("éé"))
        // Marcadores conversacionais: every one of these is also a content
        // word, so judging them needs meaning — that is the LLM's job.
        for marker in ["né", "tipo", "então", "aí", "assim", "sabe", "olha", "ah"] {
            #expect(!pt.fillers.contains(marker), "\(marker)")
        }
        // "é" is the verb "to be"; only the lengthened hesitation is a filler.
        #expect(!pt.fillers.contains("é"))
    }

    @Test("the flat spoken-punctuation table stays empty — Portuguese renders marks through rules")
    func noFlatPunctuationTable() {
        // "ponto", "vírgula", "barra" are everyday nouns and the table
        // replaces unconditionally, so Portuguese opts out of it entirely.
        #expect(LanguagePack.portuguese.spokenPunctuation.isEmpty)
        #expect(!LanguagePack.portuguese.rules.isEmpty)
    }

    @Test("question openers are unambiguous interrogatives only")
    func questionOpeners() {
        let pt = LanguagePack.portuguese
        #expect(pt.questionPrefixWords.contains("cadê"))
        #expect(pt.questionPrefixWords.contains("qual"))
        // "Porque eu quero" is an answer; "Por isso eu vim" is a statement.
        #expect(!pt.questionPrefixWords.contains("porque"))
        #expect(!pt.questionPrefixWords.contains("por"))
        // Portuguese does not accent its interrogatives, so these double as
        // subordinating conjunctions; the verb rule decides them instead.
        for conjunction in ["quando", "como", "onde", "quanto", "quem"] {
            #expect(!pt.questionPrefixWords.contains(conjunction), "\(conjunction)")
        }
        // "né" as a hasSuffix particle would fire on "boné"; a rule does it.
        #expect(pt.questionSuffixParticles.isEmpty)
    }

    @Test("the pack brings its own symbol words rather than inheriting English's")
    func ownVocabulary() {
        let pt = LanguagePack.portuguese
        // Symbol rendering is position-guarded rules, not a flat vocabulary:
        // "ponto"/"barra"/"traço" are everyday nouns, so the trigger word
        // alone can never be enough. See PortugueseSymbols.swift.
        #expect(pt.symbols == nil)
        #expect(pt.rules.contains { $0.name == "pt spoken file extension" })
        #expect(pt.spokenSymbolWords.contains("vírgula"))
        #expect(!pt.spokenSymbolWords.contains("underscore-only-english"))
        #expect(pt.stopwords.contains("de"))
        #expect(!pt.stopwords.contains("deploy"))
        // Portuguese has no one-letter capitalized pronoun: "eu" is lowercase.
        #expect(pt.capitalizedStandalonePronoun == nil)
    }

    @Test("rules are uniquely named, and only the symbol rules opt into the terminal")
    func rulesAreWellFormed() {
        var seen: Set<String> = []
        for rule in LanguagePack.portuguese.rules {
            #expect(rule.name.hasPrefix("pt "), "\(rule.name)")
            #expect(seen.insert(rule.name).inserted, "\(rule.name)")
            // Orthography is prose: a restored circumflex or a "…" inside a
            // shell command is corruption, so every one of those sits out.
            // Only the symbol rules run there, and each needs a spoken trigger
            // word an ordinary command does not contain.
            if rule.runsInTerminal {
                #expect(rule.name.hasPrefix("pt spoken "), "\(rule.name)")
            }
        }
        // The terminal opt-ins must leave a plain command exactly as spoken.
        for command in ["git status", "npm run build", "ls -la"] {
            let out = RuleBasedCleanup.process(command, options: .default,
                                               context: CleanupContext(category: .terminal),
                                               locale: "pt-BR")
            #expect(out == command, "\(command) became \(out)")
        }
    }
}

@Suite("Rule-based cleanup — Portuguese")
struct PortugueseRuleCleanupTests {
    private func clean(_ text: String, category: AppCategory = .general) -> String {
        RuleBasedCleanup.process(text, options: .default,
                                 context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                                 locale: "pt-BR")
    }

    // MARK: Fillers

    @Test("unambiguous fillers are removed, discourse markers are kept")
    func fillers() {
        #expect(clean("hum então eu acho que sim") == "Então eu acho que sim.")
        #expect(clean("eu acho ãh que dá para adiar") == "Eu acho que dá para adiar.")
        #expect(clean("então tipo assim a gente vê depois")
            == "Então tipo assim a gente vê depois.")
    }

    @Test("a filler spelling never eats a real word")
    func fillersAreBounded() {
        #expect(clean("o humor dele mudou") == "O humor dele mudou.")
        #expect(clean("ela chegou hã ontem") == "Ela chegou ontem.")
    }

    // MARK: Spoken punctuation

    @Test("spoken marks with no prose reading render; bare nouns never do")
    func spokenPunctuation() {
        #expect(clean("você vem amanhã ponto de interrogação") == "Você vem amanhã?")
        #expect(clean("isso é ótimo ponto de exclamação") == "Isso é ótimo!")
        #expect(clean("primeiro item ponto e vírgula segundo item")
            == "Primeiro item; segundo item.")
        #expect(clean("eu não sei reticências talvez amanhã")
            == "Eu não sei… talvez amanhã.")
    }

    @Test("spoken punctuation is idempotent when the engine already rendered it")
    func spokenPunctuationIdempotent() {
        #expect(clean("você vem amanhã? ponto de interrogação") == "Você vem amanhã?")
        #expect(clean("isso é ótimo! ponto de exclamação") == "Isso é ótimo!")
    }

    @Test("quotes and braces come from imperatives, which cannot be noun phrases")
    func bracketsAndQuotes() {
        #expect(clean("ele disse abre aspas não vou fecha aspas e saiu")
            == "Ele disse “não vou” e saiu.")
        #expect(clean("use abre chaves nome fecha chaves no template")
            == "Use {nome} no template.")
        #expect(clean("o total abre parênteses sem impostos fecha parênteses subiu")
            == "O total (sem impostos) subiu.")
        #expect(clean("veja a nota abre colchetes três fecha colchetes no rodapé")
            == "Veja a nota [três] no rodapé.")
    }

    @Test("everyday nouns that name a mark stay words")
    func ambiguousNounsKept() {
        #expect(clean("o ponto de vista dele mudou") == "O ponto de vista dele mudou.")
        #expect(clean("esperei no ponto de ônibus") == "Esperei no ponto de ônibus.")
        #expect(clean("temos dois pontos a discutir") == "Temos dois pontos a discutir.")
        #expect(clean("ele disse, entre parênteses, que topa")
            == "Ele disse, entre parênteses, que topa.")
        #expect(clean("isso é um traço de personalidade")
            == "Isso é um traço de personalidade.")
    }

    @Test("spoken line breaks survive the shared whitespace collapse")
    func lineBreaks() {
        #expect(clean("primeiro tópico nova linha segundo tópico")
            == "Primeiro tópico\nsegundo tópico.")
        #expect(clean("fim da introdução novo parágrafo agora os detalhes")
            == "Fim da introdução\n\nagora os detalhes.")
    }

    // MARK: Numbers, currency, ordinals

    @Test("a spoken decimal comma joins the digits and survives the spacing pass")
    func decimalComma() {
        #expect(clean("a taxa subiu para 3 vírgula 5 por cento")
            == "A taxa subiu para 3,5 por cento.")
        // Without digits on both sides there is no unambiguous decimal.
        #expect(clean("ele leu três vírgula catorze") == "Ele leu três vírgula catorze.")
    }

    @Test("a currency symbol is separated from the amount")
    func currencySpacing() {
        #expect(clean("custou R$1200 no total") == "Custou R$ 1200 no total.")
        #expect(clean("são US$40 por mês") == "São US$ 40 por mês.")
    }

    @Test("ordinal indicators replace the bare letter, but a spaced range survives")
    func ordinals() {
        #expect(clean("moro no 3o andar") == "Moro no 3º andar.")
        #expect(clean("a reunião é na 2a sala") == "A reunião é na 2ª sala.")
        #expect(clean("leva de 2 a 3 dias") == "Leva de 2 a 3 dias.")
    }

    // MARK: Questions

    @Test("multi-word interrogative openers the single-token probe cannot see")
    func interrogativeOpeners() {
        #expect(clean("por que o build está quebrado") == "Por que o build está quebrado?")
        #expect(clean("será que ele vai responder hoje") == "Será que ele vai responder hoje?")
        #expect(clean("como é que isso passou na review")
            == "Como é que isso passou na review?")
        #expect(clean("cadê o relatório") == "Cadê o relatório?")
    }

    @Test("an interrogative word plus a finite verb is a question")
    func interrogativeWordPlusVerb() {
        #expect(clean("onde está o arquivo de configuração")
            == "Onde está o arquivo de configuração?")
        #expect(clean("quando é a reunião") == "Quando é a reunião?")
        #expect(clean("quanto custa o plano anual") == "Quanto custa o plano anual?")
        #expect(clean("quem vai revisar o pull request")
            == "Quem vai revisar o pull request?")
        #expect(clean("o que significa esse erro") == "O que significa esse erro?")
    }

    @Test("the same words subordinating a clause stay statements")
    func subordinatingConjunctionsAreStatements() {
        #expect(clean("quando eu era criança eu morava lá")
            == "Quando eu era criança eu morava lá.")
        #expect(clean("como combinado segue o relatório")
            == "Como combinado segue o relatório.")
        #expect(clean("onde eu moro tem café bom") == "Onde eu moro tem café bom.")
        #expect(clean("quanto a isso eu concordo") == "Quanto a isso eu concordo.")
        #expect(clean("quem quiser pode vir na sexta") == "Quem quiser pode vir na sexta.")
        // Past tense: exactly what an adverbial clause opens with.
        #expect(clean("como foi combinado seguimos com o plano")
            == "Como foi combinado seguimos com o plano.")
    }

    @Test("'porque' and 'por' openers are statements, not questions")
    func causalOpenersAreStatements() {
        #expect(clean("porque eu quero terminar hoje") == "Porque eu quero terminar hoje.")
        #expect(clean("por isso eu vim mais cedo") == "Por isso eu vim mais cedo.")
        #expect(clean("por favor me avisa antes") == "Por favor me avisa antes.")
    }

    @Test("the opener rule fires only on a single-sentence dictation")
    func openerNeedsOneSentence() {
        // The trailing period belongs to the second sentence, not the opener.
        #expect(clean("por que isso quebrou? eu não sei")
            == "Por que isso quebrou? Eu não sei.")
    }

    @Test("'né' is a tag question; 'boné' is not")
    func tagQuestion() {
        #expect(clean("isso ficou caro né") == "Isso ficou caro né?")
        #expect(clean("ele comprou um boné") == "Ele comprou um boné.")
        #expect(clean("ela ganhou um carnê novo") == "Ela ganhou um carnê novo.")
    }

    @Test("a stressed 'quê' at the end of a period takes the circumflex")
    func sentenceFinalQue() {
        #expect(clean("você quer fazer isso por que") == "Você quer fazer isso por quê.")
        #expect(clean("ele está reclamando do que") == "Ele está reclamando do quê.")
        // Mid-sentence "que" is unstressed and unaccented.
        #expect(clean("eu acho que ele vem amanhã") == "Eu acho que ele vem amanhã.")
    }

    // MARK: Capitalization

    @Test("months and weekdays are lowercase; sentence starts and toponyms are not")
    func lowercaseDates() {
        #expect(clean("a reunião ficou para Março") == "A reunião ficou para março.")
        #expect(clean("o deploy é na Terça-feira") == "O deploy é na terça-feira.")
        #expect(clean("vou viajar no Sábado") == "Vou viajar no sábado.")
        #expect(clean("o evento é no Rio de Janeiro em Janeiro")
            == "O evento é no Rio de Janeiro em janeiro.")
        // Sentence-initial: the capital is the sentence's, not the month's.
        #expect(clean("Março foi um mês difícil") == "Março foi um mês difícil.")
    }

    // MARK: Code, identifiers, terminal

    @Test("a spoken 'ponto' joins only when the next word names a file extension")
    func fileNames() {
        #expect(clean("abre o arquivo main ponto py e roda")
            == "Abre o arquivo main.py e roda.")
        #expect(clean("o config ponto json está errado") == "O config.json está errado.")
    }

    @Test("identifiers join on the Portuguese trigger word, which is consumed")
    func identifiers() {
        #expect(clean("renomeia para max underline retries") == "Renomeia para max_retries")
        // A function word on either side blocks the join.
        #expect(clean("eu quero underline o texto") == "Eu quero underline o texto.")
    }

    @Test("a spoken email renders on 'arroba', anchored on a real TLD")
    func email() {
        #expect(clean("manda pro pedro ponto silva arroba gmail ponto com")
            == "Manda pro pedro.silva@gmail.com")
        // No TLD, no address: 'arroba' as a unit of weight stays a word.
        #expect(clean("um boi de vinte arrobas") == "Um boi de vinte arrobas.")
    }

    @Test("embedded English technical vocabulary passes through untouched")
    func embeddedEnglish() {
        #expect(clean("o pull request quebrou o build do CI")
            == "O pull request quebrou o build do CI.")
        #expect(clean("dá um git rebase na branch main") == "Dá um git rebase na branch main.")
    }

    @Test("terminal category stays command-safe: no capital, no period, no pack rule")
    func terminalCategory() {
        #expect(clean("git status", category: .terminal) == "git status")
        #expect(clean("git commit traço m corrigir o build", category: .terminal)
            == "git commit -m corrigir o build")
        #expect(clean("cd til barra projetos barra voicetype", category: .terminal)
            == "cd ~/projetos/voicetype")
        // A rule that would fire in prose must not fire here.
        #expect(clean("ls traço traço all", category: .terminal) == "ls --all")
        #expect(clean("por que o build quebrou", category: .terminal) == "por que o build quebrou")
    }
}

@Suite("Cleanup polish — Portuguese model output")
struct PortuguesePolishTests {
    private func polish(_ text: String, category: AppCategory = .general) -> String {
        CleanupPolish.apply(text, options: .default,
                            context: CleanupContext(appBundleID: nil, appName: nil, category: category),
                            locale: "pt-BR")
    }

    @Test("the pack's rules hold on model output too, at the same three stages")
    func rulesApplyToModelOutput() {
        #expect(polish("por que o build está quebrado") == "Por que o build está quebrado?")
        #expect(polish("isso ficou caro né") == "Isso ficou caro né?")
        #expect(polish("a reunião ficou para Março.") == "A reunião ficou para março.")
        #expect(polish("moro no 3o andar.") == "Moro no 3º andar.")
    }

    @Test("full-width punctuation the model drifts into is repaired to ASCII")
    func foreignPunctuationRepaired() {
        #expect(polish("tudo bem。") == "Tudo bem.")
    }

    @Test("terminal output keeps its shape")
    func terminalUntouched() {
        #expect(polish("git status", category: .terminal) == "git status")
    }
}
