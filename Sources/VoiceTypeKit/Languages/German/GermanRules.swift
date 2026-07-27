import Foundation

/// German's own deterministic fixes — the orthographic and typographic
/// conventions the pack's declarative fields don't ask about.
///
/// Everything here is a convention that is *always* right in German prose, so
/// it can run blind. Anything needing meaning (noun capitalization, das/dass,
/// compound re-joining, self-corrections) is left to the LLM pass and stated in
/// `GermanPrompt` instead.
///
/// Stage discipline, since it is easy to get wrong:
/// - `.early` — raw text. Spoken symbols and spoken punctuation names render
///   here so the shared spacing pass afterwards tidies what they produced.
/// - `.afterPunctuation` — after `fixPunctuationSpacing`, which would otherwise
///   flatten the spacing these rules install.
/// - `.final` — after capitalization and the terminal period, for rules that
///   must see (or must not be undone by) the finished sentence.
enum GermanRules {

    // MARK: - Registry

    /// Declaration order is execution order within a stage. Two orderings are
    /// load-bearing:
    /// - `decimalComma` before `currencyAfterAmount`, so the amount is one
    ///   token again before the sign is moved behind it.
    /// - `abbreviationSpacing` before `noSentenceCapitalAfterAbbreviation`,
    ///   which looks for the "B." / "h." token the former produces; and
    ///   `weekdayAndMonthCapitals` before `ordinalDatePeriod`, which matches
    ///   the capitalized month.
    static let all: [CleanupRule] = [
        // .early
        spokenSymbols,
        spokenPunctuation,
        spokenBrackets,
        // .afterPunctuation
        decimalComma,
        unitSpacing,
        currencyAfterAmount,
        emDashToGedankenstrich,
        // .final
        abbreviationSpacing,
        weekdayAndMonthCapitals,
        ordinalDatePeriod,
        noSentenceCapitalAfterAbbreviation,
        dictatedLineBreaks,
        germanQuotationMarks,
        typographicApostrophe,
    ]

    // MARK: - .early — spoken symbols and punctuation

    /// "haupt Punkt py" → haupt.py, "max Unterstrich retries" → max_retries,
    /// "Strich Strich verbose" → --verbose. Runs the shared `SpokenSymbols`
    /// pipeline with German trigger words (`SpokenSymbolVocabulary.german`).
    ///
    /// Opts into the terminal, where this is most of the value: a dictated
    /// shell command is mostly flags and paths. It is safe there because the
    /// pipeline only ever *joins* tokens the speaker marked — a command with no
    /// trigger words ("git status") comes back byte-identical.
    static let spokenSymbols = CleanupRule(
        name: "spoken symbols (German trigger words)",
        stage: .early,
        runsInTerminal: true) { text, context in
            SpokenSymbols.render(text, category: context.category, vocabulary: .german)
        }

    /// Spoken names of the marks whose German name *only* ever names the mark.
    ///
    /// Ambiguity policy — deliberately NOT here:
    /// - **"Punkt"** and **"Komma"**: everyday nouns many times over
    ///   (*auf den Punkt*, *Punkt zwölf*, *drei Komma eins*, *Kommaregeln*).
    ///   Rendering them unconditionally would corrupt ordinary prose. "Punkt"
    ///   still reaches the identifier renderer above, where both neighbors must
    ///   look like code; "Komma" still reaches `decimalComma` below, where both
    ///   neighbors must be digits.
    /// - **"Bindestrich" / "Gedankenstrich" as words**: "mit Bindestrich
    ///   schreiben" is a sentence about spelling, not a dictated hyphen.
    /// - **"Anführungszeichen"**: German needs to know *which* of „ and “ is
    ///   meant, and a lone spoken name can't say. `germanQuotationMarks` pairs
    ///   up whatever the transcriber produced instead.
    ///
    /// The names below are compound nouns that exist to name a mark, so the
    /// unconditional replacement is the same trade-off Apple's dictation and
    /// the Chinese pack make: dictating *about* a question mark renders one.
    /// Adjacent marks are absorbed, so an engine that already punctuated
    /// ("Kommt er? Fragezeichen") does not double up.
    static let spokenPunctuation = CleanupRule(
        name: "spoken punctuation names",
        stage: .early) { text, _ in
            var out = text
            for (names, mark) in spokenMarks {
                let alternation = names
                    .map { NSRegularExpression.escapedPattern(for: $0) }
                    .joined(separator: "|")
                out = replace(out,
                              pattern: "\\s*[.,;:!?]*\\s*\\b(?:\(alternation))\\b",
                              template: NSRegularExpression.escapedTemplate(for: mark),
                              options: [.caseInsensitive])
            }
            return out
        }

    /// Spoken names → mark. Longest-lived risk is the speaker talking *about*
    /// punctuation; see the note on `spokenPunctuation`.
    private static let spokenMarks: [(names: [String], mark: String)] = [
        (["fragezeichen"], "?"),
        // "Rufzeichen" is the Austrian name for the same mark.
        (["ausrufezeichen", "ausrufungszeichen", "rufzeichen"], "!"),
        (["doppelpunkt"], ":"),
        (["semikolon", "strichpunkt"], ";"),
        (["auslassungspunkte"], "…"),
    ]

    /// "Klammer auf … Klammer zu" → "(…)". German names the bracket before the
    /// direction, which the shared `SpokenSymbols` paren path (opener-then-noun,
    /// "open paren") cannot express — hence a rule of our own.
    ///
    /// The specific shapes run first so "eckige Klammer auf" is not claimed by
    /// the bare "Klammer auf" pattern.
    static let spokenBrackets = CleanupRule(
        name: "spoken brackets",
        stage: .early) { text, _ in
            var out = text
            for (adjective, open, close) in bracketShapes {
                let prefix = adjective.map { "\\b\(NSRegularExpression.escapedPattern(for: $0))\\s+" } ?? "(?:\\brunde\\s+)?"
                out = replace(out,
                              pattern: "\\s*\(prefix)klammer\\s+auf\\b\\s*",
                              template: " " + open,
                              options: [.caseInsensitive])
                out = replace(out,
                              pattern: "\\s*\(prefix)klammer\\s+zu\\b",
                              template: close,
                              options: [.caseInsensitive])
            }
            return out
        }

    /// Bracket shapes, most specific first. A nil adjective is the bare/"runde"
    /// form, which must be matched last.
    private static let bracketShapes: [(adjective: String?, open: String, close: String)] = [
        ("eckige", "[", "]"),
        ("geschweifte", "{", "}"),
        ("spitze", "<", ">"),
        (nil, "(", ")"),
    ]

    // MARK: - .afterPunctuation — numbers and spacing conventions

    /// German writes decimals with a comma — "3,14", not "3.14" (Duden,
    /// *Dezimalkomma*; DIN 5008). Two jobs:
    ///
    /// 1. Render a spoken decimal: "3 Komma 14" → "3,14". Both neighbours must
    ///    be digits, so the everyday noun ("ein Komma setzen") and a
    ///    spelled-out "drei Komma eins" — which is not a rendered number at
    ///    all — pass through untouched.
    /// 2. Repair the shared spacing pass, which inserts a space after every
    ///    comma and so turns a decimal the transcriber got right into "3, 14".
    ///
    /// The trade-off in (2): a dictated enumeration of bare digits ("3, 4 oder
    /// 5") is re-joined too. German dictation renders decimals as digits far
    /// more often than it renders a two-item digit list, and the repair has to
    /// run somewhere — this is the one place in the pipeline that knows German
    /// uses a decimal comma at all.
    ///
    /// Runs at `.afterPunctuation` for the same reason French's spacing rule
    /// does: declared `.early`, `fixPunctuationSpacing` would immediately undo
    /// it.
    static let decimalComma = CleanupRule(
        name: "decimal comma",
        stage: .afterPunctuation) { text, _ in
            var out = replace(text, pattern: "(\\d)\\s*\\bkomma\\b\\s*(\\d)",
                              template: "$1,$2", options: [.caseInsensitive])
            out = replace(out, pattern: "(\\d), (\\d)", template: "$1,$2")
            return out
        }

    /// A space belongs between a number and the sign that follows it —
    /// "50 %", "20 °C" — because the sign is read as the word it stands for
    /// (DIN 5008; Duden). Skips the code editor, where `%` is a format
    /// specifier or a modulo operator rather than a unit.
    static let unitSpacing = CleanupRule(
        name: "space between number and unit sign",
        stage: .afterPunctuation) { text, context in
            guard context.category != .codeEditor else { return text }
            var out = replace(text, pattern: "(\\d)\\s*%", template: "$1 %")
            out = replace(out, pattern: "(\\d)\\s*°\\s*([CF])\\b", template: "$1 °$2")
            return out
        }

    /// In German running text the currency sign follows the amount and is
    /// separated by a space — "12,50 €", never "€12,50" (DIN 5008). The
    /// leading-symbol form is an English-trained transcriber artifact.
    static let currencyAfterAmount = CleanupRule.regex(
        name: "currency sign follows the amount",
        stage: .afterPunctuation,
        pattern: "([€$£])\\s*(\\d+(?:[.,]\\d+)*)",
        template: "$2 $1")

    /// German's parenthetical dash is the Halbgeviertstrich – with spaces
    /// around it; the em dash — is an English convention (Duden,
    /// *Gedankenstrich*). Small models drift into the em dash constantly, so
    /// this earns its place mostly in the model path.
    static let emDashToGedankenstrich = CleanupRule.regex(
        name: "em dash becomes a Gedankenstrich",
        stage: .afterPunctuation,
        pattern: "\\s*—\\s*",
        template: " – ")

    // MARK: - .final — capitalization and typography

    /// Multi-part abbreviations take a space between their parts: "z. B.",
    /// "d. h.", "i. d. R." (Duden, *Schreibung mehrteiliger Abkürzungen*;
    /// DIN 5008). Transcribers reliably emit the run-together lowercase form
    /// ("z.b."), so the replacement also restores the casing.
    ///
    /// Runs at `.final`, after the shared sentence capitalizer, because the
    /// split creates a token ending in "." — and the capitalizer would then
    /// read "d. h." as two sentences and "correct" it to "d. H.". Placing the
    /// rule last both installs the spacing and repairs that casing if the
    /// transcriber had already split the abbreviation itself.
    static let abbreviationSpacing = CleanupRule(
        name: "multi-part abbreviation spacing",
        stage: .final) { text, _ in
            var out = text
            for (pattern, replacement) in abbreviationForms {
                out = replace(out, pattern: pattern,
                              template: NSRegularExpression.escapedTemplate(for: replacement),
                              options: [.caseInsensitive])
            }
            // An abbreviation opening the dictation still starts a sentence.
            // The shared capitalizer cannot do this one: "z.b." is not a plain
            // word to it, and by now it has run anyway.
            guard let first = out.first, first.isLowercase,
                  abbreviationForms.contains(where: { out.hasPrefix($0.1) }) else { return out }
            return String(first).uppercased() + out.dropFirst()
        }

    /// Pattern → canonical form. Ordered longest-first so "u. v. m." is not
    /// claimed piecemeal.
    private static let abbreviationForms: [(String, String)] = [
        ("\\bi\\.\\s*d\\.\\s*r\\.", "i. d. R."),
        ("\\bu\\.\\s*v\\.\\s*m\\.", "u. v. m."),
        ("\\bz\\.\\s*b\\.", "z. B."),
        ("\\bd\\.\\s*h\\.", "d. h."),
        ("\\bu\\.\\s*a\\.", "u. a."),
        ("\\bu\\.\\s*ä\\.", "u. Ä."),
        ("\\bo\\.\\s*ä\\.", "o. Ä."),
        ("\\bz\\.\\s*t\\.", "z. T."),
        ("\\bv\\.\\s*a\\.", "v. a."),
        ("\\bu\\.\\s*u\\.", "u. U."),
        ("\\bm\\.\\s*e\\.", "m. E."),
        ("\\bs\\.\\s*o\\.", "s. o."),
        ("\\bs\\.\\s*u\\.", "s. u."),
        ("\\bv\\.\\s*chr\\.", "v. Chr."),
        ("\\bn\\.\\s*chr\\.", "n. Chr."),
    ]

    /// Weekdays, months and the fixed feast days are nouns, so they are always
    /// capitalized (amtliches Regelwerk § 55: Substantive werden
    /// großgeschrieben). This is the one slice of German noun capitalization
    /// that is a *closed* class and therefore safe without a parser — every
    /// other noun needs the LLM.
    ///
    /// The derived adverbs stay lowercase ("montags", "sonntags"), which the
    /// trailing boundary already excludes. The symbol lookarounds keep
    /// identifiers and paths intact ("termin_montag", "montag.md"), and the
    /// rule sits out the code editor, where a bare `montag` is likely a
    /// variable.
    static let weekdayAndMonthCapitals = CleanupRule(
        name: "weekday, month and feast-day capitals",
        stage: .final) { text, context in
            guard context.category != .codeEditor else { return text }
            var out = text
            for word in alwaysCapitalizedNouns {
                // The trailing guard rejects an identifier neighbour but must
                // still allow sentence punctuation: "montag.md" is a file,
                // "am montag." is a sentence, so only a dot that is followed
                // by a word character blocks the capital.
                out = replace(out,
                              pattern: "(?<![\\p{L}\\p{N}._\\-/@~])\(word)(?![\\p{L}\\p{N}_\\-/@~]|\\.\\w)",
                              template: NSRegularExpression.escapedTemplate(
                                  for: word.prefix(1).uppercased() + word.dropFirst()))
            }
            return out
        }

    /// Matched case-sensitively in their lowercase form, so a shouted
    /// "MONTAG" is left as the speaker emphasized it.
    private static let alwaysCapitalizedNouns = [
        "montag", "dienstag", "mittwoch", "donnerstag", "freitag", "samstag",
        "sonnabend", "sonntag",
        "januar", "februar", "märz", "april", "mai", "juni", "juli", "august",
        "september", "oktober", "november", "dezember",
        "weihnachten", "ostern", "pfingsten", "silvester", "neujahr",
    ]

    /// A day before a month name is an ordinal and takes a period — "am 5. Mai"
    /// (Duden, *Ordinalzahlen*). Runs after the month has been capitalized so
    /// the pattern only has to know the canonical spelling, and requires a bare
    /// one- or two-digit number so a year ("1990 Mai") never matches.
    static let ordinalDatePeriod = CleanupRule.regex(
        name: "ordinal period in a spoken date",
        stage: .final,
        pattern: "\\b(\\d{1,2})\\s+(Januar|Februar|März|April|Mai|Juni|Juli|August|September|Oktober|November|Dezember)\\b",
        template: "$1. $2")

    /// The shared sentence capitalizer treats any token ending in "." as a
    /// sentence end, so "das ist z. B. mehr Arbeit" comes back as "… z. B. Mehr
    /// Arbeit". Undo it — but only for words that are *never* capitalized in
    /// German (articles, pronouns, prepositions, conjunctions, auxiliaries,
    /// adverbs). Every other word could legitimately be a noun, which German
    /// capitalizes, so it is left exactly as it is.
    ///
    /// Only abbreviations that essentially never end a sentence are considered:
    /// "usw." and "etc." routinely do, and lowercasing the next sentence's
    /// first word would be a worse bug than the one being fixed.
    static let noSentenceCapitalAfterAbbreviation = CleanupRule(
        name: "no sentence capital after a mid-sentence abbreviation",
        stage: .final) { text, _ in
            var tokens = text.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
            guard tokens.count > 1 else { return text }
            // Lowercased, because the shared capitalizer may have just
            // capitalized the abbreviation itself ("ca." at a sentence start).
            for index in 1..<tokens.count
            where midSentenceAbbreviationEndings.contains(tokens[index - 1].lowercased()) {
                let token = tokens[index]
                let core = token.trimmingCharacters(in: .punctuationCharacters)
                guard let first = core.first, first.isUppercase,
                      neverCapitalizedWords.contains(core.lowercased()) else { continue }
                tokens[index] = token.replacingOccurrences(
                    of: core, with: core.lowercased(), options: [], range: token.range(of: core))
            }
            return tokens.joined(separator: " ")
        }

    /// The *last* whitespace-separated piece of each abbreviation above, since
    /// that is the token that arms the shared capitalizer.
    private static let midSentenceAbbreviationEndings: Set<String> = [
        "b.", "h.", "r.", "t.",
        "ca.", "bzw.", "ggf.", "evtl.", "inkl.", "exkl.", "zzgl.", "vgl.",
        "bzgl.", "nr.", "mio.", "mrd.", "tel.", "dr.", "prof.", "st.",
        "abb.", "tab.", "chr.",
    ]

    /// Function words with no nominal reading. Deliberately excludes "sie",
    /// "ihr", "ihnen" (the polite address is capitalized — § 55 (3)), and every
    /// adjective that nominalizes ("das Gute", "etwas Neues").
    private static let neverCapitalizedWords: Set<String> = [
        "der", "die", "das", "den", "dem", "des",
        "ein", "eine", "einen", "einem", "einer", "eines",
        "und", "oder", "aber", "denn", "sondern", "sowie", "als", "wie",
        "wenn", "weil", "dass", "ob", "damit", "obwohl", "sobald", "während",
        "ich", "du", "er", "es", "wir", "man", "mich", "dich", "uns", "euch",
        "mir", "dir", "ihm", "sich",
        "mein", "meine", "dein", "deine", "sein", "seine", "unser", "unsere",
        "ist", "sind", "war", "waren", "bin", "bist", "wird", "werden",
        "wurde", "wurden", "hat", "haben", "hatte", "hatten",
        "kann", "können", "muss", "müssen", "soll", "sollen", "will",
        "wollen", "darf", "dürfen",
        "nicht", "kein", "keine", "nur", "noch", "schon", "auch", "sehr",
        "so", "dann", "da", "hier", "dort", "immer", "wieder", "jetzt",
        "heute", "gestern", "bald", "oft", "manchmal", "nie",
        "in", "im", "an", "am", "auf", "aus", "bei", "mit", "nach", "von",
        "vom", "vor", "zu", "zum", "zur", "über", "unter", "für", "um",
        "durch", "ohne", "gegen", "zwischen", "seit", "bis",
        "mehr", "weniger", "viel", "viele", "alle", "jeder", "einige",
        "etwas", "nichts", "ganz", "ziemlich", "fast", "etwa", "ungefähr",
        "natürlich", "vielleicht", "eigentlich", "wirklich",
    ]

    /// The dictation commands for a line break, in the wording Apple's German
    /// dictation uses. Guarded against the ordinary noun phrase: "eine neue
    /// Zeile einfügen" keeps its words because a determiner precedes "neue".
    ///
    /// Runs at `.final` so the newline survives the shared whitespace collapse,
    /// and capitalizes the word that follows it — the sentence capitalizer has
    /// already run by then and cannot do it for us.
    static let dictatedLineBreaks = CleanupRule(
        name: "dictated line breaks",
        stage: .final) { text, _ in
            var out = text
            for (pattern, replacement) in lineBreakForms {
                out = replace(out, pattern: pattern, template: replacement,
                              options: [.caseInsensitive])
            }
            guard out.contains("\n") else { return out }
            return capitalizeAfterNewlines(out)
        }

    /// A determiner before the phrase means it is an ordinary noun phrase, not
    /// a dictation command. The lookbehind sits *after* the leading `\s*` on
    /// purpose: in front of it the engine can start the match at the space
    /// itself, where the determiner is no longer immediately behind.
    private static let lineBreakForms: [(String, String)] = [
        ("\\s*(?<!\\b(?:eine|die|der|jede|diese|keine|meine|deine|welche)\\s)\\bneue\\s+zeile\\b\\s*", "\n"),
        ("\\s*(?<!\\b(?:einen|den|jeden|diesen|keinen|meinen|deinen|welchen)\\s)\\bneuer\\s+absatz\\b\\s*", "\n\n"),
        ("\\s*(?<!\\b(?:die|eine|jede|diese|keine|meine|deine|welche)\\s)\\bnächste\\s+zeile\\b\\s*", "\n"),
    ]

    private static func capitalizeAfterNewlines(_ text: String) -> String {
        var out = ""
        var atLineStart = false
        for character in text {
            if atLineStart, character.isLowercase {
                out += String(character).uppercased()
                atLineStart = false
            } else {
                out.append(character)
                if character == "\n" { atLineStart = true }
                else if !character.isWhitespace { atLineStart = false }
            }
        }
        return out
    }

    /// German quotation marks are „unten“ then “oben” (Duden,
    /// *Anführungszeichen*). Only a balanced pair on one line is converted, so
    /// a stray quote is left alone, and the code editor is skipped entirely —
    /// there a double quote is a string literal.
    static let germanQuotationMarks = CleanupRule(
        name: "German quotation marks",
        stage: .final) { text, context in
            guard context.category != .codeEditor else { return text }
            return replace(text, pattern: "\"([^\"\\n]{1,400})\"", template: "„$1“")
        }

    /// German's apostrophe is the typographic ’, not the ASCII ' (Duden,
    /// *Apostroph*): geht’s, hab’s, so ’ne. Requires a letter on both sides so
    /// a quoting apostrophe is never touched, and skips the code editor.
    ///
    /// Runs at `.final` because the shared capitalizer does not consider ’ part
    /// of a word: converting earlier would stop "geht’s los" gaining its
    /// sentence capital.
    static let typographicApostrophe = CleanupRule(
        name: "typographic apostrophe",
        stage: .final) { text, context in
            guard context.category != .codeEditor else { return text }
            return replace(text, pattern: "(?<=\\p{L})'(?=\\p{L})", template: "’")
        }

    // MARK: - Helpers

    /// Same shape as `CleanupRule.regex`'s body: a failed pattern degrades to
    /// "no change" rather than crashing a dictation.
    private static func replace(_ text: String, pattern: String, template: String,
                                options: NSRegularExpression.Options = []) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [],
                                              range: range, withTemplate: template)
    }
}
