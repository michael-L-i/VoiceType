import Foundation

/// Always-correct Bokmål mechanics that the declarative pack fields cannot
/// express. Contextual choices stay in `NorwegianPrompt`.
enum NorwegianOrthography {
    // The shared sentence-capitalization pass treats every token ending in "."
    // as a sentence boundary. Mask abbreviation and date dots until `.final`
    // so "f.eks. kaffe" and "17. mai" do not become "f.eks. Kaffe" / "17. Mai".
    static let abbreviationDot: Character = "\u{2024}"  // ONE DOT LEADER
    static let dateDot: Character = "\u{2027}"          // HYPHENATION POINT
    static let decimalComma: Character = "\u{201A}"     // SINGLE LOW-9 QUOTATION MARK

    /// Abbreviations that conventionally introduce following material.
    ///
    /// Entries such as `osv.`, `o.l.` and `e.l.` are deliberately excluded:
    /// they commonly end a sentence, where masking would stop the next real
    /// sentence from receiving its capital. `f.eks.`, `bl.a.`, `dvs.` and the
    /// other entries below overwhelmingly point forward.
    static let forwardAbbreviations: [String] = [
        "f.eks.", "bl.a.", "dvs.", "m.a.o.", "pga.", "mht.", "iht.",
        "t.o.m.", "f.o.m.", "jf.", "ca.", "ev.", "evt.", "inkl.", "ekskl.",
        "maks.", "min.", "kl.", "nr.", "fig.", "tab.", "kap.", "s.", "tlf.",
        "dr.", "prof.",
    ]

    private static let abbreviationRegex: NSRegularExpression? = {
        let names = forwardAbbreviations
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

    static let months = [
        "januar", "februar", "mars", "april", "mai", "juni",
        "juli", "august", "september", "oktober", "november", "desember",
    ]

    private static let datedMonthRegex: NSRegularExpression? = {
        let monthAlternation = months.joined(separator: "|")
        return try? NSRegularExpression(
            pattern: "(?<!\\d)([1-9]|[12]\\d|3[01])\\.(\\s+)(\(monthAlternation))\\b",
            options: [.caseInsensitive])
    }()

    static func maskDateDots(_ text: String) -> String {
        guard text.contains("."), let regex = datedMonthRegex else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(
            in: text, range: range,
            withTemplate: "$1\(dateDot)$2$3")
    }

    /// Month names are always lowercase in a written Norwegian date. Restrict
    /// the repair to a preceding day number so a person or brand named Mai is
    /// never lowercased elsewhere.
    static func normalizeDatedMonths(_ text: String) -> String {
        guard let regex = datedMonthRegex else { return text }
        var out = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let monthRange = Range(match.range(at: 3), in: out) else { continue }
            out.replaceSubrange(monthRange, with: out[monthRange].lowercased())
        }
        return out
    }

    // MARK: - Spoken identifiers

    static let extensions: Set<String> = [
        "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h",
        "cpp", "hpp", "java", "rb", "php", "sh", "md", "txt", "json",
        "yaml", "yml", "toml", "html", "css", "xml", "sql", "csv", "log",
        "lock", "env", "pdf",
        "no", "com", "net", "org", "io", "co", "dev", "app", "ai", "edu",
        "gov", "me", "eu",
    ]

    /// Words that normally surround a mention *of* a symbol rather than a
    /// dictated identifier ("ordet bindestrek brukes", "sett inn en
    /// skråstrek"). Kept local rather than added to the faithfulness
    /// stopwords: these are content words in every other context.
    private static let symbolProseGuards: Set<String> = [
        "ord", "ordet", "ordene", "tegn", "tegnet", "symbolet",
        "skriv", "skriver", "skrive", "sett", "sette", "bruk", "bruker",
        "bruke", "inn", "mellom", "kalles", "heter",
    ]

    private static func isJoinable(_ token: String) -> Bool {
        !token.isEmpty
            && token.allSatisfy { $0.isLetter || $0.isNumber || "._-/~@".contains($0) }
            && !LanguagePack.norwegianStopwords.contains(token.lowercased())
            && !symbolProseGuards.contains(token.lowercased())
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

    static func renderSpokenIdentifiers(_ text: String) -> String {
        var tokens = text.split(separator: " ").map(String.init)
        for trigger in ["krøllalfa", "alfakrøll"] {
            tokens = join(tokens, trigger: trigger, separator: "@")
        }
        for trigger in ["understrek", "underscore"] {
            tokens = join(tokens, trigger: trigger, separator: "_")
        }
        tokens = join(tokens, trigger: "bindestrek", separator: "-")
        tokens = join(tokens, trigger: "skråstrek", separator: "/")
        tokens = joinExtensions(tokens)
        return tokens.joined(separator: " ")
    }

    private static func join(_ tokens: [String],
                             trigger: String,
                             separator: String) -> [String] {
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
            if tokens[i].lowercased() == "punktum",
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

    private static let slashToken = "\u{0001}slash"

    static func renderTerminalSymbols(_ text: String) -> String {
        let raw = text.split(separator: " ").map(String.init)
        var tokens: [String] = []
        var i = 0
        while i < raw.count {
            if raw[i].lowercased() == "skråstrek" {
                tokens.append(slashToken)
                i += 1
            } else {
                tokens.append(raw[i])
                i += 1
            }
        }
        tokens = renderPaths(tokens)
        tokens = renderFlags(tokens)
        return tokens
            .joined(separator: " ")
            .replacingOccurrences(of: slashToken, with: "skråstrek")
    }

    private static func renderPaths(_ tokens: [String]) -> [String] {
        var out: [String] = []
        var i = 0
        while i < tokens.count {
            let current = tokens[i].lowercased()
            if (current == "tilde" || current == "punktum"),
               i + 2 < tokens.count, tokens[i + 1] == slashToken,
               isWordy(tokens[i + 2]) {
                out.append((current == "tilde" ? "~/" : "./") + tokens[i + 2])
                i += 3
                continue
            }
            if tokens[i] == slashToken, i + 1 < tokens.count,
               isWordy(tokens[i + 1]), let left = out.last, isWordy(left) {
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
            let current = tokens[i].lowercased()
            let isFlagWord = current == "bindestrek" || current == "minus"
            if current == "dobbel", i + 2 < tokens.count,
               ["bindestrek", "minus"].contains(tokens[i + 1].lowercased()),
               isWordy(tokens[i + 2]) {
                out.append("--" + tokens[i + 2])
                i += 3
                continue
            }
            if isFlagWord, i + 1 < tokens.count {
                let next = tokens[i + 1].lowercased()
                if ["bindestrek", "minus"].contains(next), i + 2 < tokens.count,
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

    // MARK: - Prose typography

    static func normalizeQuantitySpacing(_ text: String,
                                         context: CleanupContext) -> String {
        // Programming expressions (`value%2`, `$0`, `10ms`) should survive in
        // a code editor. Terminal rules already opt out at the rule level.
        guard context.category != .codeEditor else { return text }
        var out = replace(text, pattern: "([€$£])\\s*(?=\\d)", template: "$1 ")
        out = replace(out,
                      pattern: "(?<=\\d)\\s*(kr|NOK)\\b",
                      template: " $1",
                      options: [.caseInsensitive])
        out = replace(out, pattern: "(?<=\\d)\\s*%", template: " %")
        out = replace(out,
                      pattern: "(?<=\\d)\\s*°\\s*[cC]\\b",
                      template: " °C")
        out = replace(
            out,
            pattern: "(?<=\\d)\\s*(kg|mg|g|km|cm|mm|m|l|ml|cl|dl|ms|min|t)\\b",
            template: " $1",
            options: [.caseInsensitive])
        return out
    }

    /// Turn an explicitly supplied period into a question mark for reliably
    /// shaped questions, including one after another sentence. Content
    /// questions need an interrogative opener. Yes/no questions need BOTH a
    /// finite auxiliary/copula and an explicit pronoun subject; that prevents
    /// "er på vei" and "kan møte i morgen" from becoming questions.
    static func repairQuestionPeriods(_ text: String) -> String {
        let interrogatives = [
            "hva", "hvem", "hvilken", "hvilket", "hvilke", "hvor",
            "hvorfra", "hvorhen", "hvordan", "hvorfor", "hvorledes", "når",
        ].joined(separator: "|")
        let auxiliaries = [
            "er", "var", "har", "hadde", "kan", "kunne", "skal", "skulle",
            "vil", "ville", "må", "måtte", "bør", "burde", "får", "fikk",
            "blir", "ble", "finnes",
        ].joined(separator: "|")
        let pronouns = [
            "jeg", "du", "han", "hun", "hen", "vi", "dere", "de", "det",
            "den", "man",
        ].joined(separator: "|")
        let opener = "(?:\(interrogatives))\\b|(?:\(auxiliaries))\\s+(?:\(pronouns))\\b"
        return replace(
            text,
            pattern: "(^|(?<=[.!?])\\s+)((?:\(opener))[^.!?]*?)\\.",
            template: "$1$2?",
            options: [.caseInsensitive])
    }

    private static func replace(
        _ text: String,
        pattern: String,
        template: String,
        options: NSRegularExpression.Options = []
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(
            in: text, range: range, withTemplate: template)
    }
}

extension LanguagePack {
    static let norwegianRules: [CleanupRule] = [
        // Terminal-only work runs before the general spoken-identifier pass,
        // so "tilde skråstrek" can become "~/" before "skråstrek" is joined.
        CleanupRule(name: "spoken Norwegian shell flags and paths",
                    stage: .early, runsInTerminal: true) { text, context in
            guard context.category == .terminal else { return text }
            return NorwegianOrthography.renderTerminalSymbols(text)
        },

        CleanupRule(name: "spoken Norwegian identifier symbols",
                    stage: .early, runsInTerminal: true) { text, _ in
            NorwegianOrthography.renderSpokenIdentifiers(text)
        },

        CleanupRule(name: "mask Norwegian abbreviation periods",
                    stage: .early) { text, _ in
            NorwegianOrthography.maskAbbreviationDots(text)
        },

        CleanupRule(name: "mask Norwegian date periods",
                    stage: .early) { text, _ in
            NorwegianOrthography.maskDateDots(text)
        },

        // The shared Latin spacing pass inserts a space after any comma
        // followed by a non-space. Hide only commas tight between digits:
        // "3,14" is a decimal, while "30, 40 personer" remains a list.
        CleanupRule.regex(
            name: "mask Norwegian decimal comma",
            stage: .early,
            runsInTerminal: true,
            pattern: "(?<=\\d),(?=\\d)",
            template: String(NorwegianOrthography.decimalComma)),

        // Preserve the three-dot hesitation/omission mark; otherwise the
        // shared repeated-punctuation pass collapses it to one period.
        CleanupRule(name: "preserve Norwegian ellipsis",
                    stage: .early) { text, context in
            guard context.category != .codeEditor else { return text }
            return text.replacingOccurrences(
                of: #"\.{3,}"#, with: "…", options: .regularExpression)
        },

        CleanupRule.regex(
            name: "restore Norwegian decimal comma",
            stage: .afterPunctuation,
            runsInTerminal: true,
            pattern: String(NorwegianOrthography.decimalComma),
            template: ","),

        CleanupRule(name: "space Norwegian quantities",
                    stage: .afterPunctuation) { text, context in
            NorwegianOrthography.normalizeQuantitySpacing(text, context: context)
        },

        CleanupRule(name: "repair Norwegian question periods",
                    stage: .final) { text, _ in
            NorwegianOrthography.repairQuestionPeriods(text)
        },

        CleanupRule(name: "restore Norwegian date periods",
                    stage: .final) { text, _ in
            let restored = text.replacingOccurrences(
                of: String(NorwegianOrthography.dateDot), with: ".")
            return NorwegianOrthography.normalizeDatedMonths(restored)
        },

        CleanupRule(name: "restore Norwegian abbreviation periods",
                    stage: .final) { text, _ in
            text.replacingOccurrences(
                of: String(NorwegianOrthography.abbreviationDot), with: ".")
        },
    ]
}
