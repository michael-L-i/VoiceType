import Foundation

/// The two spaces French orthotypography needs and English never does.
///
/// Sources: *Lexique des règles typographiques en usage à l'Imprimerie
/// nationale* (2002); Académie française, « Questions de langue — la
/// ponctuation »; Wikipédia, « Espace fine insécable ».
enum FrenchTypography {
    /// U+202F NARROW NO-BREAK SPACE — the *espace fine insécable*, set before
    /// the "high" punctuation marks `;` `!` `?`.
    static let narrowSpace = "\u{202F}"

    /// U+00A0 NO-BREAK SPACE — the *espace insécable*, set before `:`, inside
    /// « … », and between a number and the unit that follows it (`50 %`,
    /// `12,50 €`). France excludes the colon from the fine space; the
    /// Imprimerie nationale gives it a full non-breaking space.
    static let noBreakSpace = "\u{00A0}"
}

extension LanguagePack {
    /// French (fr — France conventions; see the fr-CA note below).
    ///
    /// French is unusually rule-dense at the *typographic* level and unusually
    /// treacherous at the *lexical* level, so the pack is split accordingly:
    /// everything an orthography manual states as always-true is deterministic,
    /// everything that needs to know what the speaker meant is left to the LLM
    /// (see `FrenchPrompt.swift`).
    ///
    /// **Deliberately NOT done — the reviewer's list:**
    /// - **`point` → `.`** as sentence punctuation. This is the German-`Punkt`
    ///   trap: *point* is one of the most common nouns in the language (« point
    ///   de vue », « à quel point », « mise au point », « un bon point »), and
    ///   the table replaces unconditionally. It *is* wired up as a
    ///   `SpokenSymbolVocabulary` trigger, where the neighbour rules only fire
    ///   on a real file extension or e-mail (`main point py` → `main.py`), and
    ///   English's pack draws the same line: it renders `dot`, never `period`.
    /// - **`deux points` → `:`**. Genuinely ambiguous — « j'ai deux points de
    ///   retard », « il y a deux points à régler ». Unlike « une virgule », no
    ///   determiner test separates the senses, because *deux* is itself the
    ///   determiner. Prompt-side only.
    /// - **`ben` / `bah` / `bon` / `quoi` / `voilà` / `hein` / `genre` / `du
    ///   coup` / `en fait` / `tu vois`.** All of them hesitate *and* mean
    ///   something; corpus work on French disfluency separates the non-lexical
    ///   filled pause (*euh*) from these lexical discourse markers, and only the
    ///   first kind is safe to delete blind. The prompt asks the model to drop
    ///   them when they are empty.
    /// - **Decimal and thousands separators.** French writes `3,14` and
    ///   `10 000`, but a transcript's `3.14` may be a version number and its
    ///   `2026` a year, `75001` a postcode. No deterministic rule survives that.
    /// - **Repairing a decimal comma the shared spacing pass split.**
    ///   `fixPunctuationSpacing` puts a space after every comma, so a
    ///   transcribed `12,50 €` reaches the output as `12, 50 €`. Every rejoin
    ///   rule we tried also welds an enumeration of numbers together
    ///   (« les pages 10, 25 sont vides » → `10,25`), and corrupting good text
    ///   is worse than a cosmetic space. The model path never sees the split,
    ///   so the LLM output is correct; the rules floor is not.
    /// - **`14:30` → `14 h 30`.** Correct per the Imprimerie nationale, but the
    ///   colon rule below already has to dodge times, URLs and ratios; a second
    ///   rule rewriting them would be one guess too many.
    /// - **Nationality/language casing** (« un Français » vs « le peuple
    ///   français »). The noun/adjective distinction is exactly the kind of
    ///   meaning a blind rule can't see. Prompt-side.
    /// - **fr-CA.** `LanguagePack.pack(for:)` keys on the primary subtag, so
    ///   Québec dictation gets this pack. Québec (OQLF/BDL) sets no space
    ///   before `;` `!` `?` while still spacing the colon. We follow the France
    ///   convention because it is what the majority of fr speakers and every
    ///   French word processor's autocorrect produce; splitting the pack per
    ///   region needs a registry change, which is not this pack's to make.
    static let french = LanguagePack(
        code: "fr",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Non-lexical filled pauses only. "euh" is the canonical French
        // hesitation vowel; the rest are spelling variants transcribers emit
        // for the same sound. Nothing here can ever be a content word.
        fillers: [
            "euh", "euhh", "euhm", "heu", "heuh", "heum",
            "hum", "humm", "hmm", "hmmm", "mmh", "mmm", "hem",
        ],
        // Empty on purpose: the flat table replaces unconditionally and only
        // runs in the deterministic path. French's spoken punctuation needs
        // determiner guards ("une virgule" is a noun) and must also repair
        // model output, so it lives in `rules` instead — see
        // `frenchSpokenPunctuationRules`.
        spokenPunctuation: [:],
        // Interrogative words, plus the two frames that are unambiguous as an
        // opening token: "est-ce (que)" and "qu'est-ce (que)". The rest are
        // subject-verb inversions, which in French are essentially always
        // interrogative — the hyphen is the giveaway, and a curated list is
        // safer than a pattern that would also catch "peut-être".
        questionPrefixWords: [
            "est-ce", "qu'est-ce", "qu’est-ce",
            "pourquoi", "comment", "quand", "où", "qui", "que", "quoi",
            "quel", "quelle", "quels", "quelles", "combien",
            "lequel", "laquelle", "lesquels", "lesquelles",
            "puis-je", "dois-je", "peux-tu", "peut-on", "pouvez-vous",
            "pourrais-tu", "pourriez-vous", "as-tu", "avez-vous",
            "a-t-il", "a-t-elle", "y", "es-tu", "êtes-vous",
            "est-il", "est-elle", "sont-ils", "sont-elles",
            "sais-tu", "savez-vous", "veux-tu", "voulez-vous",
            "faut-il", "doit-on", "va-t-il", "allez-vous",
            "connais-tu", "connaissez-vous", "penses-tu", "pensez-vous",
            "serait-il", "seriez-vous", "aurais-tu", "auriez-vous",
        ],
        // "n'est-ce pas" is the one French tag that is never anything but a
        // question. "non ?" and "d'accord ?" hesitate between tag and content,
        // so they stay out.
        questionSuffixParticles: ["n'est-ce pas", "n’est-ce pas"],
        stopwords: LanguagePack.frenchStopwords,
        // Left nil deliberately. French *does* render spoken symbols, but it
        // drives the renderer from its own rule (`frenchSpokenSymbolRule`)
        // rather than from this field — see that rule for why.
        symbols: nil,
        // French has none: "je" is lowercase everywhere but sentence-initially.
        capitalizedStandalonePronoun: nil,
        prompt: .french,
        rules: LanguagePack.frenchRules,
        spokenSymbolWords: LanguagePack.frenchSpokenSymbolWords,
        modelLeadInPatterns: [
            // "Bien sûr, voici le texte nettoyé :" — the French shape of the
            // lead-in the shared English patterns already catch.
            #"(?i)^\s*(?:bien sûr|bien entendu|d['’]accord|certainement|entendu|voici|voilà)\s*[,!.]+\s*[^\n:]{0,80}:\s+"#,
            // "Voici la transcription corrigée :" — named-output form.
            #"(?i)^\s*(?:voici|voilà)\s+[^\n:]{0,60}(?:texte|transcription|dictée|version|résultat)[^\n:]{0,30}:\s+"#,
        ])

    // MARK: - Stopwords

    /// French function words. They make the faithfulness guard's
    /// dropped-opening probe more conservative, and — more importantly here —
    /// they are the `joinGuards` that stop `SpokenSymbols` from welding a
    /// spoken "point" onto ordinary prose: « le point de vue » never joins
    /// because "le" is on this list.
    ///
    /// Elided forms appear both with and without the apostrophe, because the
    /// guard trims punctuation off word edges ("l'" arrives as "l").
    static let frenchStopwords: Set<String> = [
        // Determiners and prepositions.
        "le", "la", "les", "l", "l'", "un", "une", "des", "du", "de", "d", "d'",
        "au", "aux", "à", "en", "dans", "sur", "sous", "pour", "par", "avec",
        "sans", "chez", "vers", "entre", "depuis", "pendant", "avant", "après",
        // Conjunctions and connectors.
        "et", "ou", "mais", "donc", "or", "ni", "car", "que", "qu", "qu'",
        "comme", "si", "quand", "alors", "aussi", "encore", "déjà", "puis",
        // Pronouns.
        "je", "j", "j'", "tu", "il", "elle", "on", "nous", "vous", "ils",
        "elles", "me", "m", "m'", "te", "t", "t'", "se", "s", "s'", "y", "en",
        "ce", "c", "c'", "cet", "cette", "ces", "ça", "cela", "ceci", "celui",
        "qui", "quoi", "dont", "où", "lui", "leur", "moi", "toi", "soi",
        // Possessives.
        "mon", "ma", "mes", "ton", "ta", "tes", "son", "sa", "ses",
        "notre", "nos", "votre", "vos", "leurs",
        // The high-frequency verb forms.
        "est", "sont", "était", "étaient", "être", "suis", "es", "sommes",
        "êtes", "ai", "as", "a", "avons", "avez", "ont", "avoir", "avait",
        "fait", "faire", "va", "vais", "vont", "peut", "peux", "pouvez",
        // Negation, degree, and the little words that carry no content.
        "ne", "n", "n'", "pas", "plus", "moins", "très", "bien", "trop",
        "oui", "non", "là", "ici", "tout", "tous", "toute", "toutes",
        "quel", "quelle", "quels", "quelles", "même", "aucun", "aucune",
        // Self-correction markers: legitimately removed along with the words
        // they retract, so they prove nothing about the opening.
        "enfin", "plutôt", "pardon", "désolé", "attends", "attendez",
    ]

    /// Words that *name* a symbol in French. The faithfulness guard discounts
    /// them when counting content, so a heavily-dictated identifier doesn't
    /// read as a summary. Replaces the English default wholesale — "dot" and
    /// "paren" mean nothing in a French transcript.
    static let frenchSpokenSymbolWords: Set<String> = [
        "point", "points", "virgule", "tiret", "trait", "union", "bas",
        "barre", "oblique", "slash", "underscore", "tilde", "arobase",
        "dièse", "étoile", "astérisque", "pourcent", "parenthèse",
        "parenthèses", "crochet", "crochets", "accolade", "accolades",
        "guillemets", "apostrophe", "exclamation", "interrogation",
        "suspension", "ouvrante", "fermante", "ouvrant", "fermant",
        "ouvrez", "ouvrir", "ouvre", "fermez", "fermer", "ferme",
        "majuscule", "minuscule", "espace", "ligne", "paragraphe",
        "nouvelle", "nouveau", "deux",
    ]
}

// MARK: - Rules

extension LanguagePack {
    /// French's own deterministic fixes, in the order they run.
    ///
    /// Stage choice, in one line each:
    /// - `.early` — spoken-symbol phrases and abbreviations, so every later
    ///   shared pass (spacing, capitalization, terminal punctuation) sees real
    ///   marks instead of words.
    /// - `.afterPunctuation` — the paragraph commands, because the shared
    ///   whitespace collapse would eat a newline inserted any earlier.
    /// - `.final` — all the typography. It has to be last: `ensureQuestionMark`
    ///   appends its `?` *after* the `.afterPunctuation` stage, and that mark
    ///   needs its fine space too. Nothing runs after `.final`, so nothing can
    ///   flatten it back.
    static let frenchRules: [CleanupRule] =
        [frenchElisionSpacingRule]
        + frenchSpokenPunctuationRules
        + [frenchVirguleRule, frenchAbbreviationRule, frenchSpokenSymbolRule]
        + frenchParagraphRules
        + frenchTypographyRules

    /// Spoken file names, identifiers, e-mail addresses, flags and paths —
    /// « ouvre main point py » → `main.py`.
    ///
    /// This is the pack's own rule rather than the `symbols` field, for two
    /// reasons. The field's call site is inside `RuleBasedCleanup` only, so
    /// model output would never get the same repair; running it here covers
    /// both paths, the way every other rule in this pack does. And the ordering
    /// matters: it must run *after* the phrase rules above, or "max tiret bas
    /// retries" would be read as a dash ("max -bas retries") in a terminal
    /// instead of as the underscore it is.
    ///
    /// The renderer's neighbour rules do the position guarding — a trigger only
    /// fires when the tokens around it look like an identifier — and the words
    /// they fire on are French's own; see `FrenchSymbols.swift` for the
    /// vocabulary and for what was left out of it.
    static let frenchSpokenSymbolRule = CleanupRule(
        name: "fr spoken symbols", stage: .early, runsInTerminal: true
    ) { text, context in
        SpokenSymbols.render(text, category: context.category, vocabulary: .french)
    }

    // MARK: Guards shared by the spoken-punctuation rules

    /// Determiners and quantifiers that turn a punctuation *name* back into an
    /// ordinary noun: « une virgule », « un trait d'union », « une nouvelle
    /// ligne », « le point d'interrogation ». A speaker who says one of these
    /// first is talking *about* the mark, not dictating it.
    private static let frenchDeterminers = [
        "un", "une", "le", "la", "les", "des", "du", "de", "d'", "d’",
        "ce", "cet", "cette", "ces", "mon", "ma", "mes", "ton", "ta", "tes",
        "son", "sa", "ses", "notre", "nos", "votre", "vos", "leur", "leurs",
        "quel", "quelle", "quels", "quelles", "aucun", "aucune",
        "autre", "autres", "même", "chaque", "plusieurs",
        "premier", "première", "dernier", "dernière", "deuxième",
    ]

    /// Number words, so « trois virgule quatorze » stays a decimal instead of
    /// becoming « trois, quatorze ».
    private static let frenchNumberWords = [
        "zéro", "un", "une", "deux", "trois", "quatre", "cinq", "six", "sept",
        "huit", "neuf", "dix", "onze", "douze", "treize", "quatorze", "quinze",
        "seize", "vingt", "vingts", "trente", "quarante", "cinquante",
        "soixante", "cent", "cents", "mille", "million", "millions",
        "milliard", "milliards", "demi", "demie",
    ]

    private static func alternation(_ words: [String]) -> String {
        words.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|")
    }

    /// A negative lookbehind for the determiners, written twice: once for a
    /// match that starts on the separating space and once for a match that
    /// starts on the phrase itself. Both start positions are reachable when the
    /// pattern opens with `[ \t]*`, and guarding only one of them would let the
    /// regex engine simply retry at the other.
    private static var frenchNounGuard: String {
        let dets = alternation(frenchDeterminers)
        return "(?<!\\b(?:\(dets)))(?<!\\b(?:\(dets))[ \\t])"
    }

    /// Marks a sentence-punctuation phrase absorbs when the transcriber already
    /// rendered one next to the spoken name — engines produce "tu viens ? point
    /// d'interrogation", and the mark must not double up.
    private static let frenchAbsorbedMarks = "[.!?;…]"

    /// One spoken phrase → one mark.
    ///
    /// `eatsLeadingSpace` / `eatsTrailingSpace` decide how the mark attaches:
    /// a closing mark swallows the space before it, an opening mark the space
    /// after it, and a joiner ("trait d'union") both.
    ///
    /// `absorbsAdjacentMarks` makes the rule idempotent for sentence
    /// punctuation, the same trade-off the Chinese pack documents: whichever
    /// side rendered the mark, exactly one comes out.
    private static func frenchPhrase(_ name: String,
                                     _ body: String,
                                     _ mark: String,
                                     eatsLeadingSpace: Bool = true,
                                     eatsTrailingSpace: Bool = false,
                                     absorbsAdjacentMarks: Bool = false,
                                     runsInTerminal: Bool = false) -> CleanupRule {
        let pattern = frenchNounGuard
            + (eatsLeadingSpace ? "[ \\t]*" : "")
            + (absorbsAdjacentMarks ? "(?:\(frenchAbsorbedMarks)[ \\t]*)?" : "")
            + "\\b(?:\(body))\\b"
            + (absorbsAdjacentMarks ? "(?:[ \\t]*\(frenchAbsorbedMarks))?" : "")
            + (eatsTrailingSpace ? "[ \\t]*" : "")
        return .regex(name: "fr spoken \(name)",
                      stage: .early,
                      runsInTerminal: runsInTerminal,
                      pattern: pattern,
                      template: NSRegularExpression.escapedTemplate(for: mark),
                      options: [.caseInsensitive])
    }

    // MARK: Spoken punctuation

    /// The spoken names French dictation software has standardized on (Apple
    /// Dictation, Word, Dragon all take the same phrases), restricted to the
    /// ones that survive the determiner test. Multi-word by nature, which is
    /// most of why they're safe: nobody says "point d'interrogation" by
    /// accident.
    ///
    /// Declared before `frenchVirguleRule` so "point-virgule" is consumed as a
    /// semicolon before the comma rule can see the "virgule" inside it.
    static let frenchSpokenPunctuationRules: [CleanupRule] = [
        frenchPhrase("question mark", #"point d['’]interrogation"#, "?",
                     absorbsAdjacentMarks: true),
        frenchPhrase("exclamation mark", #"point d['’]exclamation"#, "!",
                     absorbsAdjacentMarks: true),
        frenchPhrase("semicolon", "point[- ]virgule", ";", absorbsAdjacentMarks: true),
        frenchPhrase("ellipsis", "points de suspension|trois petits points", "…",
                     absorbsAdjacentMarks: true),
        frenchPhrase("hyphen", #"trait d['’]union"#, "-",
                     eatsTrailingSpace: true, runsInTerminal: true),
        // Safe in a terminal: "tiret bas" is never anything but an underscore,
        // and shell identifiers are exactly where it gets dictated.
        frenchPhrase("underscore", "tiret (?:du )?bas", "_",
                     eatsTrailingSpace: true, runsInTerminal: true),
        frenchPhrase("open paren",
                     "(?:ouvrir|ouvrez|ouvre)[ \\t]+(?:la[ \\t]+|une[ \\t]+)?parenthèses?"
                        + "|parenthèses?[ \\t]+ouvrantes?",
                     "(", eatsLeadingSpace: false, eatsTrailingSpace: true),
        frenchPhrase("close paren",
                     "(?:fermer|fermez|ferme)[ \\t]+(?:la[ \\t]+)?parenthèses?"
                        + "|parenthèses?[ \\t]+fermantes?",
                     ")"),
        frenchPhrase("open bracket",
                     "(?:ouvrir|ouvrez|ouvre)[ \\t]+(?:le[ \\t]+|un[ \\t]+)?crochets?"
                        + "|crochets?[ \\t]+ouvrants?",
                     "[", eatsLeadingSpace: false, eatsTrailingSpace: true),
        frenchPhrase("close bracket",
                     "(?:fermer|fermez|ferme)[ \\t]+(?:le[ \\t]+)?crochets?"
                        + "|crochets?[ \\t]+fermants?",
                     "]"),
        // Guillemets carry their own espace insécable, so the pair comes out
        // typeset correctly even if the closing one is never spoken.
        frenchPhrase("open guillemet",
                     "(?:ouvrir|ouvrez|ouvre)[ \\t]+(?:les[ \\t]+|des[ \\t]+)?guillemets",
                     "«\(FrenchTypography.noBreakSpace)",
                     eatsLeadingSpace: false, eatsTrailingSpace: true),
        frenchPhrase("close guillemet",
                     "(?:fermer|fermez|ferme)[ \\t]+(?:les[ \\t]+)?guillemets",
                     "\(FrenchTypography.noBreakSpace)»"),
    ]

    /// « virgule » → `,`, which is the single most-dictated mark in French and
    /// the single most dangerous to render blind. Three guards, all necessary:
    /// a determiner before it makes it a noun (« mets une virgule »), a number
    /// on either side makes it a decimal point (« trois virgule quatorze »,
    /// « 3 virgule 14 »), and the word-boundary anchors keep it out of
    /// "point-virgule", already consumed above.
    static let frenchVirguleRule: CleanupRule = {
        let nums = alternation(frenchNumberWords)
        let pattern = frenchNounGuard
            + "(?<!\\b(?:\(nums)))(?<!\\b(?:\(nums))[ \\t])(?<!\\d)(?<!\\d[ \\t])"
            + "[ \\t]*\\bvirgule\\b"
            + "(?![ \\t]*(?:\\d|(?:\(nums))\\b))"
        return .regex(name: "fr spoken comma", stage: .early,
                      pattern: pattern, template: ",",
                      options: [.caseInsensitive])
    }()

    // MARK: Paragraph commands

    /// "nouveau paragraphe" / "à la ligne" and friends. `.afterPunctuation`
    /// because both cleanup paths collapse whitespace before that point, and a
    /// newline inserted at `.early` would simply be flattened back to a space.
    ///
    /// The determiner guard does the heavy lifting here too: « une nouvelle
    /// ligne de produits » and « un nouveau paragraphe » stay prose. « à la
    /// ligne » additionally refuses to fire before a number or "de", so
    /// « à la ligne 42 » and « à la ligne de commande » survive.
    static let frenchParagraphRules: [CleanupRule] = [
        .regex(name: "fr new paragraph", stage: .afterPunctuation,
               pattern: frenchNounGuard + "[ \\t]*\\bnouveau paragraphe\\b[ \\t]*",
               template: "\n\n", options: [.caseInsensitive]),
        .regex(name: "fr new line", stage: .afterPunctuation,
               pattern: frenchNounGuard + "[ \\t]*\\bnouvelle ligne\\b[ \\t]*",
               template: "\n", options: [.caseInsensitive]),
        .regex(name: "fr line break", stage: .afterPunctuation,
               pattern: frenchNounGuard
                   + "[ \\t]*\\b(?:retour |revenir |aller |on va )?[àa] la ligne\\b"
                   + "(?![ \\t]*(?:\\d|de\\b|du\\b))[ \\t]*",
               template: "\n", options: [.caseInsensitive]),
    ]

    // MARK: Abbreviations

    /// Abbreviations whose correct French form is fixed:
    /// - Ordinals are `1er` / `1re` / `2e` — never `2ème`, `2ième` or `1ère`
    ///   (Académie française, « Abréviations des adjectifs numéraux »).
    /// - `etc.` takes exactly one point, never « etc… » or « etc... »
    ///   (Imprimerie nationale).
    /// - « Mr » is an English abbreviation; French writes `M.` for *Monsieur*.
    ///   Only rewritten when a capitalized name follows, so an identifier or a
    ///   URL fragment is never touched.
    static let frenchAbbreviationRule = CleanupRule(
        name: "fr abbreviations and ordinals", stage: .early
    ) { text, _ in
        var out = text
        let substitutions: [(String, String, NSRegularExpression.Options)] = [
            (#"\b(\d+)[ \t]*(?:ièmes|iemes|èmes|emes)\b"#, "$1es", [.caseInsensitive]),
            (#"\b(\d+)[ \t]*(?:ième|ieme|ème|eme)\b"#, "$1e", [.caseInsensitive]),
            (#"\b1[ \t]*(?:ères|eres|ère|ere)\b"#, "1re", [.caseInsensitive]),
            (#"\b1[ \t]*(?:iers|ier)\b"#, "1er", [.caseInsensitive]),
            (#"\betc[ \t]*(?:\.{2,}|…)"#, "etc.", [.caseInsensitive]),
            (#"(?<![\w.])Mr\.?(?=[ \t]+\p{Lu})"#, "M.", []),
        ]
        for (pattern, template, options) in substitutions {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
                continue
            }
            out = regex.stringByReplacingMatches(
                in: out, range: NSRange(out.startIndex..., in: out), withTemplate: template)
        }
        return out
    }

    // MARK: Elision

    /// Transcribers routinely split an elision — "l' homme", "j' ai",
    /// "aujourd' hui". The space is never correct after an elided form, so
    /// closing it up is safe. `.early`, so the rest of the pipeline sees whole
    /// words (capitalization included).
    static let frenchElisionSpacingRule = CleanupRule.regex(
        name: "fr elision keeps its word",
        stage: .early,
        pattern: #"\b(l|d|j|n|m|t|s|c|qu|jusqu|lorsqu|puisqu|quoiqu|aujourd)(['’])[ \t]+(?=\p{L})"#,
        template: "$1$2",
        options: [.caseInsensitive])

    // MARK: Typography

    /// Everything a French orthography manual states as always-true. All at
    /// `.final`, all sitting out the terminal (rules do by default) and the
    /// code editor: `foo?.bar`, `key: value` and `x ? y : z` are code, and a
    /// "correction" there is corruption. Ordinary prose apps — mail, chat,
    /// notes, the browser — get the full treatment.
    static let frenchTypographyRules: [CleanupRule] = [
        // Straight or smart double quotes → guillemets. Runs before the
        // spacing rules so a mark tucked inside a quote ("Bonjour !") still
        // sees whitespace on its right and gets its fine space.
        frenchProseRule(name: "fr guillemets replace straight quotes",
                        pattern: #"["“]([^"“”\n]{1,300})["”]"#,
                        template: "«\(FrenchTypography.noBreakSpace)$1"
                            + "\(FrenchTypography.noBreakSpace)»"),
        frenchProseRule(name: "fr guillemets keep their inner space",
                        pattern: "«[ \\t\u{00A0}\u{202F}]*",
                        template: "«\(FrenchTypography.noBreakSpace)"),
        frenchProseRule(name: "fr closing guillemet keeps its inner space",
                        pattern: "[ \\t\u{00A0}\u{202F}]*»",
                        template: "\(FrenchTypography.noBreakSpace)»"),
        // The fine space before ; ! ? and the full one before :. The trailing
        // `(?=\s|$)` is what keeps `https://`, `5:30` and `foo?.bar` intact —
        // in prose these marks are always followed by a space or end the text.
        // Idempotent: after one pass the character to the left is itself a
        // space, so `(?<=\S)` no longer matches.
        frenchProseRule(name: "fr fine space before high punctuation",
                        pattern: "(?<=\\S)[ \\t\u{00A0}\u{202F}]*([;!?])(?=\\s|$)",
                        template: "\(FrenchTypography.narrowSpace)$1"),
        frenchProseRule(name: "fr no-break space before colon",
                        pattern: "(?<=\\S)[ \\t\u{00A0}\u{202F}]*(:)(?=\\s|$)",
                        template: "\(FrenchTypography.noBreakSpace):"),
        // A number and its unit are never separated by a breaking space:
        // "50 %", "12,50 €".
        frenchProseRule(name: "fr no-break space before unit",
                        pattern: "(\\d)[ \\t\u{00A0}\u{202F}]*([%€])",
                        template: "$1\(FrenchTypography.noBreakSpace)$2"),
        // The typographic apostrophe. Only between two letters, so it can only
        // ever be an elision — a quoting apostrophe never matches.
        frenchProseRule(name: "fr typographic apostrophe",
                        pattern: #"(?<=\p{L})'(?=\p{L})"#,
                        template: "’"),
        frenchCalendarCasingRule,
        frenchOpeningCapitalRule,
    ]

    /// A prose-only regex rule: skips the terminal (the default) and the code
    /// editor, where French spacing conventions would corrupt real code.
    private static func frenchProseRule(name: String,
                                        pattern: String,
                                        template: String) -> CleanupRule {
        CleanupRule(name: name, stage: .final) { text, context in
            guard context.category != .codeEditor else { return text }
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
            return regex.stringByReplacingMatches(
                in: text, range: NSRange(text.startIndex..., in: text), withTemplate: template)
        }
    }

    /// Days and months are lowercase in French — a capital on one only ever
    /// comes from a sentence start (Académie française; BDL). Models trained
    /// mostly on English put it back, so we take it off again.
    ///
    /// Deliberately narrow: only where the word is unmistakably a date, i.e.
    /// after a figure or a temporal preposition. « Mars » the planet, « Avril »
    /// the given name and a sentence-initial « Lundi » all keep their capital,
    /// because none of them sit in those positions.
    static let frenchCalendarCasingRule = CleanupRule(
        name: "fr days and months are lowercase", stage: .final
    ) { text, _ in
        let months = "janvier|février|mars|avril|mai|juin|juillet|août"
            + "|septembre|octobre|novembre|décembre"
        let days = "lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche"
        var out = text
        // A figure or a temporal preposition before the month.
        out = lowercasingSecondGroup(
            out, #"((?:\d|\b(?:en|de|du|au|dès|depuis|début|fin|mi|courant|vers|avant|après))[ \t-]+)("#
                + months + #")\b"#)
        // A determiner before the day, or a date figure after it.
        out = lowercasingSecondGroup(
            out, #"((?:\d|\b(?:le|ce|chaque|du|au|dès|depuis|tous les))[ \t]+)("# + days + #")\b"#)
        out = lowercasingSecondGroup(
            out, "()\\b(" + days + ")(?=[ \\t]+\\d)")
        return out
    }

    /// Lowercase capture group 2 of every match, leaving group 1 in place.
    private static func lowercasingSecondGroup(_ text: String, _ pattern: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return text
        }
        var out = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard match.numberOfRanges >= 3,
                  let word = Range(match.range(at: 2), in: out) else { continue }
            let name = String(out[word])
            guard name.first?.isUppercase == true else { continue }
            out.replaceSubrange(word, with: name.lowercased())
        }
        return out
    }

    /// Capitalize the opening of the text and of every line.
    ///
    /// Two gaps this closes, both invisible in English:
    /// - The shared capitalizer only treats `[letters']` as a plain word, so a
    ///   model that already wrote « j’ai » (typographic apostrophe) got no
    ///   capital at all. Half of French sentences start with an elision.
    /// - A line the paragraph rules just created starts mid-token as far as the
    ///   shared pass is concerned, so its first word was never a candidate.
    ///
    /// A leading identifier or path ("main.py est cassé") still keeps its case:
    /// the dot disqualifies the token, exactly as it does upstream.
    static let frenchOpeningCapitalRule = CleanupRule(
        name: "fr capitalize line openings", stage: .final
    ) { text, _ in
        text.split(separator: "\n", omittingEmptySubsequences: false)
            .map { line -> String in
                let text = String(line)
                guard let first = text.first, first.isLowercase else { return text }
                let token = text.prefix { !$0.isWhitespace }
                guard token.allSatisfy({ $0.isLetter || $0 == "'" || $0 == "’" || $0 == "-" })
                else { return text }
                return first.uppercased() + text.dropFirst()
            }
            .joined(separator: "\n")
    }
}
