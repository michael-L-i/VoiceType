import Foundation

/// Rendering the symbols a Polish speaker *says* into the characters they mean:
/// "main kropka py" → `main.py`, "max podkreślnik retries" → `max_retries`,
/// "jan małpa gmail kropka com" → `jan@gmail.com`.
///
/// This is a `CleanupRule` rather than a `SpokenSymbolVocabulary` because the
/// shared renderer's shape does not fit Polish. Two reasons, both structural:
///
/// 1. **Word order.** Polish names the square bracket `nawias kwadratowy` —
///    noun first, adjective second. The shared opener+noun probe reads
///    "otwórz nawias" and stops, leaving a stray "kwadratowy" behind and the
///    wrong bracket rendered.
/// 2. **Case.** Polish inflects, so the connector a speaker actually utters is
///    `kropka` but the words around it are `pliku`, `nazwie`, `podkreślnikiem`.
///    The guards have to be about what a token *is*, not about a fixed lexicon.
///
/// Every join here is conservative by construction: a trigger word only fuses
/// its neighbors when both of them look like identifier parts and neither is a
/// function word, so `kropka nad i`, `i kropka` and `dodaj podkreślenie tutaj`
/// all pass through as prose. Where a Polish word is ambiguous, it is simply
/// not a trigger:
/// - **`podkreślenie`** ("emphasis", "underlining") is excluded; only the IT
///   term `podkreślnik` renders as `_`. "Dodaj podkreślenie tutaj" must not
///   become `dodaj_tutaj`.
/// - **`minus`** is excluded: "pięć minus trzy" is arithmetic, and the
///   terminal flag renderer is aggressive enough to turn it into `pięć -trzy`.
/// - **`kreska`**, **`punkt`**, **`znak`** are everyday nouns with no
///   dictation-specific reading.
enum PolishSpokenCode {
    // MARK: - Trigger words

    static let dot: Set<String> = ["kropka"]
    static let underscore: Set<String> = ["podkreślnik", "underscore"]
    static let dash: Set<String> = ["myślnik", "łącznik"]
    static let slash: Set<String> = ["ukośnik"]
    static let tilde: Set<String> = ["tylda"]
    /// "@" is universally "małpa" (monkey) in Polish. Only ever rendered inside
    /// the TLD-anchored email pattern, so the animal can't false-match.
    static let emailAt: Set<String> = ["małpa", "małpka"]

    static let openers: Set<String> = ["otwórz", "otwarty", "lewy"]
    static let closers: Set<String> = ["zamknij", "zamknięty", "prawy"]
    static let parenNouns: Set<String> = ["nawias", "nawiasy"]
    /// The adjective that turns `nawias` into a square bracket, in the
    /// position Polish actually puts it: *after* the noun.
    static let squareAdjectives: Set<String> = [
        "kwadratowy", "kwadratowe", "kwadratowych", "kwadratow",
    ]

    static let fileExtensions: Set<String> = [
        "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
        "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
        "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
    ]
    /// Polish transcribers hear the letter pair "py" as the Polish word "pi".
    static let extensionHomophones: [String: String] = ["pi": "py", "pie": "py"]

    static let emailTLDs: Set<String> = [
        "com", "net", "org", "io", "co", "dev", "app", "ai", "edu", "gov",
        "me", "pl", "eu",
    ]

    /// Every trigger word, for the fast path. Text without one is returned
    /// byte-identical, so this rule can never disturb ordinary dictation.
    private static let allTriggers: Set<String> =
        dot.union(underscore).union(dash).union(slash).union(tilde)
            .union(emailAt).union(openers).union(closers)

    // MARK: - Entry point

    static func render(_ text: String, category: AppCategory) -> String {
        let lowered = text.lowercased()
        guard allTriggers.contains(where: { lowered.contains($0) }) else { return text }

        var tokens = renderEmails(text)
            .components(separatedBy: " ")
            .filter { !$0.isEmpty }
        tokens = renderBrackets(tokens)
        tokens = renderUnderscores(tokens)
        if category == .terminal {
            tokens = renderPaths(tokens)
        }
        tokens = renderDotExtensions(tokens)
        tokens = category == .terminal ? renderFlags(tokens) : renderLetterDashes(tokens)
        return assemble(tokens)
    }

    // MARK: - Guards

    /// A token qualifies as an identifier part when it is word-like (letters,
    /// digits, or characters an earlier join introduced) and is not a Polish
    /// function word — "to podkreślnik tego" must never fuse.
    private static func isJoinable(_ token: String) -> Bool {
        !token.isEmpty
            && token.allSatisfy { $0.isLetter || $0.isNumber || "._-".contains($0) }
            && !LanguagePack.polishStopwords.contains(token.lowercased())
    }

    /// Any word-like token, for the positions where a function word is fine
    /// (the flag name after a spoken "myślnik" in a terminal).
    private static func isWordy(_ token: String) -> Bool {
        !token.isEmpty && token.allSatisfy { $0.isLetter || $0.isNumber || "._-".contains($0) }
    }

    /// Split a token into its core and any trailing sentence punctuation, so
    /// "pi." still matches the extension while the "." survives the join.
    private static func splitTrailingPunctuation(_ token: String) -> (core: String, suffix: String) {
        var core = token
        var suffix = ""
        while let last = core.last, ".,!?;:".contains(last) {
            suffix = String(last) + suffix
            core.removeLast()
        }
        return (core, suffix)
    }

    private static func alternation(_ words: Set<String>) -> String {
        words.sorted { $0.count > $1.count }
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
    }

    // MARK: - Emails

    /// "jan kropka kowalski małpa gmail kropka com" → jan.kowalski@gmail.com.
    /// Anchored on a real TLD, so an ordinary "małpa" never matches, and the
    /// local part must not be a bare function word.
    private static func renderEmails(_ text: String) -> String {
        let dots = alternation(dot)
        let at = alternation(emailAt)
        let tlds = alternation(emailTLDs)
        let pattern = "(?i)\\b([a-z0-9]+(?: (?:\(dots)) [a-z0-9]+)*) (?:\(at)) ((?:[a-z0-9]+ (?:\(dots)) )+(?:\(tlds)))\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        var result = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let whole = Range(match.range, in: result),
                  let localRange = Range(match.range(at: 1), in: result),
                  let domainRange = Range(match.range(at: 2), in: result) else { continue }
            let local = String(result[localRange])
            if !local.contains(" "), LanguagePack.polishStopwords.contains(local.lowercased()) {
                continue
            }
            let rendered = joinSpokenDots(local) + "@" + joinSpokenDots(String(result[domainRange]))
            result.replaceSubrange(whole, with: rendered.lowercased())
        }
        return result
    }

    private static func joinSpokenDots(_ text: String) -> String {
        var out = text
        for word in dot {
            out = out.replacingOccurrences(of: " \(word) ", with: ".", options: [.caseInsensitive])
        }
        return out
    }

    // MARK: - Parens and brackets

    /// "otwórz nawias" → `(`, and Polish's post-nominal adjective —
    /// "otwórz nawias kwadratowy" → `[` — consumed as one phrase so the
    /// adjective never survives as a stray word.
    private static func renderBrackets(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var index = 0
        while index < tokens.count {
            let word = tokens[index].lowercased()
            let isOpener = openers.contains(word)
            guard isOpener || closers.contains(word), index + 1 < tokens.count,
                  parenNouns.contains(tokens[index + 1].lowercased()) else {
                out.append(tokens[index])
                index += 1
                continue
            }
            var consumed = 2
            var square = false
            if index + 2 < tokens.count,
               squareAdjectives.contains(tokens[index + 2].lowercased()) {
                square = true
                consumed = 3
            }
            out.append(square ? (isOpener ? "[" : "]") : (isOpener ? "(" : ")"))
            index += consumed
        }
        return out
    }

    // MARK: - Underscores

    /// "max podkreślnik retries" → max_retries. Both neighbors must be
    /// identifier parts; chains fold left.
    private static func renderUnderscores(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var index = 0
        while index < tokens.count {
            if underscore.contains(tokens[index].lowercased()),
               let left = out.last, isJoinable(left), index + 1 < tokens.count {
                let (core, suffix) = splitTrailingPunctuation(tokens[index + 1])
                if isJoinable(core) {
                    out[out.count - 1] = left + "_" + core + suffix
                    index += 2
                    continue
                }
            }
            out.append(tokens[index])
            index += 1
        }
        return out
    }

    // MARK: - File extensions

    /// "main kropka py" → main.py; "index kropka t s" → index.ts. Joins only
    /// when the words after the dot actually name a known extension — which is
    /// what keeps "kropka nad i" and "czerwona kropka" out of it.
    private static func renderDotExtensions(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var index = 0
        while index < tokens.count {
            if dot.contains(tokens[index].lowercased()),
               let left = out.last, isJoinable(left), index + 1 < tokens.count {
                // Spelled letters: "kropka t s" → ".ts".
                var letters: [String] = []
                var scan = index + 1
                while scan < tokens.count, letters.count < 3,
                      tokens[scan].count == 1, tokens[scan].first!.isLetter {
                    letters.append(tokens[scan].lowercased())
                    scan += 1
                }
                var joined = false
                var count = letters.count
                while count >= 1 {
                    let candidate = letters.prefix(count).joined()
                    if fileExtensions.contains(candidate) {
                        out[out.count - 1] = left + "." + candidate
                        index += 1 + count
                        joined = true
                        break
                    }
                    count -= 1
                }
                if joined { continue }

                let (core, suffix) = splitTrailingPunctuation(tokens[index + 1])
                let lowered = core.lowercased()
                if let ext = extensionHomophones[lowered]
                    ?? (fileExtensions.contains(lowered) ? lowered : nil) {
                    out[out.count - 1] = left + "." + ext + suffix
                    index += 2
                    continue
                }
            }
            out.append(tokens[index])
            index += 1
        }
        return out
    }

    // MARK: - Dashes

    /// Outside a terminal, "myślnik" joins only when the right side is a single
    /// spoken letter — "michał myślnik L" → michał-L — so an ordinary
    /// "łącznik hydrauliczny" stays two words and a prose myślnik is left for
    /// `PolishSpokenMarks` to set as a spaced półpauza.
    private static func renderLetterDashes(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var index = 0
        while index < tokens.count {
            if dash.contains(tokens[index].lowercased()),
               let left = out.last, isJoinable(left), index + 1 < tokens.count {
                let (core, suffix) = splitTrailingPunctuation(tokens[index + 1])
                if core.count == 1, core.first!.isLetter {
                    out[out.count - 1] = left + "-" + core + suffix
                    index += 2
                    continue
                }
            }
            out.append(tokens[index])
            index += 1
        }
        return out
    }

    /// In a terminal a spoken dash is a flag marker: "myślnik myślnik verbose"
    /// → --verbose, "myślnik m" → -m.
    private static func renderFlags(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var index = 0
        while index < tokens.count {
            if dash.contains(tokens[index].lowercased()), index + 1 < tokens.count {
                if dash.contains(tokens[index + 1].lowercased()), index + 2 < tokens.count,
                   isWordy(tokens[index + 2]) {
                    out.append("--" + tokens[index + 2])
                    index += 3
                    continue
                }
                if isWordy(tokens[index + 1]) {
                    out.append("-" + tokens[index + 1])
                    index += 2
                    continue
                }
            }
            out.append(tokens[index])
            index += 1
        }
        return out
    }

    // MARK: - Paths

    /// "tylda ukośnik projekty" → ~/projekty; "kropka ukośnik build" →
    /// ./build; "src ukośnik main" → src/main. Terminal only: in prose,
    /// "ukośnik" is far more likely to be a word about a symbol than a path.
    private static func renderPaths(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var index = 0
        while index < tokens.count {
            let word = tokens[index].lowercased()
            let isTilde = tilde.contains(word)
            if isTilde || dot.contains(word), index + 1 < tokens.count,
               slash.contains(tokens[index + 1].lowercased()),
               index + 2 < tokens.count, isWordy(tokens[index + 2]) {
                out.append((isTilde ? "~/" : "./") + tokens[index + 2])
                index += 3
                continue
            }
            if slash.contains(word), index + 1 < tokens.count, isWordy(tokens[index + 1]),
               let left = out.last,
               left.allSatisfy({ $0.isLetter || $0.isNumber || "._-/~".contains($0) }) {
                out[out.count - 1] = left + "/" + tokens[index + 1]
                index += 2
                continue
            }
            out.append(tokens[index])
            index += 1
        }
        return out
    }

    // MARK: - Assembly

    /// Join with spaces, attaching the bracket tokens `renderBrackets`
    /// produced: "(" and "[" glue to what follows, ")" and "]" to what
    /// precedes.
    private static func assemble(_ tokens: [String]) -> String {
        var result = ""
        var glueNext = false
        for token in tokens {
            switch token {
            case "(", "[":
                result += token
                glueNext = true
            case ")", "]":
                result += token
                glueNext = false
            default:
                result += (result.isEmpty || glueNext) ? token : " " + token
                glueNext = false
            }
        }
        return result
    }
}
