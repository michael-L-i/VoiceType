import Foundation

/// Deterministic rendering of *spoken* symbol names into characters, so the
/// rule-based path can produce `main.py`, `max_retries`, `--verbose`, or
/// `john.smith@gmail.com` from the words a transcriber heard — the same job
/// the model prompt's code-rendering rules do, but in plain code.
///
/// Every rule here is conservative by construction: a trigger word only joins
/// when its neighbors look like identifier parts (never stopwords), so prose
/// like "the dot product", "a dash of salt", or "I want to underscore the
/// importance" passes through untouched. The terminal category is deliberately
/// more aggressive — "dash" there is a flag, not a word — matching the same
/// bias the model prompt applies.
public enum SpokenSymbols {

    /// Render spoken symbols in `text` for the given app category, using one
    /// language's trigger words. The neighbor rules below are language-neutral;
    /// everything language-specific arrives in `vocabulary`. Defaults to
    /// English, the reference vocabulary.
    public static func render(_ text: String,
                              category: AppCategory,
                              vocabulary: SpokenSymbolVocabulary = .english) -> String {
        var tokens = renderEmails(text, vocabulary).split(separator: " ").map(String.init)
        tokens = renderParens(tokens, vocabulary)
        tokens = renderUnderscores(tokens, vocabulary)
        if category == .terminal {
            tokens = renderTerminalPaths(tokens, vocabulary)
        }
        tokens = renderDotExtensions(tokens, vocabulary)
        tokens = category == .terminal
            ? renderTerminalFlags(tokens, vocabulary)
            : renderLetterDashes(tokens, vocabulary)
        return assemble(tokens)
    }

    /// A token qualifies as an identifier part when it is word-like (letters,
    /// digits, or characters an earlier join introduced) and not a function
    /// word — "to underscore the" must never become "to_the".
    private static func isJoinable(_ token: String, _ vocab: SpokenSymbolVocabulary) -> Bool {
        !token.isEmpty
            && token.allSatisfy { $0.isLetter || $0.isNumber || "._-".contains($0) }
            && !vocab.joinGuards.contains(token.lowercased())
    }

    /// A plain word-like token (used where any word is acceptable, e.g. the
    /// flag name after a spoken "dash" in a terminal).
    private static func isWordy(_ token: String) -> Bool {
        !token.isEmpty && token.allSatisfy { $0.isLetter || $0.isNumber || "._-".contains($0) }
    }

    /// Split a token into its core and any trailing sentence punctuation, so
    /// "pie." still matches the extension while the "." survives the join.
    private static func splitTrailingPunctuation(_ token: String) -> (core: String, suffix: String) {
        var core = token
        var suffix = ""
        while let last = core.last, ".,!?;:".contains(last) {
            suffix = String(last) + suffix
            core.removeLast()
        }
        return (core, suffix)
    }

    /// A regex alternation of the vocabulary's trigger words, longest first so
    /// a multi-word name can't be shadowed by a prefix of itself.
    private static func alternation(_ words: Set<String>) -> String {
        words.sorted { $0.count > $1.count }
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
    }

    /// Collapse the spoken dot words inside a matched address: "john dot
    /// smith" → "john.smith".
    private static func joinSpokenDots(_ text: String, _ vocab: SpokenSymbolVocabulary) -> String {
        var out = text
        for word in vocab.dot {
            out = out.replacingOccurrences(of: " \(word) ", with: ".",
                                           options: [.caseInsensitive])
        }
        return out
    }

    // MARK: - Emails

    /// "john dot smith at gmail dot com" → "john.smith@gmail.com". Anchored on
    /// the TLD so ordinary uses of "at" never match; the local part must not be
    /// a lone function word ("look at gmail dot com" stays prose).
    private static func renderEmails(_ text: String, _ vocab: SpokenSymbolVocabulary) -> String {
        let dot = alternation(vocab.dot)
        let at = alternation(vocab.emailAt)
        let tlds = alternation(vocab.emailTLDs)
        let pattern = "(?i)\\b([a-z0-9]+(?: (?:\(dot)) [a-z0-9]+)*) (?:\(at)) ((?:[a-z0-9]+ (?:\(dot)) )+(?:\(tlds)))\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        var result = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let whole = Range(match.range, in: result),
                  let localRange = Range(match.range(at: 1), in: result),
                  let domainRange = Range(match.range(at: 2), in: result) else { continue }
            let local = String(result[localRange])
            if !local.contains(" "), vocab.emailLocalGuards.contains(local.lowercased()) {
                continue
            }
            let rendered = joinSpokenDots(local, vocab)
                + "@"
                + joinSpokenDots(String(result[domainRange]), vocab)
            result.replaceSubrange(whole, with: rendered.lowercased())
        }
        return result
    }

    // MARK: - Parens & brackets

    /// "open paren" / "close paren" (and bracket) become symbol tokens; a spoken
    /// "comma" *inside* an open pair is a literal comma. Attachment happens in
    /// `assemble`.
    private static func renderParens(_ tokens: [String], _ vocab: SpokenSymbolVocabulary) -> [String] {
        var out: [String] = []
        var depth = 0
        var i = 0
        while i < tokens.count {
            let t = tokens[i].lowercased()
            if i + 1 < tokens.count, vocab.openers.contains(t) || vocab.closers.contains(t) {
                let next = tokens[i + 1].lowercased()
                var symbol: String?
                let isOpener = vocab.openers.contains(t)
                if vocab.parenNouns.contains(next) {
                    symbol = isOpener ? "(" : ")"
                } else if vocab.bracketNouns.contains(next) {
                    symbol = isOpener ? "[" : "]"
                }
                if let symbol {
                    depth = isOpener ? depth + 1 : max(0, depth - 1)
                    out.append(symbol)
                    i += 2
                    continue
                }
            }
            if depth > 0, vocab.comma.contains(t) {
                out.append(",")
                i += 1
                continue
            }
            out.append(tokens[i])
            i += 1
        }
        return out
    }

    // MARK: - Underscores

    /// "max underscore retries" → "max_retries". Both neighbors must be
    /// identifier parts; chains fold left ("test underscore client" first, so a
    /// following "dot pie" sees "test_client").
    private static func renderUnderscores(_ tokens: [String], _ vocab: SpokenSymbolVocabulary) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            if vocab.underscore.contains(tokens[i].lowercased()),
               let left = out.last, isJoinable(left, vocab),
               i + 1 < tokens.count {
                let (core, suffix) = splitTrailingPunctuation(tokens[i + 1])
                if isJoinable(core, vocab) {
                    out[out.count - 1] = left + "_" + core + suffix
                    i += 2
                    continue
                }
            }
            out.append(tokens[i])
            i += 1
        }
        return out
    }

    // MARK: - Dot extensions

    /// "main dot pie" → "main.py"; "index dot j s" → "index.js". Joins only
    /// when the trailing words actually name a known extension — "the dot
    /// product" has neither a joinable left ("the") nor an extension right.
    private static func renderDotExtensions(_ tokens: [String], _ vocab: SpokenSymbolVocabulary) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            if vocab.dot.contains(tokens[i].lowercased()),
               let left = out.last, isJoinable(left, vocab),
               i + 1 < tokens.count {
                // Spelled letters: "dot t s" → ".ts" when they form an extension.
                var letters: [String] = []
                var j = i + 1
                while j < tokens.count, letters.count < 3,
                      tokens[j].count == 1, tokens[j].first!.isLetter {
                    letters.append(tokens[j].lowercased())
                    j += 1
                }
                var joined = false
                var k = letters.count
                while k >= 1 {
                    let candidate = letters.prefix(k).joined()
                    if vocab.fileExtensions.contains(candidate) {
                        out[out.count - 1] = left + "." + candidate
                        i += 1 + k
                        joined = true
                        break
                    }
                    k -= 1
                }
                if joined { continue }

                // Whole-word extension or homophone: "dot pie" → ".py".
                let (core, suffix) = splitTrailingPunctuation(tokens[i + 1])
                let lowered = core.lowercased()
                if let ext = vocab.extensionHomophones[lowered] ?? (vocab.fileExtensions.contains(lowered) ? lowered : nil) {
                    out[out.count - 1] = left + "." + ext + suffix
                    i += 2
                    continue
                }
            }
            out.append(tokens[i])
            i += 1
        }
        return out
    }

    // MARK: - Dashes

    /// Outside the terminal, "dash" joins only when the right side is a single
    /// spoken letter — "michael dash L dash I" → "michael-L-i" — so "a dash of
    /// salt" stays prose. A joined capital "I" lowers: it was capitalized as
    /// the pronoun, which it no longer is inside a handle.
    private static func renderLetterDashes(_ tokens: [String], _ vocab: SpokenSymbolVocabulary) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            if vocab.dash.contains(tokens[i].lowercased()),
               let left = out.last, isJoinable(left, vocab),
               i + 1 < tokens.count {
                let (core, suffix) = splitTrailingPunctuation(tokens[i + 1])
                if core.count == 1, core.first!.isLetter {
                    let letter = core == "I" ? "i" : core
                    out[out.count - 1] = left + "-" + letter + suffix
                    i += 2
                    continue
                }
            }
            out.append(tokens[i])
            i += 1
        }
        return out
    }

    /// In a terminal, "dash" is a flag marker: "dash dash verbose" → "--verbose",
    /// "dash m" → "-m". Aggressive on purpose — prose dictated into a terminal
    /// accepts the same bias the model prompt does.
    private static func renderTerminalFlags(_ tokens: [String], _ vocab: SpokenSymbolVocabulary) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            if vocab.dash.contains(tokens[i].lowercased()), i + 1 < tokens.count {
                if vocab.dash.contains(tokens[i + 1].lowercased()), i + 2 < tokens.count, isWordy(tokens[i + 2]) {
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

    // MARK: - Terminal paths

    /// "tilde slash projects slash voice" → "~/projects/voice"; "dot slash
    /// build" → "./build"; "src slash main" → "src/main". Terminal-only: in
    /// prose, "slash" is more often a word than a path separator.
    private static func renderTerminalPaths(_ tokens: [String], _ vocab: SpokenSymbolVocabulary) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            let t = tokens[i].lowercased()
            let isTilde = vocab.tilde.contains(t)
            if isTilde || vocab.dot.contains(t), i + 1 < tokens.count,
               vocab.slash.contains(tokens[i + 1].lowercased()),
               i + 2 < tokens.count, isWordy(tokens[i + 2]) {
                out.append((isTilde ? "~/" : "./") + tokens[i + 2])
                i += 3
                continue
            }
            if vocab.slash.contains(t), i + 1 < tokens.count, isWordy(tokens[i + 1]),
               let left = out.last,
               left.allSatisfy({ $0.isLetter || $0.isNumber || "._-/~".contains($0) }) {
                out[out.count - 1] = left + "/" + tokens[i + 1]
                i += 2
                continue
            }
            out.append(tokens[i])
            i += 1
        }
        return out
    }

    // MARK: - Assembly

    /// Join tokens with spaces, attaching the symbol tokens `renderParens`
    /// produced: "(" glues to both sides, ")" "]" "," glue to the left.
    private static func assemble(_ tokens: [String]) -> String {
        var result = ""
        var glueNext = false
        for token in tokens {
            switch token {
            case "(", "[":
                result += token
                glueNext = true
            case ")", "]", ",":
                result += token
                glueNext = false
            default:
                if result.isEmpty || glueNext {
                    result += token
                } else {
                    result += " " + token
                }
                glueNext = false
            }
        }
        return result
    }
}
