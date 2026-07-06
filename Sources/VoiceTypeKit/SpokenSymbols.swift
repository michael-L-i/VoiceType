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

    /// Render spoken symbols in `text` for the given app category. English-only
    /// by contract — the trigger words ("dot", "underscore", …) are English;
    /// callers gate on the locale.
    public static func render(_ text: String, category: AppCategory) -> String {
        var tokens = renderEmails(text).split(separator: " ").map(String.init)
        tokens = renderParens(tokens)
        tokens = renderUnderscores(tokens)
        if category == .terminal {
            tokens = renderTerminalPaths(tokens)
        }
        tokens = renderDotExtensions(tokens)
        tokens = category == .terminal
            ? renderTerminalFlags(tokens)
            : renderLetterDashes(tokens)
        return assemble(tokens)
    }

    // MARK: - Vocabulary

    /// File extensions we join after a spoken "dot". Kept to common, unambiguous
    /// ones; anything else stays prose.
    static let extensions: Set<String> = [
        "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
        "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
        "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
    ]

    /// Homophones a transcriber produces for extensions ("open main dot pie").
    static let extensionHomophones: [String: String] = [
        "pie": "py",
        "pi": "py",
    ]

    /// Top-level domains that anchor the spoken-email pattern.
    private static let emailTLDs = "com|net|org|io|co|dev|app|ai|edu|gov|me"

    /// Words that read as prose in front of "at", not as an email local part:
    /// "have a look at gmail dot com" must stay a sentence. Function words plus
    /// the verbs that commonly precede "at".
    private static let emailLocalGuards: Set<String> = CleanupGuard.openerStopwords.union([
        "look", "looking", "looked", "go", "going", "meet", "meeting",
        "back", "up", "over", "out", "stay", "arrive", "start", "starts",
    ])

    /// A token qualifies as an identifier part when it is word-like (letters,
    /// digits, or characters an earlier join introduced) and not a function
    /// word — "to underscore the" must never become "to_the".
    private static func isJoinable(_ token: String) -> Bool {
        !token.isEmpty
            && token.allSatisfy { $0.isLetter || $0.isNumber || "._-".contains($0) }
            && !CleanupGuard.openerStopwords.contains(token.lowercased())
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

    // MARK: - Emails

    /// "john dot smith at gmail dot com" → "john.smith@gmail.com". Anchored on
    /// the TLD so ordinary uses of "at" never match; the local part must not be
    /// a lone function word ("look at gmail dot com" stays prose).
    private static func renderEmails(_ text: String) -> String {
        let pattern = "(?i)\\b([a-z0-9]+(?: dot [a-z0-9]+)*) at ((?:[a-z0-9]+ dot )+(?:\(emailTLDs)))\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        var result = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let whole = Range(match.range, in: result),
                  let localRange = Range(match.range(at: 1), in: result),
                  let domainRange = Range(match.range(at: 2), in: result) else { continue }
            let local = String(result[localRange])
            if !local.contains(" "), emailLocalGuards.contains(local.lowercased()) {
                continue
            }
            let rendered = local.replacingOccurrences(of: " dot ", with: ".")
                + "@"
                + String(result[domainRange]).replacingOccurrences(of: " dot ", with: ".")
            result.replaceSubrange(whole, with: rendered.lowercased())
        }
        return result
    }

    // MARK: - Parens & brackets

    /// "open paren" / "close paren" (and bracket) become symbol tokens; a spoken
    /// "comma" *inside* an open pair is a literal comma. Attachment happens in
    /// `assemble`.
    private static func renderParens(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var depth = 0
        var i = 0
        while i < tokens.count {
            let t = tokens[i].lowercased()
            if i + 1 < tokens.count, t == "open" || t == "close" {
                let next = tokens[i + 1].lowercased()
                var symbol: String?
                if ["paren", "parens", "parenthesis"].contains(next) {
                    symbol = t == "open" ? "(" : ")"
                } else if next == "bracket" || next == "brackets" {
                    symbol = t == "open" ? "[" : "]"
                }
                if let symbol {
                    depth = t == "open" ? depth + 1 : max(0, depth - 1)
                    out.append(symbol)
                    i += 2
                    continue
                }
            }
            if depth > 0, t == "comma" {
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
    private static func renderUnderscores(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            if tokens[i].lowercased() == "underscore",
               let left = out.last, isJoinable(left),
               i + 1 < tokens.count {
                let (core, suffix) = splitTrailingPunctuation(tokens[i + 1])
                if isJoinable(core) {
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
    private static func renderDotExtensions(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            if tokens[i].lowercased() == "dot",
               let left = out.last, isJoinable(left),
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
                    if extensions.contains(candidate) {
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
                if let ext = extensionHomophones[lowered] ?? (extensions.contains(lowered) ? lowered : nil) {
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
    private static func renderLetterDashes(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            if tokens[i].lowercased() == "dash",
               let left = out.last, isJoinable(left),
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
    private static func renderTerminalFlags(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            if tokens[i].lowercased() == "dash", i + 1 < tokens.count {
                if tokens[i + 1].lowercased() == "dash", i + 2 < tokens.count, isWordy(tokens[i + 2]) {
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
    private static func renderTerminalPaths(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            let t = tokens[i].lowercased()
            if (t == "tilde" || t == "dot"), i + 1 < tokens.count,
               tokens[i + 1].lowercased() == "slash",
               i + 2 < tokens.count, isWordy(tokens[i + 2]) {
                out.append((t == "tilde" ? "~/" : "./") + tokens[i + 2])
                i += 3
                continue
            }
            if t == "slash", i + 1 < tokens.count, isWordy(tokens[i + 1]),
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
