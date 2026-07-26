import Foundation

/// Dutch orthography that the pack's declarative fields cannot express, written
/// as `CleanupRule`s so improving Dutch never touches shared code.
///
/// Every rule below encodes a convention that is *always* right in Dutch. The
/// judgment calls — which hesitation is empty, which compound was split — stay
/// in `DutchPrompt`, where the model has context.
///
/// Sources (all consulted 2026-07):
/// - Genootschap Onze Taal, "hoofdletter (wanneer wel of niet?)" and
///   "wel of geen spatie voor gradenteken, procentteken, euroteken, enz."
/// - Taaladvies.net (Nederlandse Taalunie): "Euro / EUR / euroteken",
///   "Komma of punt bij decimale getallen", "Afkortingen: gebruik (algemeen)".
/// - Wikipedia (nl), "Hoofdletter in de Nederlandse spelling" — the IJ digraph.
enum DutchOrthography {
    // MARK: - Masking placeholders
    //
    // Two shared passes are correct for most orthographies and wrong for
    // Dutch, and both run *between* the rule stages, so the fix is to hide the
    // character from them and restore it afterwards. The placeholders are
    // chosen to degrade gracefully: each is a real Unicode mark that looks
    // almost exactly like the character it stands in for, so even a leaked
    // placeholder reads as a typo rather than as a missing glyph.

    /// Stands in for the period inside an abbreviation. `capitalizeSentences`
    /// re-arms on any token ending in ".", which turns "we hebben bijv. koffie
    /// nodig" into "… bijv. Koffie nodig". Masking the dot keeps the shared
    /// pass from ever seeing a sentence end there — and, unlike lowercasing
    /// afterwards, it preserves a genuine proper noun ("o.a. Amsterdam").
    static let abbreviationDot: Character = "\u{2024}"   // ONE DOT LEADER

    /// Stands in for the decimal comma. `fixPunctuationSpacing` inserts a
    /// space after every comma followed by a non-space, which splits every
    /// Dutch decimal number: "3,14" → "3, 14". Masking only the commas that
    /// are *already* tight between digits leaves a legitimate "30, 40 mensen"
    /// alone. (Taaladvies: the comma is Dutch's decimal separator.)
    static let decimalComma: Character = "\u{201A}"      // SINGLE LOW-9 QUOTATION MARK

    // MARK: - Abbreviations

    /// Dutch abbreviations that take a period and effectively never end a
    /// sentence, so a capital after them is always wrong.
    ///
    /// Deliberately excluded: "enz.", "etc.", "e.d.", "a.u.b." (they routinely
    /// *do* end a sentence), the weekday abbreviations ma./di./…/zo. ("Zo. Dat
    /// was het." is an ordinary Dutch sentence), and "B.V." (the company form,
    /// which ends sentences too).
    static let abbreviations: [String] = [
        "bijv.", "bv.", "o.a.", "d.w.z.", "m.a.w.", "i.v.m.", "t.o.v.",
        "t.a.v.", "m.b.t.", "i.p.v.", "n.a.v.", "ca.", "ong.", "incl.",
        "excl.", "resp.", "evt.", "zgn.", "nl.", "vgl.", "nr.", "blz.",
        "pag.", "fig.", "afb.", "dhr.", "mevr.", "mw.", "dr.", "drs.", "ir.",
        "ing.", "prof.", "mr.", "jr.", "v.Chr.", "n.Chr.",
    ]

    private static let abbreviationRegex: NSRegularExpression? = {
        let names = abbreviations
            .sorted { $0.count > $1.count }
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
        return try? NSRegularExpression(
            pattern: "(?<![\\p{L}\\p{N}])(?:\(names))(?![\\p{L}\\p{N}])",
            options: [.caseInsensitive])
    }()

    static func maskAbbreviationDots(_ text: String) -> String {
        guard text.contains("."), let regex = abbreviationRegex else { return text }
        var out = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let range = Range(match.range, in: out) else { continue }
            out.replaceSubrange(range, with: out[range].replacingOccurrences(
                of: ".", with: String(abbreviationDot)))
        }
        return out
    }

    // MARK: - Sentence-initial clitics

    /// `'s`, `'t`, `'n` and `'k` keep their lowercase apostrophe form at the
    /// start of a sentence; the capital moves to the next word: "'s Ochtends
    /// regent het." (Onze Taal.) The shared capitalization pass cannot do this
    /// — it sees a token starting with an apostrophe and stops.
    private static let cliticRegex = try? NSRegularExpression(
        pattern: "(^|[.!?]\\s|\\n)(['\u{2019}][stnk])\\s+(\\p{Ll})")

    static func capitalizeAfterClitic(_ text: String) -> String {
        guard let regex = cliticRegex else { return text }
        var out = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let letter = Range(match.range(at: 3), in: out) else { continue }
            out.replaceSubrange(letter, with: out[letter].uppercased())
        }
        return out
    }

    // MARK: - Spoken identifier symbols

    /// The file extensions and top-level domains that make a spoken "punt"
    /// unambiguous. Single letters (c, h) are left out: "op dat punt c" is
    /// nonsense, but the extension set is the only guard this join has, so it
    /// stays narrow.
    static let extensions: Set<String> = [
        "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "json", "yaml",
        "yml", "toml", "md", "txt", "html", "css", "sh", "sql", "csv", "log",
        "env", "lock", "java", "rb", "php", "xml", "cpp", "hpp",
        "nl", "be", "com", "net", "org", "io", "dev", "eu", "app", "ai",
    ]

    /// True when a token can be part of a dictated identifier: word-like, and
    /// not a Dutch function word. "de underscore van het bestand" must stay
    /// four words, not become "de_van het bestand".
    private static func isJoinable(_ token: String) -> Bool {
        !token.isEmpty
            && token.allSatisfy { $0.isLetter || $0.isNumber || "._-@".contains($0) }
            && !LanguagePack.dutchStopwords.contains(token.lowercased())
    }

    private static func isWordy(_ token: String) -> Bool {
        !token.isEmpty
            && token.allSatisfy { $0.isLetter || $0.isNumber || "._-/~@".contains($0) }
    }

    private static func splitTrailingPunctuation(_ token: String) -> (core: String, suffix: String) {
        var core = token
        var suffix = ""
        while let last = core.last, ".,!?;:".contains(last) {
            suffix = String(last) + suffix
            core.removeLast()
        }
        return (core, suffix)
    }

    /// Join the two symbol words that are *only* symbol names in Dutch —
    /// "apenstaartje" (@, the one every Dutch speaker uses for an e-mail
    /// address) and "underscore" (the loanword; the Dutch verb is
    /// "onderstrepen", so the noun never appears as prose here) — plus "punt"
    /// in the single position where it cannot be prose: between a joinable
    /// word and a known extension or TLD.
    static func renderSpokenIdentifiers(_ text: String) -> String {
        var tokens = text.split(separator: " ").map(String.init)
        tokens = join(tokens, trigger: "apenstaartje", separator: "@")
        tokens = join(tokens, trigger: "underscore", separator: "_")
        tokens = joinExtensions(tokens)
        return tokens.joined(separator: " ")
    }

    private static func join(_ tokens: [String], trigger: String, separator: String) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            if tokens[i].lowercased() == trigger,
               let left = out.last, isJoinable(left), i + 1 < tokens.count {
                let (core, suffix) = splitTrailingPunctuation(tokens[i + 1])
                if isJoinable(core) {
                    out[out.count - 1] = left + separator + core + suffix
                    i += 2
                    continue
                }
            }
            out.append(tokens[i])
            i += 1
        }
        return out
    }

    private static func joinExtensions(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            if tokens[i].lowercased() == "punt",
               let left = out.last, isJoinable(left), i + 1 < tokens.count {
                let (core, suffix) = splitTrailingPunctuation(tokens[i + 1])
                if extensions.contains(core.lowercased()) {
                    out[out.count - 1] = left + "." + core.lowercased() + suffix
                    i += 2
                    continue
                }
            }
            out.append(tokens[i])
            i += 1
        }
        return out
    }

    // MARK: - Terminal flags and paths

    /// A private sentinel standing for the two-word "schuine streep" while the
    /// token pass runs; anything left over is expanded back, so a phrase that
    /// never became a path survives intact.
    private static let slashToken = "\u{0001}slash"

    /// Terminal-only. A Dutch speaker dictating a shell command says "streepje
    /// streepje verbose" for `--verbose` and "tilde schuine streep projecten"
    /// for `~/projecten`. Outside a terminal "streepje" is an ordinary word
    /// ("een streepje zetten"), which is why this runs nowhere else.
    static func renderTerminalSymbols(_ text: String) -> String {
        var tokens: [String] = []
        let raw = text.split(separator: " ").map(String.init)
        var i = 0
        while i < raw.count {
            if raw[i].lowercased() == "schuine", i + 1 < raw.count,
               raw[i + 1].lowercased() == "streep" {
                tokens.append(slashToken)
                i += 2
                continue
            }
            tokens.append(raw[i])
            i += 1
        }
        tokens = renderPaths(tokens)
        tokens = renderFlags(tokens)
        return tokens
            .joined(separator: " ")
            .replacingOccurrences(of: slashToken, with: "schuine streep")
    }

    private static func renderPaths(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            let t = tokens[i].lowercased()
            let isTilde = t == "tilde"
            if isTilde || t == "punt", i + 2 < tokens.count,
               tokens[i + 1] == slashToken, isWordy(tokens[i + 2]) {
                out.append((isTilde ? "~/" : "./") + tokens[i + 2])
                i += 3
                continue
            }
            if tokens[i] == slashToken, i + 1 < tokens.count, isWordy(tokens[i + 1]),
               let left = out.last, isWordy(left) {
                out[out.count - 1] = left + "/" + tokens[i + 1]
                i += 2
                continue
            }
            out.append(tokens[i])
            i += 1
        }
        return out
    }

    private static func renderFlags(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            if tokens[i].lowercased() == "streepje", i + 1 < tokens.count {
                if tokens[i + 1].lowercased() == "streepje", i + 2 < tokens.count,
                   isWordy(tokens[i + 2]) {
                    out.append("--" + tokens[i + 2])
                    i += 3
                    continue
                }
                if isWordy(tokens[i + 1]) {
                    out.append("-" + tokens[i + 1])
                    i += 2
                    continue
                }
            }
            out.append(tokens[i])
            i += 1
        }
        return out
    }
}

extension LanguagePack {
    /// Dutch's own deterministic fixes. Order within a stage is declaration
    /// order, and the two masking pairs are declared so that each mask runs
    /// before anything that could disturb it and each restore runs after.
    static let dutchRules: [CleanupRule] = [
        // --- .early: raw transcriber (or model) output -------------------

        // Hide the abbreviation period from `capitalizeSentences`, which would
        // otherwise treat "bijv." as a sentence end and capitalize the word
        // after it. Restored at `.final`.
        CleanupRule(name: "mask abbreviation periods", stage: .early) { text, _ in
            DutchOrthography.maskAbbreviationDots(text)
        },

        // Hide the decimal comma from `fixPunctuationSpacing`, which inserts a
        // space after any comma followed by a non-space and so would turn
        // "3,14" into "3, 14". Restored at `.afterPunctuation`.
        CleanupRule.regex(
            name: "mask decimal comma",
            stage: .early,
            pattern: "(?<=\\d),(?=\\d)",
            template: String(DutchOrthography.decimalComma)),

        // "jan apenstaartje voorbeeld punt nl" → jan@voorbeeld.nl,
        // "max underscore retries" → max_retries.
        CleanupRule(name: "spoken identifier symbols", stage: .early) { text, _ in
            DutchOrthography.renderSpokenIdentifiers(text)
        },

        // Terminal only, and gated again inside: "streepje streepje verbose"
        // → --verbose, "tilde schuine streep projecten" → ~/projecten.
        CleanupRule(name: "spoken shell flags and paths",
                    stage: .early, runsInTerminal: true) { text, context in
            guard context.category == .terminal else { return text }
            return DutchOrthography.renderTerminalSymbols(text)
        },

        // --- .afterPunctuation: after spacing normalization ---------------

        CleanupRule.regex(
            name: "restore decimal comma",
            stage: .afterPunctuation,
            pattern: String(DutchOrthography.decimalComma),
            template: ","),

        // Taaladvies: in Dutch the euro sign precedes the amount with a space
        // between them — "€ 15,50", never "€15,50".
        CleanupRule.regex(
            name: "space after euro sign",
            stage: .afterPunctuation,
            pattern: "€\\s*(?=\\d)",
            template: "€ "),

        // Onze Taal: the percent sign sits directly against the number —
        // "15%", not "15 %".
        CleanupRule.regex(
            name: "no space before percent sign",
            stage: .afterPunctuation,
            pattern: "(?<=\\d)\\s+%",
            template: "%"),

        // --- .final: after capitalization and terminal punctuation --------

        // A word beginning with the digraph "ij" takes TWO capitals:
        // IJsland, IJssel, IJmuiden — never "Ijsland". Runs last so it
        // repairs whatever the shared capitalization pass (or the model)
        // produced.
        CleanupRule.regex(
            name: "IJ digraph takes two capitals",
            stage: .final,
            pattern: "(?<![\\p{L}\\p{N}])Ij(?!\\p{Lu})",
            template: "IJ"),

        // "'s ochtends" → "'s Ochtends" at the start of a sentence.
        CleanupRule(name: "capital moves past a sentence-initial clitic",
                    stage: .final) { text, _ in
            DutchOrthography.capitalizeAfterClitic(text)
        },

        // Put the abbreviation periods back. Always runs — both cleanup paths
        // reach `.final` on every return path — and pairs with the `.early`
        // mask, including its terminal opt-out, so the two can never disagree.
        CleanupRule(name: "restore abbreviation periods", stage: .final) { text, _ in
            text.replacingOccurrences(of: String(DutchOrthography.abbreviationDot),
                                      with: ".")
        },
    ]
}
