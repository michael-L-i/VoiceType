import Foundation

/// Swedish's own deterministic fixes — everything the pack's declarative
/// fields can't express. Every rule here runs in *both* cleanup paths (the
/// zero-latency `RuleBasedCleanup` floor and `CleanupPolish`'s repair of model
/// output), so Swedish orthography holds however the text was produced.
///
/// Sources for the orthographic claims, in order of the rules below:
/// - Apple Support, "Kommandon för textdiktering på datorn" (sv-SE) — the
///   spoken names of punctuation and symbols Swedish users already dictate.
/// - Svenska skrivregler (Språkrådet) §12.14.1 / §13.1.2 — a space between a
///   figure and %, °, and other symbols read aloud as words.
/// - Svenska skrivregler — Swedish quotation marks are ”…”: the same
///   nine-shaped mark before and after; never the English “…”.
/// - Svenska skrivregler / Språkrådet — an abbreviation's period does not end
///   a sentence, so the next word stays lowercase ("t.ex. detta").
/// - Språkrådet / SAOL — veckodagar och månader are common nouns in Swedish
///   and are written with a lowercase initial.
enum SwedishRules {
    static let all: [CleanupRule] = [
        protectDecimalComma,
        spokenSymbols,
        restoreDecimalComma,
        spokenPunctuation,
        symbolSpacing,
        quotationMarks,
        abbreviationCase,
        calendarCase,
        whereQuestion,
    ]

    // MARK: - Decimal comma (.early → .afterPunctuation)

    /// Swedish writes decimals with a comma — 3,14 — and the shared Latin
    /// spacing pass puts a space after every comma that is followed by a
    /// non-space, which splits every decimal number in the language into two.
    ///
    /// The two readings are indistinguishable *after* that pass ("3, 14" could
    /// have been the decimal 3,14 or the enumeration "3, 4"), so the decimal
    /// is marked while it is still tight and unmarked once the spacing pass
    /// has run. Only a comma the speaker's transcriber emitted with no space
    /// is protected; a genuine enumeration arrives spaced and is left alone.
    ///
    /// The marker is a Private Use Area scalar, which no transcriber emits,
    /// and both halves live in this pack and share a terminal opt-out, so the
    /// marker can never outlive the pass that introduced it.
    private static let decimalMarker = "\u{E000}"

    static let protectDecimalComma = CleanupRule.regex(
        name: "protect the decimal comma from the shared spacing pass",
        stage: .early,
        pattern: #"(\d),(\d)"#,
        template: "$1\(decimalMarker)$2")

    static let restoreDecimalComma = CleanupRule.regex(
        name: "restore the decimal comma",
        stage: .afterPunctuation,
        pattern: decimalMarker,
        template: ",")

    // MARK: - Spoken symbols (.early)

    /// Runs the shared `SpokenSymbols` token pipeline with the Swedish
    /// vocabulary, so "main punkt paj" → `main.py`, "max understreck försök" →
    /// `max_försök`, "tilde snedstreck projekt" → `~/projekt`.
    ///
    /// Declared as a rule rather than via `LanguagePack.symbols` for two
    /// reasons: the shared field is currently asserted to be English-only by
    /// `EnglishPackTests`, and — more usefully — the field only feeds the
    /// rules floor, while a rule also runs over model output, where the
    /// pipeline never ran before.
    ///
    /// It opts into the terminal because that is where it earns the most
    /// (flags and paths), and because it cannot corrupt a command: with no
    /// Swedish trigger word present it is the identity function.
    static let spokenSymbols = CleanupRule(
        name: "spoken symbols → identifiers, paths and file names",
        stage: .early,
        runsInTerminal: true) { text, context in
            let vocabulary: SpokenSymbolVocabulary =
                context.category == .terminal ? .swedishTerminal : .swedish
            return SpokenSymbols.render(text, category: context.category,
                                        vocabulary: vocabulary)
        }

    // MARK: - Spoken punctuation (.afterPunctuation)

    /// Renders the Swedish names of punctuation marks. Runs *after* the shared
    /// spacing pass — and after `spokenSymbols` — so a "punkt" that belonged
    /// to a file name has already been consumed, and so the spacing this rule
    /// produces is final.
    ///
    /// Two classes of name:
    /// - Unambiguous compounds (`frågetecken`, `utropstecken`, `semikolon`,
    ///   `kolon`, `kommatecken`, `procenttecken`, `vänsterparentes`,
    ///   `högerparentes`, `citattecken`, `tankstreck`, `ellips`): these mean
    ///   the mark and nothing else, so they render unconditionally — the same
    ///   trade-off iOS dictation makes, i.e. dictating *about* a mark renders
    ///   it.
    /// - `punkt`, `bindestreck`, `ny rad`, `nytt stycke`: everyday words, so
    ///   they render only in positions where the ordinary reading is
    ///   impossible. See `looksLikeSentenceEnd`.
    ///
    /// `komma` is absent on purpose: it is the verb "to come".
    static let spokenPunctuation = CleanupRule(
        name: "spoken punctuation names → marks",
        stage: .afterPunctuation) { text, _ in
            render(text)
        }

    /// Marks that glue onto the preceding word.
    private static let trailingMarks: [String: String] = [
        "frågetecken": "?",
        "utropstecken": "!",
        "semikolon": ";",
        "kolon": ":",
        "kommatecken": ",",
        "högerparentes": ")",
        "ellips": "…",
    ]

    /// Marks that stand as their own space-separated token. Swedish writes a
    /// space before % (Svenska skrivregler §12.14.1) and spaces around a
    /// parenthetical tankstreck.
    private static let standaloneMarks: [String: String] = [
        "procenttecken": "%",
        "tankstreck": "–",
    ]

    /// Words that make a following bare `punkt` (or `ny rad` / `nytt stycke`)
    /// the noun rather than the mark: determiners, quantifiers, possessives
    /// and prepositions. Probed one *and* two tokens back, so an adjective in
    /// between still shields it — "en svag punkt" is a weak spot, not a
    /// sentence end.
    private static let nounCues: Set<String> = [
        "en", "ett", "den", "det", "denna", "detta", "dessa", "varje",
        "någon", "något", "några", "ingen", "inget", "inga", "samma",
        "sista", "första", "andra", "tredje", "fjärde", "nästa", "förra",
        "min", "mitt", "din", "ditt", "sin", "sitt", "vår", "vårt", "er",
        "ert", "flera", "alla", "vilken", "vilket", "vissa", "enda",
        "på", "i", "om", "av", "med", "vid", "till", "från", "under",
        "över", "efter", "före", "kring", "per", "för", "mot", "utan",
        "genom", "som",
    ]

    /// Words after a bare `punkt` that make it the noun: "punkt tre", "punkt
    /// för punkt", "punkt slut" (the fixed idiom, which is written out).
    private static let nounFollowers: Set<String> = [
        "ett", "en", "två", "tre", "fyra", "fem", "sex", "sju", "åtta",
        "nio", "tio", "elva", "tolv", "och", "eller", "för", "slut",
        "nummer", "där", "som", "i", "på", "efter",
    ]

    private static let absorbable = ",.!?;:…"
    private static let trimmable = CharacterSet(charactersIn: ",.!?;:…\"")

    private static func core(_ token: String) -> String {
        token.trimmingCharacters(in: trimmable).lowercased()
    }

    /// True when a token can be half of a dictated hyphenation
    /// ("svensk bindestreck engelsk") — a word-like token that is not a
    /// function word, so "sätt ett bindestreck där" stays prose.
    private static func isJoinablePart(_ token: String) -> Bool {
        let stripped = token.trimmingCharacters(in: trimmable)
        return !stripped.isEmpty
            && stripped.allSatisfy { $0.isLetter || $0.isNumber || "._-".contains($0) }
            && !LanguagePack.swedishStopwords.contains(stripped.lowercased())
    }

    /// Whether the bare `punkt` at `index` is the sentence-ending mark rather
    /// than the noun "point/item". Conservative in both directions: it must
    /// have something to attach to, no determiner or preposition within two
    /// tokens to its left, and nothing enumerable to its right.
    private static func looksLikeSentenceEnd(_ tokens: [String], _ index: Int) -> Bool {
        guard index > 0 else { return false }
        if nounCues.contains(core(tokens[index - 1])) { return false }
        if index >= 2, nounCues.contains(core(tokens[index - 2])) { return false }
        guard index + 1 < tokens.count else { return true }
        let next = core(tokens[index + 1])
        if nounFollowers.contains(next) { return false }
        if let first = next.first, first.isNumber { return false }
        return true
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func render(_ text: String) -> String {
        let tokens = text.split(separator: " ").map(String.init)
        guard tokens.count > 1 else { return text }

        var out: [String] = []
        var pendingPrefix = ""
        var glueToPrevious = false
        var capitalizeNext = false
        var quoteOpen = false

        /// Append a word, honoring a pending opening mark and a pending
        /// capital from the mark that just closed a sentence.
        func emit(_ raw: String) {
            var word = raw
            if capitalizeNext, let first = word.first, first.isLowercase,
               word.allSatisfy({ $0.isLetter }) {
                word = String(first).uppercased() + word.dropFirst()
            }
            capitalizeNext = false
            let piece = pendingPrefix + word
            pendingPrefix = ""
            if glueToPrevious, !out.isEmpty {
                out[out.count - 1] += piece
                glueToPrevious = false
            } else {
                out.append(piece)
            }
        }

        /// Glue a mark onto the previous word. `absorbing` swallows any mark
        /// already sitting there, so a transcriber that punctuated the
        /// hesitation ("det var bra. punkt") doesn't produce "bra..".
        func attach(_ mark: String, absorbing: Bool = false) {
            guard !out.isEmpty else { pendingPrefix += mark; return }
            var last = out[out.count - 1]
            if absorbing {
                while let character = last.last, absorbable.contains(character),
                      last.count > 1 {
                    last.removeLast()
                }
            }
            out[out.count - 1] = last + mark
        }

        var i = 0
        while i < tokens.count {
            let token = tokens[i]
            let word = core(token)

            // "ny rad" / "nytt stycke" — two tokens, and only when no
            // determiner precedes ("på en ny rad" is prose).
            if word == "ny" || word == "nytt", i + 1 < tokens.count, !out.isEmpty {
                let next = core(tokens[i + 1])
                let isBreak = (word == "ny" && next == "rad")
                    || (word == "nytt" && (next == "stycke" || next == "paragraf"))
                if isBreak, !nounCues.contains(core(tokens[i - 1])) {
                    attach(next == "rad" ? "\n" : "\n\n")
                    glueToPrevious = true
                    capitalizeNext = true
                    i += 2
                    continue
                }
            }

            // "svensk bindestreck engelsk" → svensk-engelsk. Both neighbors
            // must be content words; the shared pipeline already handled the
            // single-letter handle case ("michael bindestreck L").
            if word == "bindestreck", i + 1 < tokens.count,
               let left = out.last, isJoinablePart(left),
               isJoinablePart(tokens[i + 1]) {
                attach("-")
                glueToPrevious = true
                i += 1
                continue
            }

            if word == "punkt", looksLikeSentenceEnd(tokens, i) {
                attach(".", absorbing: true)
                capitalizeNext = true
                i += 1
                continue
            }

            // Swedish uses the same nine-shaped ” to open and to close, so the
            // pair is tracked by parity rather than by two different names.
            if word == "citattecken" || word == "citationstecken" {
                if quoteOpen { attach("”") } else { pendingPrefix += "”" }
                quoteOpen.toggle()
                i += 1
                continue
            }

            if word == "vänsterparentes" {
                pendingPrefix += "("
                i += 1
                continue
            }

            if let mark = trailingMarks[word] {
                attach(mark, absorbing: absorbable.contains(mark))
                if ".!?".contains(mark) { capitalizeNext = true }
                i += 1
                continue
            }

            if let mark = standaloneMarks[word] {
                out.append(mark)
                i += 1
                continue
            }

            emit(token)
            i += 1
        }
        if !pendingPrefix.isEmpty { out.append(pendingPrefix) }
        return out.joined(separator: " ")
    }

    // MARK: - Symbol spacing (.afterPunctuation)

    /// Swedish sets a space between a figure and a symbol that is read aloud
    /// as a word — `50 %`, `20 °C` (Svenska skrivregler §12.14.1, §13.1.2).
    /// Idempotent: `\s*` absorbs a space that is already correct.
    static let symbolSpacing = CleanupRule(
        name: "space between a figure and % or °",
        stage: .afterPunctuation) { text, _ in
            var out = text
            for (pattern, template) in [(#"(\d)\s*%"#, "$1 %"), (#"(\d)\s*°"#, "$1 °")] {
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                out = regex.stringByReplacingMatches(
                    in: out, range: NSRange(out.startIndex..., in: out),
                    withTemplate: template)
            }
            return out
        }

    // MARK: - Quotation marks (.afterPunctuation)

    /// English and German curly quotes → the Swedish ”. Swedish uses the same
    /// nine-shaped mark at both ends (Svenska skrivregler), and neither “ nor
    /// „ has any legitimate use in Swedish text. Straight `"` is deliberately
    /// left alone: it is meaningful inside code and shell strings.
    static let quotationMarks = CleanupRule.regex(
        name: "curly quotes → Swedish ”",
        stage: .afterPunctuation,
        pattern: "[\u{201C}\u{201E}\u{201F}]",
        template: "\u{201D}")

    // MARK: - Abbreviation casing (.final)

    /// An abbreviation's period does not end a sentence, so the next word
    /// keeps its lowercase initial: "vi behöver t.ex. det andra". The shared
    /// capitalization pass can't know that — it capitalizes after any token
    /// ending in "." — so this puts it back.
    ///
    /// Only a *function word* is lowered. After the pass has run there is no
    /// way to tell a capital it introduced from one that was always there, and
    /// a proper noun in this position is entirely ordinary ("bl.a. Anna och
    /// Erik"). A function word never is, so restricting the repair to the
    /// stopword list makes it unable to eat a name. The cost is that a
    /// capitalized common noun ("t.ex. Kaffe") is left as the shared pass made
    /// it; that is the conservative half of the trade.
    static let abbreviationCase = CleanupRule(
        name: "lowercase after a Swedish abbreviation period",
        stage: .final) { text, _ in
            let abbreviations = [
                "t.ex.", "bl.a.", "m.m.", "d.v.s.", "dvs.", "osv.", "o.s.v.",
                "fr.o.m.", "t.o.m.", "m.fl.", "s.k.", "p.g.a.", "e.d.",
                "jfr.", "resp.", "kl.", "nr.", "ca.", "obs.", "st.",
            ]
            let names = abbreviations
                .map { NSRegularExpression.escapedPattern(for: $0) }
                .joined(separator: "|")
            let pattern = "(?i)(?<![\\p{L}.])(?:\(names)) (\\p{Lu}\\p{L}*)\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
            var out = text
            let matches = regex.matches(in: out, range: NSRange(out.startIndex..., in: out))
            for match in matches.reversed() {
                guard let word = Range(match.range(at: 1), in: out) else { continue }
                let lowered = out[word].lowercased()
                guard LanguagePack.swedishStopwords.contains(lowered) else { continue }
                out.replaceSubrange(word, with: lowered)
            }
            return out
        }

    // MARK: - Calendar casing (.final)

    /// Weekdays and months are common nouns in Swedish and take a lowercase
    /// initial (Språkrådet) — English-trained transcribers and models
    /// capitalize them anyway. Only mid-sentence occurrences are lowered: a
    /// sentence-initial "Måndag" is correct, and the lookbehind requires the
    /// previous character to be neither a sentence mark nor the string start.
    ///
    /// `mars` and `maj` are deliberately excluded: Mars is also the planet,
    /// and Maj is also a personal name. A compound keeps its capital too
    /// ("Fredagsmyset") because the word boundary after the inflection fails.
    static let calendarCase = CleanupRule(
        name: "weekdays and months stay lowercase mid-sentence",
        stage: .final) { text, _ in
            let names = [
                "Måndag", "Tisdag", "Onsdag", "Torsdag", "Fredag", "Lördag",
                "Söndag", "Januari", "Februari", "April", "Juni", "Juli",
                "Augusti", "September", "Oktober", "November", "December",
            ].joined(separator: "|")
            let pattern = "(?<=[^.!?…\n] )(\(names))(en|ar|arna|s|e)?\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
            var out = text
            let matches = regex.matches(in: out, range: NSRange(out.startIndex..., in: out))
            for match in matches.reversed() {
                guard let name = Range(match.range(at: 1), in: out) else { continue }
                out.replaceSubrange(name, with: out[name].lowercased())
            }
            return out
        }

    // MARK: - "Var …?" (.final)

    /// `var` is three words at once — the interrogative "where", the past
    /// tense of "vara", and its imperative ("Var snäll!") — so it is not in
    /// `questionPrefixWords`, where it would put a question mark on every
    /// polite request. It gets a positive rule instead: a leading "var"
    /// followed by a finite verb can only be the interrogative, because the
    /// imperative and the past tense both take a complement, not a second
    /// finite verb.
    ///
    /// Runs at `.final` so it can convert the period the terminal-punctuation
    /// pass has just appended; the `[^.?!]*` body keeps it to a single
    /// sentence.
    static let whereQuestion = CleanupRule.regex(
        name: "\"Var\" + finite verb ends in a question mark",
        stage: .final,
        pattern: "^(Var (?:är|låg|ligger|finns|fanns|kan|ska|skulle|har|hade|kommer|kom|hittar|hittade|står|stod|bor|jobbar|sparas|sparade|lade|la|blev|gick|sitter|satt|placeras|placerade|köpte|köper|hämtar|hämtade)\\b[^.?!]*)\\.\\z",
        template: "$1?")
}
