import Foundation

extension LanguagePack {
    /// Ukrainian.
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `ну`, `так`, `типу`, `значить`, `коротше`, `власне`, and `ось` can
    ///   all carry meaning. The deterministic pass keeps them; the LLM may
    ///   remove one only when context proves it is a throwaway hesitation.
    /// - A bare `е`, `ем`, `гм`, or `мм` can be a spelled letter, an
    ///   acknowledgement, or an expressive sound. Only explicitly prolonged
    ///   `е-е` / `е-е-е` vocalizations are deterministic fillers.
    /// - `крапка`, `кома`, `мінус`, and `підкреслення` are ordinary nouns.
    ///   They are never replaced blindly. `UkrainianSpokenSymbols` renders
    ///   them only in a structurally clear file-name, identifier, email,
    ///   bracket, flag, or terminal-path context.
    /// - Ukrainian yes/no questions can be marked by intonation alone. The
    ///   rules recognize explicit interrogative openers but do not guess from
    ///   word order, and they do not rewrite non-initial sentences.
    /// - Missing apostrophes inside a word (`обєкт` → `об’єкт`) require lexical
    ///   knowledge and remain LLM work. The rules only normalize an apostrophe
    ///   that is already present.
    /// - A dot between digits can be a date, version, IPv4 address, or decimal
    ///   copied from code. Rules compact date-like dot groups but never change
    ///   a dot into a decimal comma. They do protect an existing decimal comma
    ///   from the shared punctuation-spacing pass.
    /// - Dash-versus-minus judgment and grammatical capitalization of names
    ///   are contextual, so no blind rewrite attempts them.
    static let ukrainian = LanguagePack(
        code: "uk",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["е-е", "е-е-е"],
        spokenPunctuation: [:],
        questionPrefixWords: [
            "що", "хто", "кого", "кому", "ким", "коли", "де", "куди",
            "звідки", "чому", "навіщо", "як", "який", "яка", "яке", "які",
            "якого", "якої", "яких", "скільки", "чий", "чия", "чиє", "чиї",
            "чи", "хіба", "невже",
        ],
        questionSuffixParticles: [],
        stopwords: LanguagePack.ukrainianStopwords,
        prompt: .ukrainian,
        rules: UkrainianRules.all,
        spokenSymbolWords: UkrainianSpokenSymbols.words,
        modelLeadInPatterns: [
            #"(?i)^\s*(?:звичайно|гаразд|добре),?\s+ось\s+(?:очищений|відредагований|виправлений)\s+(?:текст|транскрипт|запис)\s*:\s*"#,
        ])

    /// Function words ignored by the faithfulness opening probe and refused as
    /// identifier components by the Ukrainian spoken-symbol renderer.
    static let ukrainianStopwords: Set<String> = [
        "і", "й", "та", "а", "але", "або", "чи", "що", "щоб", "як",
        "до", "з", "зі", "із", "у", "в", "на", "за", "від", "для", "про",
        "при", "по", "над", "під", "без", "між",
        "це", "цей", "ця", "ці", "той", "та", "те", "ті",
        "я", "ми", "ти", "ви", "він", "вона", "воно", "вони",
        "мене", "мені", "мій", "моя", "моє", "мої", "наш", "ваш",
        "є", "був", "була", "було", "були", "буде", "бути",
        "не", "ні", "так", "тут", "там", "тоді", "тепер",
        // Self-correction markers may legitimately disappear with a retracted
        // phrase, so their absence is not evidence of summarization.
        "стоп", "тобто", "точніше", "перепрошую", "вірніше",
    ]
}

private enum UkrainianRules {
    /// Private-use placeholder: an existing decimal comma is masked only long
    /// enough to survive the shared `fixPunctuationSpacing` pass.
    private static let decimalComma = "\u{E100}"
    /// ONE DOT LEADER is punctuation (so sentence-initial capitalization still
    /// sees a plain word) but does not trigger the shared sentence boundary.
    private static let abbreviationDot = "\u{2024}"

    static let all: [CleanupRule] = [
        UkrainianSpokenSymbols.rule,

        CleanupRule(
            name: "render unambiguous Ukrainian spoken punctuation",
            stage: .early
        ) { text, _ in
            let punctuation: [String: String] = [
                "відкрита квадратна дужка": "[",
                "закрита квадратна дужка": "]",
                "відкрита кругла дужка": "(",
                "закрита кругла дужка": ")",
                "відкрита фігурна дужка": "{",
                "закрита фігурна дужка": "}",
                "крапка з комою": ";",
                "відкриті лапки": "«",
                "закриті лапки": "»",
                "знак питання": "?",
                "знак оклику": "!",
                "три крапки": "…",
                "двокрапка": ":",
            ]
            var out = text
            for (name, mark) in punctuation.sorted(by: { $0.key.count > $1.key.count }) {
                out = replace(
                    out,
                    pattern: #"(?i)\b"# + NSRegularExpression.escapedPattern(for: name) + #"\b"#,
                    template: mark)
            }
            // Attach paired marks and ellipses after phrase replacement.
            out = replace(out, pattern: #"([\[({«])\s+"#, template: "$1")
            out = replace(out, pattern: #"\s+([\])}»])"#, template: "$1")
            out = replace(out, pattern: #"\s+…"#, template: "…")
            out = replace(out, pattern: #"…(?=\S)"#, template: "… ")
            // If the recognizer already emitted a mark and also transcribed the
            // spoken command, the explicitly dictated (second) mark wins.
            out = replace(out, pattern: #"\.+…"#, template: "…")
            out = replace(out, pattern: #"([.!?])\s*…"#, template: "…")
            out = replace(out, pattern: #"…\s*([.!?])"#, template: "$1")
            out = replace(out, pattern: #"([.!?])\s+([.!?])"#, template: "$2")
            return out
        },

        CleanupRule(
            name: "normalize Ukrainian in-word apostrophes",
            stage: .early
        ) { text, _ in
            replace(
                text,
                pattern: #"(?<=\p{Cyrillic})\s*['’‘ʼ]\s*(?=\p{Cyrillic})"#,
                template: "'")
        },

        CleanupRule(
            name: "protect Ukrainian decimal commas",
            stage: .early,
            runsInTerminal: true
        ) { text, _ in
            replace(
                text,
                pattern: #"(?<=\d),(?=\d)"#,
                template: decimalComma)
        },

        CleanupRule(
            name: "preserve ellipses in Ukrainian prose",
            stage: .early
        ) { text, context in
            guard context.category != .codeEditor else { return text }
            return replace(text, pattern: #"\.{3,}"#, template: "…")
        },

        CleanupRule(
            name: "protect Ukrainian abbreviation periods",
            stage: .early
        ) { text, _ in
            replace(
                text,
                pattern: #"(?i)\b(напр|тобто|пор|див|рис|табл|стор|ім|вул|обл|р-н|ст|с|м|р|п)\.(?=\s+\p{Ll})"#,
                template: "$1" + abbreviationDot)
        },

        CleanupRule.regex(
            name: "compact Ukrainian numeric dates",
            stage: .afterPunctuation,
            pattern: #"\b(\d{1,2})\s*\.\s*(\d{1,2})\s*\.\s*(\d{2,4})\b"#,
            template: "$1.$2.$3"),

        CleanupRule(
            name: "use Ukrainian outer quotation marks",
            stage: .afterPunctuation
        ) { text, _ in
            // Require Cyrillic content so ASCII code strings, JSON, and inch
            // measurements remain byte-for-byte untouched.
            replace(
                text,
                pattern: #""([^"\n]*\p{Cyrillic}[^"\n]*)""#,
                template: "«$1»")
        },

        CleanupRule(
            name: "restore Ukrainian protected punctuation",
            stage: .final,
            runsInTerminal: true
        ) { text, _ in
            text
                .replacingOccurrences(of: decimalComma, with: ",")
                // An abbreviation at the end of a sentence receives the same
                // physical dot from both roles; do not emit two.
                .replacingOccurrences(of: abbreviationDot + ".", with: ".")
                .replacingOccurrences(of: abbreviationDot, with: ".")
        },

        CleanupRule(
            name: "use nonbreaking spaces in Ukrainian numeric groups and units",
            stage: .final
        ) { text, _ in
            var out = text
            // Preserve only grouping the speaker/transcriber already supplied;
            // never guess whether an ungrouped digit string is a quantity.
            out = replace(
                out,
                pattern: #"(?<=\d)[ \u00A0](?=\d{3}(?:\D|$))"#,
                template: "\u{00A0}")
            out = replace(
                out,
                pattern: #"(?<=\d)[ \u00A0]+(?=(?:грн\b|₴|[%‰]|°[CС]|(?:кг|г|км|м|см|мм)\b))"#,
                template: "\u{00A0}",
                options: [.caseInsensitive])
            return out
        },

        CleanupRule(
            name: "restore typographic Ukrainian apostrophes",
            stage: .final
        ) { text, _ in
            replace(
                text,
                pattern: #"(?<=\p{Cyrillic})'(?=\p{Cyrillic})"#,
                template: "’")
        },
    ]

    private static func replace(
        _ text: String,
        pattern: String,
        template: String,
        options: NSRegularExpression.Options = []
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: template)
    }
}
