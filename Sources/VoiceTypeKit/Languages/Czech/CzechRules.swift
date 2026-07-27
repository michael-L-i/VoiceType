import Foundation

/// Czech orthography that cannot be expressed by `LanguagePack`'s declarative
/// fields. These rules run over both raw transcription and model output.
///
/// Sources (ÚJČ AV ČR, consulted 2026-07):
/// - Uvozovky: primary Czech quotes are „…“, tight to their contents.
/// - Tři tečky: an ellipsis is one character `…`, not three periods.
/// - Členění čísel…: a decimal comma has no space on either side.
/// - Zkratky čistě grafické / Tečka: abbreviation dots do not double at a
///   sentence end and are followed by a normal lowercase continuation.
enum CzechOrthography {
    /// The shared capitalization pass treats every token-final ASCII period as
    /// a sentence boundary. Hide periods inside known abbreviations until the
    /// final stage so `např. další` never becomes `např. Další`.
    static let abbreviationDot: Character = "\u{2024}" // ONE DOT LEADER

    /// The shared punctuation-spacing pass inserts a space after every tight
    /// ASCII comma. Hide only commas already tight between digits, preserving
    /// the user's distinction between decimal `3,14` and list `3, 14`.
    static let decimalComma: Character = "\u{FE50}" // SMALL COMMA

    /// Inserted inside filler tokens in a terminal so the ordinary filler pass
    /// cannot delete a literal command argument such as `echo ehm`.
    static let terminalFillerShield = "\u{2060}" // WORD JOINER

    static let questionPrefixWords: Set<String> = [
        "co", "čeho", "čemu", "čím", "copak",
        "kdo", "koho", "komu", "kým", "kdopak",
        "čí", "čího", "číhož", "čími",
        "kdy", "odkdy", "dokdy",
        "kde", "kam", "odkud", "kudy",
        "proč", "pročpak",
        "jak", "jaký", "jaká", "jaké", "jací", "jakého", "jakému",
        "jakou", "jakým", "jakými", "jakých",
        "který", "která", "které", "kteří", "kterého", "kterému",
        "kterou", "kterým", "kterými", "kterých",
        "kolik", "kolika", "kolikátý", "kolikátá", "kolikáté",
    ]

    /// Multi-word interrogative openers whose first token is a preposition and
    /// therefore invisible to the shared first-token question heuristic.
    static let multiwordQuestionOpeners: Set<String> = [
        "za jak", "do kdy", "od kdy", "s kým", "o kom", "o čem", "v čem",
        "na co", "na koho", "pro koho", "kvůli čemu", "bez čeho",
    ]

    /// Abbreviations whose period normally sits inside a continuing sentence.
    /// End-prone `atd.`, `apod.`, and `atp.` are omitted: masking one before a
    /// genuinely new sentence would suppress the required next capital.
    private static let abbreviations: [String] = [
        "např.", "kupř.", "popř.", "tj.", "tzn.", "tzv.", "mj.", "resp.",
        "č.", "čís.", "odst.", "písm.", "str.", "obr.", "tab.", "čl.",
        "mil.", "mld.", "n. l.", "př. n. l.",
        "a. s.", "s. r. o.", "v. o. s.", "v. v. i.", "o. p. s.", "z. s.",
        "z. ú.",
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

    static func maskTerminalFillers(_ text: String, context: CleanupContext) -> String {
        guard context.category == .terminal else { return text }
        let names = LanguagePack.czech.fillers
            .sorted { $0.count > $1.count }
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
        guard let regex = try? NSRegularExpression(
            pattern: "\\b(?:\(names))\\b", options: [.caseInsensitive]) else {
            return text
        }
        var out = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let range = Range(match.range, in: out),
                  let first = out[range].indices.first else { continue }
            let insertion = out.index(after: first)
            out.insert(contentsOf: terminalFillerShield, at: insertion)
        }
        return out
    }

    static func normalizeProseTypography(_ text: String,
                                        context: CleanupContext) -> String {
        guard context.category == .general || context.category == .messaging else {
            return text
        }
        var out = replace(text, pattern: "\\.{3,}", template: "…")
        out = replace(out, pattern: "“([^“”\\n]+)”", template: "„$1“")
        out = replace(out, pattern: "\"([^\"\\n]+)\"", template: "„$1“")
        out = replace(out, pattern: "„\\s+", template: "„")
        out = replace(out, pattern: "\\s+“", template: "“")
        return out
    }

    /// Mark questions sentence by sentence, including preposition-led Czech
    /// openers and later sentences the shared whole-dictation probe cannot see.
    static func markQuestions(_ text: String) -> String {
        let single = questionPrefixWords
            .sorted { $0.count > $1.count }
            .map { NSRegularExpression.escapedPattern(for: $0) }
            .joined(separator: "|")
        let multi = multiwordQuestionOpeners
            .sorted { $0.count > $1.count }
            .map {
                NSRegularExpression.escapedPattern(for: $0)
                    .replacingOccurrences(of: "\\ ", with: "\\s+")
            }
            .joined(separator: "|")
        let pattern =
            "(^|(?<=[.!?])\\s+)([„“\"]?(?:(?:\(multi))|(?:\(single))\\b)[^.!?]*?)\\."
        return replace(text, pattern: pattern, template: "$1$2?",
                       options: [.caseInsensitive])
    }

    /// `CleanupPolish` repairs only the first word of model output, while a
    /// Czech dictation may contain several sentences. Mirror the shared
    /// plain-word guard sentence by sentence, with abbreviation periods still
    /// masked so `např. nový` does not become `např. Nový`.
    static func capitalizeSentenceStarts(_ text: String) -> String {
        var words: [String] = []
        var capitalizeNext = true
        for token in text.split(separator: " ") {
            var word = String(token)
            let core = word.trimmingCharacters(in: .punctuationCharacters)
            let isPlain = !core.isEmpty
                && core.allSatisfy { $0.isLetter || $0 == "'" || $0 == "’" }
            if capitalizeNext, isPlain, let first = word.first, first.isLowercase {
                word = String(first).uppercased() + word.dropFirst()
            }
            capitalizeNext = word.hasSuffix(".")
                || word.hasSuffix("!")
                || word.hasSuffix("?")
            words.append(word)
        }
        return words.joined(separator: " ")
    }

    private static func replace(_ text: String, pattern: String, template: String,
                                options: NSRegularExpression.Options = []) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text, range: NSRange(text.startIndex..., in: text),
            withTemplate: template)
    }
}

extension LanguagePack {
    static let czechRules: [CleanupRule] = [
        // Protect literal terminal arguments from Czech's filler lexicon.
        CleanupRule(name: "protect fillers in terminal",
                    stage: .early, runsInTerminal: true) { text, context in
            CzechOrthography.maskTerminalFillers(text, context: context)
        },

        CleanupRule(name: "mask abbreviation periods", stage: .early) { text, _ in
            CzechOrthography.maskAbbreviationDots(text)
        },

        // This pair intentionally runs in terminals too: `tool 3,14` must not
        // become two shell arguments while shared punctuation spacing runs.
        CleanupRule.regex(
            name: "mask decimal comma",
            stage: .early,
            runsInTerminal: true,
            pattern: "(?<=\\d),(?=\\d)",
            template: String(CzechOrthography.decimalComma)),

        CleanupRule(name: "normalize Czech quotes and ellipsis",
                    stage: .early) { text, context in
            CzechOrthography.normalizeProseTypography(text, context: context)
        },

        // Uses a narrow neighbor-guarded vocabulary in prose and the fuller
        // flag/path/parenthesis vocabulary only in technical app categories.
        CleanupRule(name: "render guarded Czech spoken symbols",
                    stage: .early, runsInTerminal: true) { text, context in
            CzechSymbols.render(text, context: context)
        },

        CleanupRule.regex(
            name: "restore decimal comma",
            stage: .afterPunctuation,
            runsInTerminal: true,
            pattern: String(CzechOrthography.decimalComma),
            template: ","),

        // Runs after the shared heuristic and terminal-period insertion so it
        // can repair preposition-led and non-initial questions ending in ".".
        CleanupRule(name: "mark Czech questions sentence by sentence",
                    stage: .final) { text, _ in
            CzechOrthography.markQuestions(text)
        },

        CleanupRule(name: "capitalize every Czech sentence start",
                    stage: .final) { text, _ in
            CzechOrthography.capitalizeSentenceStarts(text)
        },

        CleanupRule(name: "restore abbreviation periods", stage: .final) { text, _ in
            text.replacingOccurrences(
                of: String(CzechOrthography.abbreviationDot), with: ".")
        },

        CleanupRule(name: "restore protected terminal fillers",
                    stage: .final, runsInTerminal: true) { text, context in
            guard context.category == .terminal else { return text }
            return text.replacingOccurrences(
                of: CzechOrthography.terminalFillerShield, with: "")
        },
    ]
}
