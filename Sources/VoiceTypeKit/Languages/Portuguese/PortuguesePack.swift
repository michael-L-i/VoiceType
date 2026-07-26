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
        rules: LanguagePack.portugueseSymbolRules,
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
}
