import Foundation

extension LanguagePack {
    /// Portuguese (Brazilian conventions; keyed on "pt", so pt-PT dictation
    /// gets it too). Orthography follows the Acordo Ortográfico da Língua
    /// Portuguesa de 1990, which both varieties share.
    ///
    /// Ambiguity policy — what this pack deliberately does NOT do:
    ///
    /// - **"né", "tipo", "então", "aí", "assim", "sabe", "olha", "quer dizer"
    ///   are not fillers.** They are *marcadores conversacionais*: they do
    ///   real work in speech and every one of them is also a content word
    ///   ("aí" = there/then, "então" = so, "tipo" = kind, "sabe" = knows,
    ///   "olha" = look). Deciding needs meaning, so it is the LLM's job — the
    ///   prompt names them explicitly. Only lengthened hesitation vowels and
    ///   nasal grunts are removed blindly. "ah" and "aham" stay too: they are
    ///   interjections that carry attitude and agreement.
    ///
    /// - **Bare "ponto", "vírgula", "dois pontos", "barra", "traço",
    ///   "asterisco" never render as marks.** Each is an everyday Portuguese
    ///   noun ("ponto de vista", "ponto de ônibus", "chegou em ponto", "dois
    ///   pontos da pauta", "a barra do bar", "traço de personalidade"), and
    ///   `spokenPunctuation` replaces unconditionally. It therefore stays
    ///   empty; what ships instead is a `CleanupRule` that renders only names
    ///   with no ordinary-prose reading, plus the position-guarded symbol
    ///   rules in `PortugueseSymbols.swift`, which join a "ponto" only when
    ///   the next word is a real file extension.
    ///
    /// - **"porque" and "por" were removed from the question openers.** They
    ///   were actively wrong: "Porque eu quero" is an *answer*, and "Por isso
    ///   eu vim" / "Por favor me avisa" are statements. The interrogative
    ///   "por que" is two words, which the single-token probe cannot see, so a
    ///   `.final` rule handles it (and "será que", "cadê", "como é que"…).
    ///
    /// - **"quando", "como", "onde", "quanto", "quem" are not question
    ///   openers either.** Spanish accents its interrogatives ("cuándo" vs
    ///   "cuando"); Portuguese does not, so the same spelling subordinates a
    ///   clause: "Quando eu era criança…", "Como combinado…", "Onde eu moro…",
    ///   "Quanto a isso…", "Quem quiser…". They get a question mark only when
    ///   a finite verb follows them, which is the rule below. The known miss
    ///   is a pronoun in between ("Como você fez isso"), which stays a
    ///   statement — a missing "?" is cosmetic, a wrong one changes how the
    ///   sentence reads.
    ///
    /// - **Thousands separators and percent spacing are left alone.** The norms
    ///   genuinely conflict: the CGPM/INMETRO metrological rule is a thin space
    ///   (24 000), everyday Brazilian usage is a point (24.000), and PT-PT and
    ///   PT-BR disagree on `50 %` vs `50%`. A rule that is right in one
    ///   register is wrong in another, so neither ships.
    ///
    /// - **Enclitic hyphens ("diga-me", "fazê-lo") and the crase (à/às) are
    ///   prompt-only.** Both need to know what part of speech a word is; a
    ///   blind regex would hyphenate every "me"/"se"/"o" it saw.
    static let portuguese = LanguagePack(
        code: "pt",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Pure disfluencies: lengthened vowels and nasal grunts, plus the
        // unaccented spellings transcribers produce for them. Nothing here is
        // a Portuguese word.
        fillers: [
            "hum", "humm", "hmm", "hmmm", "ahn", "ahm", "ãh", "ãhn", "hã",
            "ehm", "uhm", "uhn", "éé", "ééé", "mmm",
        ],
        // Empty by design — see the ambiguity note above. Portuguese renders
        // spoken punctuation through its own rules instead.
        spokenPunctuation: [:],
        // Interrogative words only, and only the ones that cannot also
        // subordinate a clause. Portuguese does not accent its interrogatives
        // the way Spanish does ("cuándo" vs "cuando"), so "quando", "como",
        // "onde" and "quanto" are spelled identically as conjunctions —
        // "Quando eu era criança…", "Como combinado…", "Onde eu moro…",
        // "Quanto a isso…", "Quem quiser pode vir…" are all statements. They
        // are handled by the interrogative-word-plus-verb rule below instead,
        // which can see enough of the sentence to tell the two apart.
        questionPrefixWords: [
            "quê", "qual", "quais", "quantos", "quantas", "cadê", "cade",
        ],
        // Left empty deliberately. The obvious candidate is the tag "né", but
        // particles are matched with `hasSuffix` and no word boundary, so "né"
        // would fire on "boné". The `.final` rule below does it properly.
        questionSuffixParticles: [],
        stopwords: LanguagePack.portugueseStopwords,
        prompt: .portuguese,
        rules: LanguagePack.portugueseSymbolRules + LanguagePack.portugueseRules,
        spokenSymbolWords: LanguagePack.portugueseSymbolWords,
        modelLeadInPatterns: [
            // "Claro, aqui está o texto limpo:", "Beleza! Segue a versão corrigida:"
            #"(?i)^\s*(?:claro|certo|ok|okay|tudo bem|com certeza|perfeito|beleza|pronto)[,!.]+\s*(?:aqui (?:est[áa]|vai|tem)\b|segue\b)?[^\n:]{0,80}:\s+"#,
            // "Aqui está a transcrição corrigida:", "Segue o texto limpo:"
            #"(?i)^\s*(?:aqui (?:est[áa]|vai|tem)\b|segue\b|a\b|o\b)?[^\n:]{0,60}(?:transcri[çc][ãa]o|dita[çc][ãa]o|texto (?:limpo|corrigido|revisado)|vers[ãa]o (?:limpa|corrigida|revisada))[^\n:]{0,30}:\s+"#,
        ])

    // MARK: - Stopwords

    /// Function words too common to prove anything about whether the opening of
    /// a dictation survived, and too common to be joined into a dictated
    /// identifier ("o token de sessão" must never become "o_token"). Declared
    /// separately so it can be read before `LanguagePack.portuguese` itself
    /// finishes initializing; `PortugueseText.joinGuard` is its regex-shaped
    /// subset, used by the symbol rules.
    static let portugueseStopwords: Set<String> = [
        // Artigos e contrações
        "o", "a", "os", "as", "um", "uma", "uns", "umas",
        "de", "do", "da", "dos", "das", "dum", "duma",
        "em", "no", "na", "nos", "nas", "num", "numa",
        "por", "pelo", "pela", "pelos", "pelas",
        "para", "pra", "pro", "ao", "aos", "à", "às",
        "com", "sem", "sob", "sobre", "até", "desde", "entre", "após", "contra",
        // Conjunções
        "e", "ou", "mas", "que", "se", "como", "quando", "porque", "então",
        "pois", "nem", "porém", "logo", "assim",
        // Pronomes
        "eu", "tu", "você", "vocês", "ele", "ela", "eles", "elas", "nós",
        "me", "te", "lhe", "lhes", "nos", "vos",
        "meu", "minha", "meus", "minhas", "seu", "sua", "seus", "suas",
        "nosso", "nossa", "dele", "dela",
        "isso", "isto", "aquilo", "esse", "essa", "este", "esta",
        "aquele", "aquela", "esses", "essas", "estes", "estas",
        // Verbos de altíssima frequência
        "é", "são", "era", "eram", "foi", "foram", "ser", "está", "estão",
        "estava", "estar", "tem", "têm", "tinha", "ter", "há", "vai", "vou",
        "vamos", "ficou", "fica",
        // Advérbios e marcadores
        "aqui", "ali", "lá", "já", "ainda", "também", "muito", "mais", "menos",
        "bem", "só", "agora", "depois", "antes", "sempre", "nunca", "talvez",
        // Marcadores de autocorreção: removidos junto com o que retificam, logo
        // não provam nada sobre a abertura da fala.
        "não", "opa", "desculpa", "quer", "dizer", "melhor", "digo", "aliás",
        "tipo", "né", "tá", "ok", "sim", "certo", "olha",
    ]

    // MARK: - Spoken symbol words

    /// Words that name a symbol out loud in Portuguese and legitimately
    /// collapse into one character during cleanup. The faithfulness guard
    /// discounts them when counting content, so a heavily dictated identifier
    /// ("main ponto py") does not read as a summary. Replaces the English
    /// default, which named none of these.
    static let portugueseSymbolWords: Set<String> = [
        "ponto", "pontos", "vírgula", "virgula", "traço", "traco", "hífen",
        "hifen", "barra", "invertida", "til", "arroba", "underline",
        "underscore", "sublinhado", "parêntese", "parênteses", "parentese",
        "parenteses", "colchete", "colchetes", "chave", "chaves", "aspas",
        "abre", "abrir", "abra", "fecha", "fechar", "feche", "asterisco",
        "cifrão", "cifrao", "cerquilha", "interrogação", "interrogacao",
        "exclamação", "exclamacao", "reticências", "reticencias", "crase",
        "maiúscula", "maiuscula", "minúscula", "minuscula", "parágrafo",
        "paragrafo", "linha", "espaço", "espaco", "tabulação", "igual",
    ]

    // MARK: - Rules

    /// Portuguese's own deterministic fixes. Everything here is an orthographic
    /// convention that is *always* right in Portuguese, or a spoken name with
    /// no ordinary-prose reading. Anything needing meaning went to the prompt.
    ///
    /// All of them sit out terminal dictation (the default): in a shell, a
    /// spoken "…" or a restored circumflex is corruption. The symbol rules in
    /// `PortugueseSymbols.swift` are the ones that opt in there, because flags
    /// and paths are exactly what a terminal dictation contains.
    static let portugueseRules: [CleanupRule] = [
        // 1. Decimal comma. Portuguese reads 3,14 as "três vírgula catorze",
        //    and the decimal separator is a comma in every Portuguese-speaking
        //    country (INMETRO/VIM; CGPM). Digits on both sides make it
        //    unambiguous, which bare "vírgula" is not.
        //
        //    Declared at `.afterPunctuation` rather than `.early` because the
        //    shared Latin pass forces a space after every comma — correct for
        //    prose, fatal for "3,5".
        CleanupRule.regex(
            name: "pt decimal comma",
            stage: .afterPunctuation,
            pattern: #"(?<=\d)\s+v[íi]rgula\s+(?=\d)"#,
            template: ",",
            options: [.caseInsensitive]),

        // 2. Currency symbol separated from the amount by a space
        //    ("R$ 1.200", never "R$1.200").
        CleanupRule.regex(
            name: "pt currency symbol spacing",
            stage: .early,
            pattern: #"\b(R\$|US\$)\s*(?=\d)"#,
            template: "$1 "),

        // 3. Ordinal indicators. A digit glued to a lone "o"/"a" is an ordinal
        //    in Portuguese ("1o" → 1º, "2a" → 2ª) — the masculine/feminine
        //    ordinal indicators, not the letters. Anchored on both sides, so
        //    "de 2 a 3 dias" (spaced) and "0x2a" (no boundary) are untouched.
        CleanupRule.regex(
            name: "pt masculine ordinal indicator",
            stage: .early,
            pattern: #"\b(\d{1,3})o\b"#,
            template: "$1º"),
        CleanupRule.regex(
            name: "pt feminine ordinal indicator",
            stage: .early,
            pattern: #"\b(\d{1,3})a\b"#,
            template: "$1ª"),

        // 4. Spoken punctuation names with no ordinary-prose reading. Compare
        //    the excluded ones in the pack comment: every name here is either
        //    a multi-word phrase that only ever names a mark, or an imperative
        //    ("abre …") that cannot be a noun phrase.
        CleanupRule(name: "pt spoken punctuation names", stage: .early) { text, _ in
            var out = text
            // Sentence marks absorb an adjacent mark, so a name the engine has
            // already punctuated ("você vem? ponto de interrogação") renders
            // once instead of doubling up.
            for (name, mark) in [
                (#"ponto de interroga[çc][ãa]o"#, "?"),
                (#"ponto de exclama[çc][ãa]o"#, "!"),
                (#"ponto e v[íi]rgula"#, ";"),
            ] {
                out = PortugueseText.sub(out, #"[ \t]*[.,;:!?…]*[ \t]*\b(?:"# + name + #")\b[ \t]*[.,;:!?…]*"#,
                            " " + mark + " ")
            }
            // Reticências (…) glue to the word before them.
            out = PortugueseText.sub(out, #"[ \t]*[.,;:!?]*[ \t]*\bretic[êe]ncias\b"#, "…")
            // Quotation marks: Portuguese typography uses curly double quotes.
            out = PortugueseText.sub(out, #"\s*\b(?:abre|abrir|abra)\s+(?:as\s+)?aspas\b\s*"#, " “")
            out = PortugueseText.sub(out, #"\s*\b(?:fecha|fechar|feche)\s+(?:as\s+)?aspas\b"#, "”")
            // Braces. "chave" alone is a key; "abre chave" cannot be.
            out = PortugueseText.sub(out, #"\s*\b(?:abre|abrir|abra)\s+(?:as\s+)?chaves?\b\s*"#, " {")
            out = PortugueseText.sub(out, #"\s*\b(?:fecha|fechar|feche)\s+(?:as\s+)?chaves?\b"#, "}")
            return PortugueseText.sub(out, #"[ \t]{2,}"#, " ")
        },

        // 5. Spoken line breaks. Declared at `.afterPunctuation` because the
        //    shared Latin spacing pass ends in `collapseWhitespace`, which
        //    would flatten a newline inserted any earlier.
        CleanupRule(name: "pt spoken line breaks", stage: .afterPunctuation) { text, _ in
            // Longest name first, so "novo parágrafo" is not eaten by a
            // shorter alternative.
            var out = PortugueseText.sub(text, #"\s*\bnovo par[áa]grafo\b\s*"#, "\n\n")
            out = PortugueseText.sub(out, #"\s*\bnova linha\b\s*"#, "\n")
            return out
        },

        // 6. Circumflex on a stressed "quê" ending a sentence. The rule of the
        //    four "porquês": «por quê» (accented, two words) is the form used
        //    at the end of a period, before . ! or ?. Same for "o quê", "do
        //    quê", "para quê" — a monosyllable in final position is stressed
        //    and takes the circumflex.
        CleanupRule.regex(
            name: "pt circumflex on sentence-final quê",
            stage: .final,
            pattern: #"\b(por|o|do|da|de|para|pra|com|em|no|na|ao)\s+que\b(?=\s*[.!?…]?\s*$)"#,
            template: "$1 quê",
            options: [.caseInsensitive]),

        // 7. Interrogative openers the single-token probe cannot see, because
        //    they need more than the first word:
        //    - multi-word frames: "por que", "será que", "quanto custa", and
        //      the "… é que" cleft, which is interrogative whenever it follows
        //      an interrogative word;
        //    - an interrogative word followed immediately by a finite verb.
        //      This is what separates "Onde está o arquivo" (question) from
        //      "Onde eu moro tem café" (statement) and "Como está o build"
        //      from "Como combinado, segue o relatório". The verb list is
        //      present/future only: a past tense is exactly what an adverbial
        //      clause opens with ("Quando foi lançado, ninguém viu").
        CleanupRule(name: "pt multi-word interrogative opener", stage: .final) { text, _ in
            // One sentence only: with more than one, the trailing mark belongs
            // to the last sentence, not to the opener.
            let withoutFinalMark = text.last.map { "?!.…".contains($0) } == true
                ? String(text.dropLast()) : text
            guard !withoutFinalMark.contains(where: { ".!?…".contains($0) }) else { return text }
            guard text.range(of: ptInterrogativeOpener,
                             options: [.regularExpression, .caseInsensitive, .anchored]) != nil else {
                return text
            }
            if text.hasSuffix("?") || text.hasSuffix("!") { return text }
            // A trailing "…" is a speaker trailing off; leave it as spoken.
            if text.hasSuffix("…") { return text }
            return withoutFinalMark + "?"
        },

        // 8. "né" is a tag question ("Está caro, né?"), so it ends the sentence
        //    with a question mark, never a period. Word-bounded, so "boné" and
        //    "carnê" are safe.
        CleanupRule.regex(
            name: "pt tag question né takes a question mark",
            stage: .final,
            pattern: #"\bné\s*\.?\s*$"#,
            template: "né?",
            options: [.caseInsensitive]),

        // 9. Days of the week and months are written lowercase in Portuguese
        //    (Acordo Ortográfico de 1990, Base XIX: "segunda-feira; outubro;
        //    primavera"). Engines trained on English-shaped data capitalize
        //    them. Anchored so a sentence-initial name keeps its capital, and
        //    "Rio de Janeiro" — where Janeiro is part of a toponym — is
        //    explicitly excluded.
        CleanupRule(name: "pt lowercase months and weekdays", stage: .final) { text, _ in
            var out = text
            for month in ptMonths {
                out = PortugueseText.sub(out,
                            #"(?<!Rio )\b(de|em|no|até|desde|entre|para|pra|a|ao)\s+"# + month + #"\b"#,
                            "$1 " + month.lowercased(),
                            options: [])
            }
            for day in ptWeekdayStems {
                out = PortugueseText.sub(out, #"(?<=\p{Ll} )"# + day + #"-feira\b"#,
                            day.lowercased() + "-feira", options: [])
            }
            for day in ["Sábado", "Domingo"] {
                out = PortugueseText.sub(out,
                            #"\b(no|ao|de|em|desde|até|todo|neste|nesse|próximo|último)\s+"# + day + #"\b"#,
                            "$1 " + day.lowercased(), options: [])
            }
            return out
        },
    ]
}

// MARK: - File-private lexicons

/// Openers that can only introduce a direct question. Unambiguous single words
/// live in `questionPrefixWords`; these are the frames the first-token probe
/// cannot reach — the multi-word ones, the "… é que" cleft (which turns any
/// interrogative word into an unmistakable question), and an interrogative word
/// resolved by the verb that follows it.
private let ptInterrogativeOpener =
    #"^(?:"#
    + #"por que|por quê|será que|sera que|de onde|para onde|pra onde|até quando"#
    + #"|\#(ptInterrogativeWords) é que"#
    + #"|\#(ptInterrogativeWords) (?:\#(ptQuestionVerbs))"#
    + #")\b"#

private let ptInterrogativeWords =
    "(?:o que|por que|quem|quando|onde|aonde|como|qual|quais|quanto|quanta|quantos|quantas|cadê)"

/// Finite verbs that follow an interrogative word in a direct question. Present
/// and future only — a past tense is what an adverbial clause opens with, so
/// including one would turn "Como foi combinado, seguimos" into a question.
private let ptQuestionVerbs =
    "é|são|está|estão|tá|tão|será|serão|vai|vão|tem|têm|posso|podemos|pode|podem"
    + "|devo|deve|devemos|falta|faltam|custa|custam|acontece|funciona|significa|dá|dão|fica|ficam"

private let ptMonths = [
    "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
    "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro",
]

private let ptWeekdayStems = ["Segunda", "Terça", "Terca", "Quarta", "Quinta", "Sexta"]
