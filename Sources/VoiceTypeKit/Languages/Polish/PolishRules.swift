import Foundation

extension LanguagePack {
    /// Polish's own deterministic fixes — the conventions the pack's
    /// declarative fields don't ask about. Every rule here is an orthographic
    /// fact, not a stylistic preference: Polish punctuation is codified by the
    /// PWN rules, so "always right" is a claim that can actually be checked.
    ///
    /// Order matters within a stage. `.early` runs on raw text (so `...`
    /// becomes `…` before the shared pass collapses repeated dots into one);
    /// `.afterPunctuation` runs once spacing and `SpokenSymbols` have had their
    /// say (so a `kropka` that joined a file name is already gone before the
    /// prose renderer looks at the leftovers); `.final` sees the finished
    /// sentence, including a question mark the shared heuristic just appended.
    static let polishRules: [CleanupRule] = [
        // MARK: .early

        // Wielokropek is ONE character in Polish typography, and it must be
        // written before `fixPunctuationSpacing` collapses "..." to ".".
        .regex(name: "pl: ellipsis becomes wielokropek",
               stage: .early,
               pattern: "\\.{3,}",
               template: "…"),

        // Elongated hesitation runs the fixed-string filler matcher can't
        // express: "yyyy", "eeee", "mmmm", "hmmm". No Polish word repeats y, e
        // or m that many times, and the lookarounds keep the match off word
        // interiors. "mm" is excluded on purpose — it is millimetres.
        .regex(name: "pl: elongated hesitation runs",
               stage: .early,
               pattern: "(?i)(?<![\\p{L}\\p{N}])(?:y{2,}|e{3,}|m{3,}|hm{2,})(?![\\p{L}\\p{N}]),?",
               template: " "),

        // Spoken symbols → characters: file names, identifiers, handles,
        // e-mail addresses, and (in a terminal) flags and paths. Runs first,
        // and in the terminal too, so a `kropka` that belongs to `main.py` is
        // gone before the prose renderer below looks for sentence marks.
        // See `PolishSpokenCode`.
        CleanupRule(name: "pl: spoken symbols in code and paths",
                    stage: .early,
                    runsInTerminal: true) { text, context in
            PolishSpokenCode.render(text, category: context.category)
        },

        // Polish writes decimals with a comma (3,14 — never 3.14), and the
        // shared Latin spacing pass, which puts a space after every comma,
        // splits them into "3, 14". Park the ones the transcriber already
        // wrote *tight* — that tightness is the evidence it's a decimal and
        // not a list — and restore them once that pass has gone by. A list
        // dictated as "1, 2, 3" arrives with spaces and is left alone.
        .regex(name: "pl: park the decimal comma",
               stage: .early,
               pattern: "(?<=\\p{N}),(?=\\p{N})",
               template: PolishSpokenMarks.decimalCommaSentinel),

        // MARK: .afterPunctuation

        // Spoken punctuation names → marks, in the positions where the noun
        // reading is implausible. See `PolishSpokenMarks`.
        CleanupRule(name: "pl: spoken punctuation names in prose",
                    stage: .afterPunctuation) { text, _ in
            PolishSpokenMarks.render(text)
        },

        // The obligatory comma before a subordinate clause — the single
        // biggest gap between what a Polish transcriber emits and what Polish
        // orthography requires. See `PolishClauseCommas`.
        CleanupRule(name: "pl: comma before a subordinate clause",
                    stage: .afterPunctuation) { text, _ in
            PolishClauseCommas.insert(into: text)
        },

        // Sentence-opening parentheticals and participial phrases
        // (imiesłowowy równoważnik zdania) are always cut off by a comma.
        // The lookahead requires whitespace right after the phrase, so a
        // comma that is already there stops the rule from doubling it.
        .regex(name: "pl: comma after a sentence-opening parenthetical",
               stage: .afterPunctuation,
               pattern: "(?i)^(co ciekawe|co więcej|co gorsza|co gorsze|co ważne|co istotne|jak wiadomo|jak widać|jak mówiłem|jak mówiłam|innymi słowy|krótko mówiąc|prawdę mówiąc|szczerze mówiąc|ogólnie rzecz biorąc)(?=\\s+\\S)",
               template: "$1,"),

        // A hyphen standing alone between words is a myślnik, which Polish
        // typography sets as a półpauza (–) with spaces on both sides.
        // Compounds ("polsko-niemiecki", "e-mail") carry no spaces and are
        // untouched; so is a code editor, where "-" is an operator.
        .polishProse(name: "pl: spaced hyphen becomes półpauza",
                     stage: .afterPunctuation) { text in
            text.replacingOccurrences(of: "(?<=\\S) [-−] (?=\\S)",
                                      with: " – ",
                                      options: .regularExpression)
        },

        // Polish quotes are „…”, not "…". Only a *matched* straight or curly
        // pair is converted, so an unpaired quote is left exactly as dictated.
        // Skipped in a code editor, where a quote is a string delimiter.
        .polishProse(name: "pl: straight quotes become cudzysłów apostrofowy",
                     stage: .afterPunctuation) { text in
            text.replacingOccurrences(of: "\"([^\"\\n]*)\"",
                                      with: "„$1”",
                                      options: .regularExpression)
                .replacingOccurrences(of: "“([^”\\n]*)”",
                                      with: "„$1”",
                                      options: .regularExpression)
        },

        // Re-tighten spacing around the marks the rules above inserted as
        // standalone tokens. The shared `fixPunctuationSpacing` has already
        // run by this stage, so Polish has to finish its own work.
        CleanupRule(name: "pl: tighten spacing around inserted marks",
                    stage: .afterPunctuation) { text, _ in
            PolishSpokenMarks.tighten(text)
        },

        // Give the parked decimal commas back, now that every pass which
        // would have put a space after them has run.
        .regex(name: "pl: restore the decimal comma",
               stage: .afterPunctuation,
               pattern: PolishSpokenMarks.decimalCommaSentinel,
               template: ","),

        // MARK: .final

        // The shared question heuristic fires on an opening interrogative
        // word, which in Polish also opens two very common non-questions:
        // the correlative "Jak …, to …" frame ("Jak skończysz, to daj znać")
        // and the set phrases "Co ciekawe", "Jak wiadomo". Take the mark back.
        CleanupRule(name: "pl: not every jak/kiedy/co opening is a question",
                    stage: .final) { text, _ in
            PolishQuestions.demoteFalsePositive(text)
        },
    ]
}

// MARK: - Prose-only rules

extension CleanupRule {
    /// A rule that applies to prose only. Rules already sit out the terminal by
    /// default; this also excludes a code editor, where a dictated `"` is a
    /// string delimiter and a `-` is an operator — typographic "corrections"
    /// there are corruption, exactly as they are in a shell.
    static func polishProse(name: String,
                            stage: Stage,
                            transform: @escaping @Sendable (String) -> String) -> CleanupRule {
        CleanupRule(name: name, stage: stage) { text, context in
            context.category == .codeEditor ? text : transform(text)
        }
    }
}

// MARK: - Spoken punctuation

/// Polish spoken punctuation, rendered by position rather than unconditionally.
///
/// The pack's `spokenPunctuation` table replaces every occurrence of a name,
/// which is fine for Chinese (句号 means nothing but "full stop") and wrong for
/// Polish, where the two names people actually say are ordinary nouns:
/// `kropka` is a dot, a polka dot and the idiom `i kropka` ("and that's that"),
/// and `przecinek` is how every Polish speaker reads a decimal point
/// ("trzy przecinek czternaście" = 3,14). So each name is rendered only where
/// its noun reading is implausible.
///
/// This runs at `.afterPunctuation`, i.e. after `SpokenSymbols` — a `kropka`
/// that belonged to `main.py` has already been consumed by then, and what is
/// left over is prose.
enum PolishSpokenMarks {
    /// Names that only ever denote the mark. No position guard needed.
    private static let unambiguous: [[String]: String] = [
        ["pytajnik"]: "?",
        ["znak", "zapytania"]: "?",
        ["wykrzyknik"]: "!",
        ["dwukropek"]: ":",
        ["średnik"]: ";",
        ["wielokropek"]: "…",
        ["myślnik"]: "–",
        ["nowy", "akapit"]: "\n\n",
        ["nowy", "wiersz"]: "\n",
        ["nowa", "linia"]: "\n",
        ["otwórz", "cudzysłów"]: "„",
        ["cudzysłów", "otwierający"]: "„",
        ["zamknij", "cudzysłów"]: "”",
        ["cudzysłów", "zamykający"]: "”",
    ]

    /// Words that make a following `kropka` the noun, not the command:
    /// `i kropka` / `a kropka` is the idiom, `kropka nad i` is the proverb,
    /// and `jest kropka` / `to kropka` describe a dot rather than dictating one.
    private static let dotBlockersBefore: Set<String> = [
        "i", "a", "oraz", "ani", "jest", "to", "ta", "jedna", "czerwona",
    ]
    private static let dotBlockersAfter: Set<String> = ["nad"]

    /// Placeholder standing in for a decimal comma between the `.early` rule
    /// that parks it and the `.afterPunctuation` rule that restores it. A
    /// private-use scalar, so it can never collide with dictated text.
    static let decimalCommaSentinel = "\u{E000}"

    /// Polish cardinals, so "trzy przecinek czternaście" stays a number
    /// instead of becoming "trzy, czternaście".
    private static let numberWords: Set<String> = [
        "zero", "jeden", "jedna", "jedno", "dwa", "dwie", "trzy", "cztery",
        "pięć", "sześć", "siedem", "osiem", "dziewięć", "dziesięć",
        "jedenaście", "dwanaście", "trzynaście", "czternaście", "piętnaście",
        "szesnaście", "siedemnaście", "osiemnaście", "dziewiętnaście",
        "dwadzieścia", "trzydzieści", "czterdzieści", "pięćdziesiąt",
        "sześćdziesiąt", "siedemdziesiąt", "osiemdziesiąt", "dziewięćdziesiąt",
        "sto", "dwieście", "trzysta", "czterysta", "pięćset", "sześćset",
        "siedemset", "osiemset", "dziewięćset", "tysiąc", "tysiące", "milion",
        "setnych", "dziesiątych", "tysięcznych",
    ]

    static func render(_ text: String) -> String {
        var tokens = text.components(separatedBy: " ")
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            let word = core(tokens[i])
            // Two-word names first, so "znak zapytania" isn't shadowed.
            if i + 1 < tokens.count, let mark = unambiguous[[word, core(tokens[i + 1])]] {
                out.append(mark)
                i += 2
                continue
            }
            if let mark = unambiguous[[word]] {
                out.append(mark)
                i += 1
                continue
            }
            if word == "kropka", rendersDot(at: i, tokens: tokens, out: out) {
                out.append(".")
                i += 1
                continue
            }
            if word == "przecinek", rendersComma(at: i, tokens: tokens, out: out) {
                out.append(",")
                i += 1
                continue
            }
            out.append(tokens[i])
            i += 1
        }
        return out.joined(separator: " ")
    }

    /// Collapse the whitespace the standalone mark tokens left behind, and
    /// glue the marks to the words they belong to. Mirrors what the shared
    /// `fixPunctuationSpacing` does, re-run because Polish inserts marks after
    /// that pass has already gone by.
    static func tighten(_ text: String) -> String {
        var out = text
        // A mark never keeps whitespace in front of it …
        out = out.replacingOccurrences(of: "[ \\t]+([,.!?;:…”])", with: "$1",
                                       options: .regularExpression)
        // … and an opening quote or bracket never keeps whitespace behind it.
        out = out.replacingOccurrences(of: "([„(\\[])[ \\t]+", with: "$1",
                                       options: .regularExpression)
        out = out.replacingOccurrences(of: "[ \\t]+([)\\]])", with: "$1",
                                       options: .regularExpression)
        // A comma or closing mark is followed by exactly one space. "." and
        // ":" are excluded for the same reason the shared pass excludes them:
        // they live inside main.py and 5:30.
        out = out.replacingOccurrences(of: "([,!?;…])(?=[\\p{L}\\p{N}„])", with: "$1 ",
                                       options: .regularExpression)
        // Spoken newlines arrive as their own token, so strip the padding.
        out = out.replacingOccurrences(of: "[ \\t]*\\n[ \\t]*", with: "\n",
                                       options: .regularExpression)
        out = out.replacingOccurrences(of: "[ \\t]{2,}", with: " ",
                                       options: .regularExpression)
        // The speaker said the name AND the engine already rendered the mark
        // ("czy to działa? znak zapytania"): the dictated mark wins once.
        out = out.replacingOccurrences(of: "([.!?])[.!?]+", with: "$1",
                                       options: .regularExpression)
        return out
    }

    /// A spoken `kropka` becomes "." only where it cannot be the noun: it must
    /// follow an ordinary word, and it must either end the dictation or be
    /// followed by something that starts a new sentence. "Czerwona kropka jest
    /// duża" ("the red dot is big") therefore survives as prose.
    private static func rendersDot(at index: Int, tokens: [String], out: [String]) -> Bool {
        guard let previous = out.last, isPlainWord(previous) else { return false }
        guard !dotBlockersBefore.contains(core(previous)) else { return false }
        guard index + 1 < tokens.count else { return true }
        let next = tokens[index + 1]
        guard !dotBlockersAfter.contains(core(next)) else { return false }
        return next.first?.isUppercase == true
    }

    /// A spoken `przecinek` becomes "," unless it sits between numbers, where
    /// every Polish speaker is reading a decimal point aloud.
    private static func rendersComma(at index: Int, tokens: [String], out: [String]) -> Bool {
        guard let previous = out.last, isPlainWord(previous),
              !isNumeric(previous) else { return false }
        guard index + 1 < tokens.count else { return false }
        let next = tokens[index + 1]
        return !isNumeric(next) && next.first?.isLowercase == true
    }

    private static func isNumeric(_ token: String) -> Bool {
        let word = core(token)
        return numberWords.contains(word) || word.allSatisfy { $0.isNumber }
    }

    private static func isPlainWord(_ token: String) -> Bool {
        let word = core(token)
        return !word.isEmpty && word.allSatisfy { $0.isLetter }
    }

    /// The token's word, lowercased and stripped of the punctuation a
    /// transcriber may have hung off it.
    static func core(_ token: String) -> String {
        token.trimmingCharacters(in: .punctuationCharacters).lowercased()
    }
}

// MARK: - Clause commas

/// The obligatory comma before a subordinate clause.
///
/// Polish interpunkcja is grammatical, not prosodic: PWN's rules require a
/// comma before the word that opens a subordinate clause (`że`, `ponieważ`,
/// `który`, …), and no transcriber puts one in. A native reader sees the
/// missing comma as an error, which makes this the highest-value deterministic
/// fix the language has.
///
/// It is not, however, a rule without exceptions, and every exception here is
/// resolved the safe way — by *not* inserting:
/// - Two conjunctions in a row take one comma, before the first ("…, i że …").
/// - Compound conjunctions take the comma before their first element
///   ("…, dlatego że …", "…, chyba że …", "…, mimo że …"), which this does not
///   attempt to place, so those are skipped entirely.
/// - A relative pronoun governed by a preposition puts the comma before the
///   preposition ("dom, w którym mieszkam"), which *is* handled.
/// - `choć` / `chociaż` are excluded: they also mean "at least"
///   ("daj mi choć trochę"), where a comma would be wrong.
enum PolishClauseCommas {
    /// Conjunctions and particles that already carry the clause boundary, so
    /// the comma belongs before *them*, not before the trigger word.
    private static let sharedBlockers: Set<String> = [
        "i", "a", "oraz", "lub", "albo", "ani", "bądź", "ale", "lecz", "czy",
        "no", "więc", "zaś", "natomiast",
    ]

    /// Every trigger is also a blocker: two subordinators in a row take one
    /// comma, before the first.
    private static let triggerWords: Set<String> = relativeWords.union([
        "że", "iż", "żeby", "aby", "ażeby", "ponieważ", "gdyż", "bo",
        "jeśli", "jeżeli", "gdyby", "gdy", "skoro",
    ])

    /// Relative pronouns and the interrogatives that open an *indirect*
    /// question ("Nie wiem, kiedy wrócę"). Both take a comma, and both can be
    /// governed by a preposition that the comma has to jump over.
    ///
    /// `co`, `jak` and `czy` are deliberately absent: `nie ma co czekać`,
    /// `zrób to tak jak ja` and `dwa czy trzy` take no comma at all, and
    /// nothing in the token stream distinguishes them from the clause reading.
    private static let relativeWords: Set<String> = [
        "który", "która", "które", "którzy", "którego", "której", "któremu",
        "którym", "którą", "których", "którymi",
        "kiedy", "gdzie", "dokąd", "skąd", "dlaczego",
        "kto", "kogo", "komu", "kim", "ile", "ilu",
    ]

    /// Prepositions that govern a relative pronoun. "…, w którym …" takes the
    /// comma before the preposition, not before the pronoun.
    private static let prepositions: Set<String> = [
        "w", "we", "z", "ze", "o", "do", "od", "ode", "na", "po", "za", "przy",
        "przez", "dla", "u", "ku", "nad", "nade", "pod", "pode", "przed",
        "przede", "między", "bez", "wobec", "wśród", "obok", "koło",
    ]

    private struct Trigger {
        let blockers: Set<String>
        let liftsPreposition: Bool
    }

    private static func trigger(for word: String) -> Trigger? {
        switch word {
        case "że", "iż":
            // The compound conjunctions: "dlatego że", "mimo że", "chyba że",
            // "tylko że", "zwłaszcza że", "jako że", "tym bardziej że",
            // "tyle że", "tak że". Each takes its comma one word earlier, so
            // Polish's own rule is to leave them alone rather than guess.
            return Trigger(blockers: sharedBlockers.union(triggerWords).union([
                "dlatego", "mimo", "pomimo", "chyba", "tylko", "zwłaszcza",
                "jako", "bardziej", "tyle", "poza", "oprócz", "prócz",
                "wobec", "wprawdzie", "tak", "właśnie", "podczas",
            ]), liftsPreposition: false)
        case "bo":
            return Trigger(blockers: sharedBlockers.union(triggerWords).union([
                "tylko", "właśnie", "dlatego",
            ]), liftsPreposition: false)
        case "jeśli", "jeżeli", "gdyby", "gdy", "skoro":
            // "jak gdyby" ("as if") and "podczas gdy" ("while") are fixed
            // phrases: the first takes no comma, the second takes it before
            // "podczas".
            return Trigger(blockers: sharedBlockers.union(triggerWords).union([
                "nawet", "chyba", "tylko", "jak", "tak", "podczas",
            ]), liftsPreposition: false)
        case "żeby", "aby", "ażeby", "ponieważ", "gdyż":
            return Trigger(blockers: sharedBlockers.union(triggerWords),
                           liftsPreposition: false)
        default:
            guard relativeWords.contains(word) else { return nil }
            // "mało kto wie", "byle gdzie", "rzadko kiedy" are quantifier
            // phrases, not clauses — no comma inside them.
            return Trigger(blockers: sharedBlockers.union(triggerWords).union([
                "mało", "byle", "rzadko", "nie",
            ]), liftsPreposition: true)
        }
    }

    static func insert(into text: String) -> String {
        var tokens = text.components(separatedBy: " ")
        guard tokens.count >= 3 else { return text }
        var index = 1
        while index < tokens.count {
            defer { index += 1 }
            guard let trigger = trigger(for: PolishSpokenMarks.core(tokens[index])) else {
                continue
            }
            // Move the insertion point in front of a governing preposition.
            var target = index
            if trigger.liftsPreposition, index >= 2,
               prepositions.contains(PolishSpokenMarks.core(tokens[index - 1])) {
                target = index - 1
            }
            guard target >= 1 else { continue }
            let previous = tokens[target - 1]
            // Only after a bare word: an existing mark means the boundary is
            // already there, and anything with a symbol in it ("main.py",
            // "get_user", "2020") is not prose and must not be punctuated.
            guard !previous.isEmpty,
                  previous.allSatisfy({ $0.isLetter }) else { continue }
            guard !trigger.blockers.contains(previous.lowercased()) else { continue }
            tokens[target - 1] = previous + ","
        }
        return tokens.joined(separator: " ")
    }
}

// MARK: - Question-mark false positives

enum PolishQuestions {
    /// Openings that look interrogative to the shared first-word heuristic but
    /// are not questions in Polish.
    private static let patterns: [String] = [
        // The correlative frame: "Jak skończysz, to daj znać." The comma +
        // "to" is what makes it a conditional/temporal clause rather than a
        // question; "Jak to zrobić?" has no comma and stays a question.
        "(?i)^(?:jak|kiedy|gdy|gdyby|jeśli|jeżeli|skoro)\\b[^?]*,\\s+to\\b[^?]*\\?$",
        // Set phrases: "Co ciekawe, …", "Co więcej, …", "Co gorsza, …".
        "(?i)^co\\s+(?:ciekawe|więcej|gorsza|gorsze|ważne|istotne|prawda|do)\\b[^?]*\\?$",
        // "Jak wiadomo, …", "Jak widać, …", "Jak mówiłem, …".
        "(?i)^jak\\s+(?:wiadomo|widać|mówiłem|mówiłam|wspomniałem|wspomniałam|zwykle|zawsze)\\b[^?]*\\?$",
    ]

    static func demoteFalsePositive(_ text: String) -> String {
        guard text.hasSuffix("?") else { return text }
        for pattern in patterns where text.range(of: pattern, options: .regularExpression) != nil {
            return String(text.dropLast()) + "."
        }
        return text
    }
}
