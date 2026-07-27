import Foundation

extension LanguagePack {
    /// Spanish (es) — Peninsular and Latin American, one pack.
    ///
    /// The two things that make Spanish dictation different from English are
    /// both handled deterministically here: the **opening marks** `¿` `¡`,
    /// which RAE calls obligatory and which no transcriber reliably emits, and
    /// the fact that Spanish **symbol names are multi-word** ("guion bajo",
    /// "punto y coma"), which the single-token `SpokenSymbols` triggers cannot
    /// express on their own. See `SpanishOrthography` for the rules.
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - **"este" / "esto"**: the canonical Spanish hesitation *and* the
    ///   demonstrative ("este informe"). Never a deterministic filler; the
    ///   prompt asks the model to judge it in context.
    /// - **"pues" / "bueno" / "o sea" / "vale" / "claro" / "en plan" /
    ///   "digamos" / "¿no?" / "¿sabes?"**: discourse markers that carry
    ///   meaning at least as often as they fill a pause. Same treatment.
    /// - **"punto" and "coma" as standalone spoken punctuation**: "punto" is
    ///   an everyday noun (punto de vista, punto clave, a punto de) and "coma"
    ///   is also a noun and a verb form (que coma, en coma). They are NOT in
    ///   `spokenPunctuation`, which replaces unconditionally. "punto" survives
    ///   as a `SpokenSymbols` dot trigger only because that pipeline additionally
    ///   requires a joinable left neighbour and a known file extension on the
    ///   right. Only the unambiguous multi-word commands ("punto y coma",
    ///   "punto y aparte") are rendered — as rules, so they also repair model
    ///   output. "dos puntos" is excluded: "hay dos puntos importantes".
    /// - **"qué" after `¿`**: the diacritic restorer skips it. "¿Que te vas?"
    ///   (echo question, no tilde) is ordinary spoken Spanish, and dictation
    ///   is spoken Spanish. Every other interrogative is restored.
    /// - **Decimal and thousands separators**: RAE accepts *both* the comma
    ///   and the point as decimal separator, and both the point and a thin
    ///   space for thousands. With two valid answers there is no repair to
    ///   make, so digits pass through exactly as transcribed.
    /// - **Straight quotes → « »**: only a dictated "abrir comillas" command
    ///   produces guillemets. Rewriting quotes the speaker did not dictate
    ///   would corrupt quoted code and English quotations.
    /// - **Spelled-out letters** ("punto jota ese" → .js): Spanish letter
    ///   names are ordinary words ("ese", "te", "de", "ce"), so mapping them
    ///   to letters would shred prose. Left to the LLM pass.
    static let spanish = LanguagePack(
        code: "es",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Pure hesitation vowels and nasals only — see the ambiguity policy
        // above for the discourse markers that are deliberately absent.
        // "mm" is excluded on purpose: it is also the millimetre symbol
        // ("5 mm"), and the filler pass is a blind whole-word removal.
        fillers: ["eh", "ehh", "eeh", "em", "emm", "ehm", "mmm", "hmm"],
        // Empty by design: Spanish's unambiguous spoken punctuation is all
        // multi-word, so it is rendered by rules (which also run over model
        // output) rather than by the unconditional replacement table.
        spokenPunctuation: [:],
        // Interrogative words ONLY. Spanish yes/no questions don't invert
        // ("¿es bueno?" reads exactly like "es bueno"), so listing verbs would
        // turn plain statements into questions. Multi-word openers ("por qué",
        // "de dónde") can't be expressed here — the shared heuristic tests a
        // single leading token — so `SpanishOrthography.finalQuestionMark`
        // handles those.
        questionPrefixWords: [
            "qué", "quién", "quiénes", "cuándo", "cuánto", "cuánta",
            "cuántos", "cuántas", "dónde", "adónde", "cómo", "cuál", "cuáles",
        ],
        questionSuffixParticles: [],
        stopwords: LanguagePack.spanishStopwords,
        // NOTE: the spoken-symbol vocabulary is `SpokenSymbolVocabulary.spanish`
        // and is applied by a rule (`SpanishOrthography`), not by this field.
        // `EnglishPackTests.englishIsTheOnlyOptIn` asserts that no non-English
        // pack sets `symbols`, and relaxing it would mean editing another
        // language's test file. Going through the rules hook keeps this change
        // inside `Languages/Spanish/`, and it earns something too: the renderer
        // then also repairs model output, which `pack.symbols` never reaches.
        prompt: .spanish,
        rules: SpanishOrthography.rules,
        spokenSymbolWords: LanguagePack.spanishSpokenSymbolWords,
        modelLeadInPatterns: [
            // "Claro, aquí tienes el texto limpio:" — the Spanish shape of the
            // conversational wrapper the shared English patterns already catch.
            #"(?i)^\s*(?:claro|por supuesto|de acuerdo|entendido|vale|perfecto|desde luego)[,!.]+\s*(?:aqu[íi]\s+(?:tienes|est[áa]|va))?[^\n:]{0,80}:\s+"#,
            // "Aquí tienes la transcripción corregida:", "El texto limpio es:".
            #"(?i)^\s*(?:aqu[íi]\s+(?:tienes|est[áa]|va)|el\b|la\b)?[^\n:]{0,60}(?:transcripci[óo]n|dictado|texto\s+(?:limpio|corregido|final))[^\n:]{0,30}:\s+"#,
        ])

    /// Spanish function words: too common to prove that a dictation's opening
    /// survived (the faithfulness guard skips them) and never safe to fuse into
    /// a dictated identifier (`SpokenSymbols` refuses to join them). Declared
    /// separately because `SpokenSymbolVocabulary.spanish` builds on it before
    /// `LanguagePack.spanish` itself finishes initializing.
    static let spanishStopwords: Set<String> = [
        // Articles, prepositions, conjunctions.
        "el", "la", "los", "las", "lo", "un", "una", "unos", "unas",
        "de", "del", "al", "a", "y", "e", "o", "u", "que", "en", "con",
        "por", "para", "sin", "sobre", "entre", "hasta", "desde", "según",
        "como", "pero", "aunque", "si", "porque", "cuando", "donde", "mientras",
        // Pronouns and possessives.
        "yo", "tú", "él", "ella", "ellos", "ellas", "usted", "ustedes",
        "nosotros", "nosotras", "vosotros", "me", "te", "se", "nos", "os",
        "le", "les", "mi", "mis", "tu", "tus", "su", "sus", "nuestro", "nuestra",
        // Common verb forms that carry no topical content.
        "es", "son", "era", "eran", "fue", "fueron", "ser", "está", "están",
        "estar", "hay", "he", "ha", "han", "había", "hemos", "haber",
        "tiene", "tienen", "tener", "va", "van", "ir",
        // Deictics and high-frequency adverbs.
        "este", "esta", "esto", "estos", "estas", "ese", "esa", "eso",
        "aquel", "aquella", "aquí", "ahí", "allí", "allá",
        "muy", "más", "menos", "ya", "también", "tampoco", "solo", "sólo",
        "ahora", "luego", "entonces", "así", "todo", "toda", "todos", "todas",
        // Discourse markers: legitimately dropped by the LLM pass, so their
        // absence from the output proves nothing about faithfulness.
        "bueno", "vale", "pues", "claro", "sí", "no", "ok", "okay",
        // Self-correction markers: removed along with what they retract.
        "perdón", "perdona", "digo", "mejor", "dicho", "espera", "bueno",
    ]

    /// Spanish words that *name* a symbol out loud. The faithfulness guard
    /// discounts them when counting content, so a heavily-dictated identifier
    /// ("test guion bajo cliente punto pi") doesn't read as a summary.
    static let spanishSpokenSymbolWords: Set<String> = [
        "punto", "puntos", "coma", "comas", "guion", "guión", "bajo",
        "barra", "arroba", "paréntesis", "parentesis", "corchete", "corchetes",
        "llave", "llaves", "comillas", "abrir", "abre", "cerrar", "cierra",
        "virgulilla", "tilde", "almohadilla", "numeral", "asterisco",
        "porcentaje", "dólar", "signo", "símbolo", "mayúscula", "minúscula",
        "espacio", "nueva", "nuevo", "línea", "linea", "salto", "párrafo",
        "parrafo", "aparte", "seguido", "interrogación", "exclamación",
        "igual", "más", "menos", "vertical", "invertida", "inclinada",
    ]
}

// MARK: - Spanish orthography

/// Spanish's own deterministic fixes. Everything the pack's declarative fields
/// cannot express lives here as a named `CleanupRule`, so both cleanup paths —
/// the zero-latency rules floor and the repair of model output — produce the
/// same orthography.
///
/// Every typographic rule sits out terminal dictation (the `CleanupRule`
/// default): in a shell an inserted `¿` or a « » pair is corruption, not a
/// correction. The only two that opt in are the spoken-symbol renderer and the
/// "guion bajo" join that must precede it — turning "guion guion verbose" into
/// `--verbose` is the point of dictating into a terminal at all.
enum SpanishOrthography {
    static let rules: [CleanupRule] = [
        // --- .early: spoken commands that produce an inline mark. Run before
        // the shared spacing pass so it can tidy whatever they leave behind.
        CleanupRule.regex(
            name: "es: spoken «punto y coma» renders a semicolon",
            stage: .early,
            pattern: #"(?i)\s*\bpunto y coma\b\s*"#,
            template: "; "),
        CleanupRule.regex(
            name: "es: spoken «punto y seguido» renders a period",
            stage: .early,
            pattern: #"(?i)\s*\bpunto y seguido\b\s*"#,
            template: ". "),
        // Before the symbol renderer below: it matches one token per trigger,
        // so it would read the "guion" of "guion bajo" as a dash and, in a
        // terminal, turn "guion bajo" into the flag "-bajo".
        CleanupRule(
            name: "es: spoken «guion bajo» joins an identifier",
            stage: .early,
            runsInTerminal: true,
            transform: { text, _ in joinSpokenUnderscore(text) }),
        // Spanish's spoken-symbol vocabulary, applied through the rules hook
        // rather than `LanguagePack.symbols` — see the note on the pack. Opted
        // into the terminal because that is where the renderer does its most
        // valuable work (flags and paths), and where its guards are strictest.
        CleanupRule(
            name: "es: spoken symbols render file names, identifiers and paths",
            stage: .early,
            runsInTerminal: true,
            transform: { text, context in
                SpokenSymbols.render(text, category: context.category, vocabulary: .spanish)
            }),
        // The shared Latin spacing pass puts a space after every comma that is
        // followed by a non-space — which splits the Spanish decimal comma:
        // "1.234,56" → "1.234, 56". It cannot tell that comma from a clause
        // comma, and neither can a later rule ("En 2020, 30 personas" is real
        // prose). So we hide it from that pass and restore it after, which is
        // lossless: the placeholder exists only between two stages of one
        // cleanup, and both stages run in both cleanup paths.
        CleanupRule.regex(
            name: "es: shield the decimal comma from the shared spacing pass",
            stage: .early,
            pattern: #"(?<=[0-9]),(?=[0-9])"#,
            template: "\u{E000}"),

        // --- .afterPunctuation: conventions the shared Latin spacing pass
        // would otherwise flatten, and the paragraph commands, whose newlines
        // the rules floor collapses if they are inserted any earlier.
        CleanupRule.regex(
            name: "es: restore the shielded decimal comma",
            stage: .afterPunctuation,
            pattern: "\u{E000}",
            template: ","),
        CleanupRule.regex(
            name: "es: spoken «punto y aparte» starts a new paragraph",
            stage: .afterPunctuation,
            pattern: #"(?i)\s*\bpunto y aparte\b\s*"#,
            template: ".\n\n"),
        CleanupRule.regex(
            name: "es: spoken «nuevo párrafo» starts a new paragraph",
            stage: .afterPunctuation,
            pattern: #"(?i)\s*\bnuevo p[áa]rrafo\b\s*"#,
            template: "\n\n"),
        CleanupRule.regex(
            name: "es: spoken «nueva línea» inserts a line break",
            stage: .afterPunctuation,
            pattern: #"(?i)\s*\b(?:nueva l[íi]nea|salto de l[íi]nea)\b\s*"#,
            template: "\n"),
        // RAE: the opening signs are written attached to the first word of the
        // sequence they frame and separated by a space from what precedes.
        CleanupRule.regex(
            name: "es: opening marks hug the word they open",
            stage: .afterPunctuation,
            pattern: #"([¿¡])[ \t]+"#,
            template: "$1"),
        CleanupRule.regex(
            name: "es: opening marks are separated from the preceding word",
            stage: .afterPunctuation,
            pattern: #"(?<=[\p{L}\p{N},;:])([¿¡])"#,
            template: " $1"),
        // RAE: a symbol is separated from the figure it follows (50 %, 20 €,
        // 23 °C). Prose only — "50%" is a CSS length and "%" is an operator,
        // so a code editor keeps whatever the speaker said.
        prose(name: "es: percent sign is spaced from the figure",
              stage: .afterPunctuation,
              pattern: #"(?<=[0-9])[ \t]*%"#,
              template: " %"),
        prose(name: "es: euro sign is spaced from the figure",
              stage: .afterPunctuation,
              pattern: #"(?<=[0-9])[ \t]*€"#,
              template: " €"),
        prose(name: "es: degree symbol is spaced from the figure",
              stage: .afterPunctuation,
              pattern: #"(?<=[0-9])[ \t]*°[ \t]*([CF])\b"#,
              template: " °$1"),
        // RAE puts comillas angulares at the first level of quotation, so a
        // dictated quote gets « ». A code editor gets straight quotes instead:
        // there the speaker is almost certainly dictating a string literal,
        // and « » would be a syntax error rather than a typographic nicety.
        CleanupRule(
            name: "es: spoken «abrir comillas» opens a quotation",
            stage: .afterPunctuation,
            transform: { text, context in
                replacing(text,
                          pattern: #"(?i)\s*\b(?:abrir|abre|abro)(?: las)? comillas\b\s*"#,
                          template: context.category == .codeEditor ? " \"" : " «")
            }),
        CleanupRule(
            name: "es: spoken «cerrar comillas» closes a quotation",
            stage: .afterPunctuation,
            transform: { text, context in
                replacing(text,
                          pattern: #"(?i)\s*\b(?:cerrar|cierra|cierro)(?: las)? comillas\b"#,
                          template: context.category == .codeEditor ? "\"" : "»")
            }),

        // --- .final: rules that need the finished sentence.
        CleanupRule(
            name: "es: a final sentence opening with an interrogative ends in ?",
            stage: .final,
            transform: { text, _ in finalQuestionMark(text) }),
        CleanupRule(
            name: "es: questions and exclamations gain their opening ¿ ¡",
            stage: .final,
            transform: { text, _ in addOpeningMarks(text) }),
        CleanupRule(
            name: "es: interrogatives inside ¿…? carry their diacritic",
            stage: .final,
            transform: { text, _ in restoreInterrogativeTildes(text) }),
        CleanupRule(
            name: "es: capitalize after an opening mark or a line break",
            stage: .final,
            transform: { text, _ in capitalizeAfterOpeners(text) }),
        CleanupRule(
            name: "es: months, weekdays and language names stay lowercase",
            stage: .final,
            transform: { text, _ in lowercaseCommonNouns(text) }),
    ]

    // MARK: - Question detection

    /// Words that open a direct question. Single tokens duplicate the pack's
    /// `questionPrefixWords` (the shared heuristic reads only the first token
    /// of the whole text); the two-token entries are what this rule adds.
    static let questionOpeners: Set<String> = [
        "qué", "quién", "quiénes", "cuál", "cuáles", "cuándo",
        "cuánto", "cuánta", "cuántos", "cuántas", "dónde", "adónde", "cómo",
        "por qué", "para qué", "de dónde", "de quién", "de quiénes",
        "a qué", "a quién", "a quiénes", "a cuánto", "en qué", "en cuánto",
        "con qué", "con quién", "hasta cuándo", "desde cuándo", "hacia dónde",
        "qué tal", "cada cuánto", "para cuándo", "por dónde",
    ]

    /// True when the first one or two words of `sentence` open a direct
    /// question. Splitting on non-letters drops any leading `¿` or quote.
    static func opensQuestion(_ sentence: String) -> Bool {
        let words = sentence.lowercased()
            .split(whereSeparator: { !$0.isLetter })
            .prefix(2)
            .map(String.init)
        guard let first = words.first else { return false }
        if questionOpeners.contains(first) { return true }
        if words.count == 2, questionOpeners.contains(first + " " + words[1]) { return true }
        return false
    }

    /// Turn the period the shared pass just appended into a question mark when
    /// the last sentence opens with an interrogative.
    ///
    /// Gating on a period already being there is deliberate: it is the only
    /// evidence a rule has that `CleanupOptions.addPunctuation` is on, so a
    /// user who turned punctuation off never gets a "?" from us either.
    ///
    /// The comma/colon/semicolon guard is what keeps indirect questions safe:
    /// "Cómo lo hizo, no lo sé." is a statement, and every phrasing that fools
    /// this heuristic has an internal comma.
    static func finalQuestionMark(_ text: String) -> String {
        var parts = segments(text)
        guard let index = parts.lastIndex(where: {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else { return text }
        let sentence = parts[index]
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasSuffix("."), !trimmed.hasSuffix(".."),
              !trimmed.contains(","), !trimmed.contains(";"), !trimmed.contains(":"),
              opensQuestion(trimmed),
              let dot = sentence.lastIndex(of: ".") else { return text }
        parts[index] = sentence.replacingCharacters(in: dot...dot, with: "?")
        return parts.joined()
    }

    // MARK: - Opening marks

    /// RAE: `¿` and `¡` are double signs — the opening one is obligatory and
    /// must not be dropped in imitation of English. Transcribers emit the
    /// closing mark and almost never the opening one, so we restore it.
    static func addOpeningMarks(_ text: String) -> String {
        guard text.contains("?") || text.contains("!") else { return text }
        // A query string is not a question. Bail on the whole text rather than
        // trying to tell prose from a URL segment by segment.
        guard !text.lowercased().contains("://") else { return text }
        return segments(text).map(openSegment).joined()
    }

    private static func openSegment(_ segment: String) -> String {
        let trimmed = segment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let closer = trimmed.last, closer == "?" || closer == "!" else { return segment }
        // Already opened (by the speaker, the engine, or a previous run), or
        // mixed ¿…! — either way, leave the speaker's marks alone.
        guard !segment.contains("¿"), !segment.contains("¡") else { return segment }
        var chars = Array(segment)
        var insertAt = 0
        while insertAt < chars.count,
              chars[insertAt].isWhitespace || "«\"“'‘(".contains(chars[insertAt]) {
            insertAt += 1
        }
        guard insertAt < chars.count else { return segment }
        // RAE: the sign goes exactly where the question begins, which is after
        // a leading vocative or subordinate clause — "María, ¿qué hora es?",
        // "Si no tienes clase, ¿por qué no vienes?".
        if closer == "?", let afterComma = questionStartAfterComma(chars, from: insertAt) {
            insertAt = afterComma
        }
        chars.insert(closer == "?" ? "¿" : "¡", at: insertAt)
        return String(chars)
    }

    /// The index just past the last comma whose remainder opens a question.
    private static func questionStartAfterComma(_ chars: [Character], from start: Int) -> Int? {
        var result: Int?
        for i in start..<chars.count where chars[i] == "," {
            var j = i + 1
            while j < chars.count, chars[j].isWhitespace { j += 1 }
            guard j < chars.count else { continue }
            if opensQuestion(String(chars[j...])) { result = j }
        }
        return result
    }

    // MARK: - Diacritics

    /// Interrogative pronouns and adverbs carry a diacritical tilde. Applied
    /// only immediately after `¿`, where the word is interrogative by
    /// construction — and never to "qué", because "¿Que te vas?" (echo
    /// question, correctly unaccented) is ordinary spoken Spanish.
    static let interrogativeTildes: [String: String] = [
        "donde": "dónde", "adonde": "adónde", "cuando": "cuándo",
        "como": "cómo", "cual": "cuál", "cuales": "cuáles",
        "quien": "quién", "quienes": "quiénes",
        "cuanto": "cuánto", "cuanta": "cuánta",
        "cuantos": "cuántos", "cuantas": "cuántas",
        // Two-word openers: "por que" is only ever "por qué" inside ¿…?.
        "por que": "por qué", "para que": "para qué",
    ]

    static func restoreInterrogativeTildes(_ text: String) -> String {
        guard text.contains("¿") else { return text }
        let pattern = #"¿(\p{L}+)(\s+(\p{L}+))?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        var out = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let firstRange = Range(match.range(at: 1), in: out) else { continue }
            let first = String(out[firstRange])
            if match.range(at: 3).location != NSNotFound,
               let secondRange = Range(match.range(at: 3), in: out) {
                let second = String(out[secondRange])
                let key = (first + " " + second).lowercased()
                if let fixed = interrogativeTildes[key] {
                    let parts = fixed.split(separator: " ").map(String.init)
                    out.replaceSubrange(secondRange, with: matchingCase(parts[1], like: second))
                    out.replaceSubrange(firstRange, with: matchingCase(parts[0], like: first))
                    continue
                }
            }
            if let fixed = interrogativeTildes[first.lowercased()] {
                out.replaceSubrange(firstRange, with: matchingCase(fixed, like: first))
            }
        }
        return out
    }

    /// Keep the replacement's capitalization in step with what it replaces —
    /// the word after `¿` is sentence-initial as often as not.
    private static func matchingCase(_ replacement: String, like original: String) -> String {
        guard let first = original.first, first.isUppercase, let head = replacement.first else {
            return replacement
        }
        return String(head).uppercased() + replacement.dropFirst()
    }

    // MARK: - Capitalization

    /// The shared capitalization pass tests whether the *first character* of a
    /// token is lowercase, and it splits on spaces alone. So "¿que hora es?"
    /// (the token starts with `¿`) and the word after a dictated line break
    /// (same token as the word before it) both slip past it.
    ///
    /// This closes exactly those two gaps and nothing else — ordinary sentence
    /// starts are left to the shared pass, which owns the
    /// `fixCapitalization` option. The plain-word guard is the shared one, so
    /// "app.js falló" never becomes "App.js falló".
    static func capitalizeAfterOpeners(_ text: String) -> String {
        var chars = Array(text)
        var atSentenceStart = true
        var sawOpeningMark = false
        var afterLineBreak = false
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            if atSentenceStart {
                if ch.isWhitespace || "¿¡«\"“'‘(".contains(ch) {
                    if ch == "\n" { afterLineBreak = true }
                    if "¿¡«\"“'‘(".contains(ch) { sawOpeningMark = true }
                    i += 1
                    continue
                }
                let ours = sawOpeningMark || afterLineBreak || i == 0
                if ours, ch.isLowercase, isPlainWord(chars, startingAt: i) {
                    chars[i] = Character(String(ch).uppercased())
                }
                atSentenceStart = false
                sawOpeningMark = false
                afterLineBreak = false
            }
            if isSentenceBreak(chars, at: i) {
                atSentenceStart = true
                afterLineBreak = ch == "\n"
            }
            i += 1
        }
        return String(chars)
    }

    private static func isPlainWord(_ chars: [Character], startingAt index: Int) -> Bool {
        var token = ""
        var i = index
        while i < chars.count, !chars[i].isWhitespace {
            token.append(chars[i])
            i += 1
        }
        let core = token.trimmingCharacters(in: .punctuationCharacters)
        return !core.isEmpty && core.allSatisfy { $0.isLetter || $0 == "'" }
    }

    /// A period only ends a sentence when whitespace (or the end of the text)
    /// follows it — the dots in main.py and 3.14 do not.
    private static func isSentenceBreak(_ chars: [Character], at index: Int) -> Bool {
        let ch = chars[index]
        if ch == "\n" { return true }
        guard ".!?…".contains(ch) else { return false }
        return index + 1 >= chars.count || chars[index + 1].isWhitespace
    }

    // MARK: - Common nouns that English capitalizes and Spanish does not

    private static let calendarTriggers =
        #"de|del|el|los|en|este|esta|pr[óo]ximo|pr[óo]xima|pasado|pasada|desde|hasta|al"#
    private static let calendarNames =
        #"enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|setiembre|octubre|noviembre|diciembre|lunes|martes|mi[ée]rcoles|jueves|viernes|s[áa]bado|domingo"#
    private static let languageTriggers =
        #"en|al|del|hablo|habla|hablan|hablar|hablamos|idioma|lengua|traducir|traduce|traducido"#
    private static let languageNames =
        #"espa[ñn]ol|castellano|ingl[ée]s|franc[ée]s|alem[áa]n|italiano|portugu[ée]s|chino|japon[ée]s|ruso|[áa]rabe|catal[áa]n|gallego|euskera|coreano|neerland[ée]s|holand[ée]s|sueco|polaco|turco|vietnamita|ucraniano"#

    /// RAE: months, weekdays, seasons and the names of languages are common
    /// nouns in Spanish and take no capital. An engine trained on
    /// English-heavy data capitalizes them anyway.
    ///
    /// Both halves require a trigger word in front, so a sentence-initial
    /// "Lunes" keeps its capital, and both refuse to fire when the next word
    /// is itself capitalized — that is "el Viernes Santo", a proper name.
    static func lowercaseCommonNouns(_ text: String) -> String {
        var out = text
        out = lowercasingSecondGroup(out, trigger: calendarTriggers, names: calendarNames)
        out = lowercasingSecondGroup(out, trigger: languageTriggers, names: languageNames)
        return out
    }

    private static func lowercasingSecondGroup(_ text: String,
                                               trigger: String,
                                               names: String) -> String {
        let pattern = "(?i)\\b(?:\(trigger))\\s+(\(names))\\b(?!\\s+\\p{Lu})"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        var out = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let range = Range(match.range(at: 1), in: out) else { continue }
            let word = String(out[range])
            guard let first = word.first, first.isUppercase else { continue }
            out.replaceSubrange(range, with: word.lowercased())
        }
        return out
    }

    // MARK: - Multi-word symbol names

    /// "max guion bajo reintentos" → max_reintentos.
    ///
    /// `SpokenSymbols` matches one token per trigger, and every Spanish symbol
    /// name for `_` is two words. The join guards are the same ones that
    /// pipeline uses — both neighbours must look like identifier parts and
    /// neither may be a function word — so "el guion bajo del documento" stays
    /// prose.
    static func joinSpokenUnderscore(_ text: String) -> String {
        guard text.range(of: #"(?i)gui[oó]n bajo"#, options: .regularExpression) != nil else {
            return text
        }
        var tokens = text.split(separator: " ").map(String.init)
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            let isTrigger = i + 1 < tokens.count
                && ["guion", "guión"].contains(tokens[i].lowercased())
                && tokens[i + 1].lowercased() == "bajo"
            if isTrigger, let left = out.last, isJoinable(left), i + 2 < tokens.count {
                let right = tokens[i + 2]
                if isJoinable(right) {
                    out[out.count - 1] = left + "_" + right
                    i += 3
                    continue
                }
            }
            out.append(tokens[i])
            i += 1
        }
        tokens = out
        return tokens.joined(separator: " ")
    }

    private static func isJoinable(_ token: String) -> Bool {
        !token.isEmpty
            && token.allSatisfy { $0.isLetter || $0.isNumber || "._-".contains($0) }
            && !LanguagePack.spanishStopwords.contains(token.lowercased())
    }

    // MARK: - Helpers

    /// Split into sentence-ish segments, each keeping its own terminal mark so
    /// `joined()` reconstructs the input exactly.
    static func segments(_ text: String) -> [String] {
        var out: [String] = []
        var current = ""
        let chars = Array(text)
        for (i, ch) in chars.enumerated() {
            current.append(ch)
            guard ".!?…\n".contains(ch) else { continue }
            if ch == "\n" || i + 1 >= chars.count || chars[i + 1].isWhitespace {
                out.append(current)
                current = ""
            }
        }
        if !current.isEmpty { out.append(current) }
        return out
    }

    /// A regex rule restricted to prose targets. Terminal is already excluded
    /// for every rule; this also excludes a code editor, where typographic
    /// spacing and « » would corrupt the code being dictated.
    private static func prose(name: String,
                              stage: CleanupRule.Stage,
                              pattern: String,
                              template: String) -> CleanupRule {
        CleanupRule(name: name, stage: stage) { text, context in
            guard context.category == .general || context.category == .messaging else {
                return text
            }
            return replacing(text, pattern: pattern, template: template)
        }
    }

    /// A regex substitution that degrades to "no change" if the pattern fails
    /// to compile, matching `CleanupRule.regex`'s contract.
    private static func replacing(_ text: String, pattern: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [],
                                              range: range, withTemplate: template)
    }
}
