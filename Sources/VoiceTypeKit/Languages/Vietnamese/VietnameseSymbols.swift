import Foundation

extension SpokenSymbolVocabulary {
    /// Vietnamese tech-dictation vocabulary. It is intentionally invoked from
    /// a pack-owned `CleanupRule`, not assigned to `LanguagePack.symbols`: that
    /// makes the same rendering repair model output and preserves the repository
    /// contract that only English opts into the shared pack field.
    static let vietnamese = SpokenSymbolVocabulary(
        dot: ["chấm"],
        underscore: ["gạch_dưới"],
        dash: ["gạch_ngang", "gạch_nối"],
        slash: ["gạch_chéo"],
        tilde: ["dấu_ngã"],
        comma: ["phẩy"],
        emailAt: ["a_còng"],
        openers: ["mở"],
        closers: ["đóng"],
        parenNouns: ["ngoặc", "ngoặc_tròn"],
        bracketNouns: ["ngoặc_vuông"],
        fileExtensions: [
            "py", "js", "ts", "jsx", "tsx", "rs", "go", "swift", "c", "h", "cpp",
            "hpp", "java", "rb", "php", "sh", "md", "txt", "json", "yaml", "yml",
            "toml", "html", "css", "xml", "sql", "csv", "log", "lock", "env",
            "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "zip",
        ],
        extensionHomophones: [:],
        emailTLDs: [
            "com", "net", "org", "io", "co", "dev", "app", "ai", "edu", "gov",
            "vn", "me",
        ],
        joinGuards: LanguagePack.vietnameseStopwords,
        emailLocalGuards: LanguagePack.vietnameseStopwords.union([
            "xem", "gặp", "gửi", "nhìn", "đi", "vào", "ra", "lại", "đang",
        ]))
}

/// Vietnamese-only text transforms used by the pack's cleanup rules.
///
/// Private-use markers hide characters from shared passes that would otherwise
/// split a decimal comma or collapse a dictated line break. Every producer has
/// the same `runsInTerminal` policy as the final restoring rule, so no marker can
/// leak into terminal output.
enum VietnameseSymbols {
    private static let decimalComma = "\u{E120}"
    private static let lineBreak = "\u{E121}"
    private static let paragraphBreak = "\u{E122}"
    private static let openParen = "\u{E123}"
    private static let closeParen = "\u{E124}"
    private static let openSquare = "\u{E125}"
    private static let closeSquare = "\u{E126}"

    static func protectNumericSeparators(in text: String) -> String {
        replacing(text, pattern: #"(?<=\p{Nd}),(?=\p{Nd})"#, template: decimalComma)
    }

    static func restoreProtectedCharacters(in text: String) -> String {
        var out = text.replacingOccurrences(of: decimalComma, with: ",")
        out = replacing(
            out,
            pattern: #"[ \t]*"# + NSRegularExpression.escapedPattern(for: paragraphBreak) + #"[ \t]*"#,
            template: "\n\n")
        out = replacing(
            out,
            pattern: #"[ \t]*"# + NSRegularExpression.escapedPattern(for: lineBreak) + #"[ \t]*"#,
            template: "\n")
        out = replacing(
            out,
            pattern: NSRegularExpression.escapedPattern(for: openParen) + #"[ \t]*"#,
            template: "(")
        out = replacing(
            out,
            pattern: #"[ \t]*"# + NSRegularExpression.escapedPattern(for: closeParen),
            template: ")")
        out = replacing(
            out,
            pattern: NSRegularExpression.escapedPattern(for: openSquare) + #"[ \t]*"#,
            template: "[")
        out = replacing(
            out,
            pattern: #"[ \t]*"# + NSRegularExpression.escapedPattern(for: closeSquare),
            template: "]")
        return capitalizePlainLineStarts(in: out)
    }

    /// Render explicit, established voice-input commands. Bare `chấm` and
    /// `phẩy` deliberately stay out of this table; the contextual code renderer
    /// and numeric separator rule own those ambiguous forms.
    static func renderPunctuation(in text: String) -> String {
        let commands: [(name: String, mark: String)] = [
            ("chấm xuống dòng", "." + lineBreak),
            ("dấu chấm cảm", "!"),
            ("dấu chấm than", "!"),
            ("dấu cảm thán", "!"),
            ("dấu chấm hỏi", "?"),
            ("dấu chấm phẩy", ";"),
            ("dấu chấm lửng", "…"),
            ("dấu ba chấm", "…"),
            ("dấu hai chấm", ":"),
            ("mở ngoặc kép", "“"),
            ("đóng ngoặc kép", "”"),
            ("mở ngoặc vuông", openSquare),
            ("đóng ngoặc vuông", closeSquare),
            ("mở ngoặc đơn", openParen),
            ("đóng ngoặc đơn", closeParen),
            ("dấu chấm", "."),
            ("dấu phẩy", ","),
            ("dấu hỏi", "?"),
            ("xuống đoạn", paragraphBreak),
            ("xuống dòng", lineBreak),
        ]

        return commands.reduce(text) { current, command in
            let escaped = NSRegularExpression.escapedPattern(for: command.name)
            // Absorb an already-rendered adjacent ASCII mark so "Tốt. dấu
            // chấm" is idempotent, matching the spoken-punctuation contract.
            let pattern = #"(?:[.,!?;:…]\s*)?(?<![\p{L}\p{N}_])"# + escaped
                + #"(?![\p{L}\p{N}_])(?:\s*[.,!?;:…])?"#
            return replacing(
                current,
                pattern: pattern,
                template: NSRegularExpression.escapedTemplate(for: command.mark),
                options: [.caseInsensitive])
        }
    }

    /// Render code-shaped uses of Vietnamese symbol names. Multiword names are
    /// folded into temporary single tokens because `SpokenSymbols` is a token
    /// pipeline; any token it declines to consume is restored to ordinary prose.
    static func renderCode(in text: String, category: AppCategory) -> String {
        var out = text
        let foldedPhrases: [(phrase: String, token: String)] = [
            ("gạch chéo ngược", "gạch_chéo_ngược"),
            ("gạch dưới", "gạch_dưới"),
            ("gạch ngang", "gạch_ngang"),
            ("gạch nối", "gạch_nối"),
            ("gạch chéo", "gạch_chéo"),
            ("dấu ngã", "dấu_ngã"),
            ("a còng", "a_còng"),
            ("ngoặc vuông", "ngoặc_vuông"),
            ("ngoặc tròn", "ngoặc_tròn"),
        ]
        for item in foldedPhrases {
            out = replacingWholePhrase(out, phrase: item.phrase, with: item.token)
        }

        out = SpokenSymbols.render(out, category: category, vocabulary: .vietnamese)

        // Explicit "dấu …" names remain safe even when they are not one of the
        // structural joins supported by `SpokenSymbols`.
        let explicitSymbols: [(name: String, mark: String)] = [
            ("dấu gạch_chéo_ngược", "\\"),
            ("dấu gạch đứng", "|"),
            ("dấu a_còng", "@"),
            ("dấu phần trăm", "%"),
            ("dấu bằng", "="),
            ("dấu cộng", "+"),
            ("dấu trừ", "-"),
            ("dấu sao", "*"),
            ("dấu thăng", "#"),
            ("dấu hai chấm", ":"),
            ("dấu chấm phẩy", ";"),
        ]
        for item in explicitSymbols {
            out = replacingWholePhrase(out, phrase: item.name, with: item.mark)
        }

        // Declined triggers were prose, not code. Restore only our exact folded
        // tokens; underscores created in a real identifier remain untouched.
        for item in foldedPhrases {
            out = out.replacingOccurrences(of: item.token, with: item.phrase)
        }
        return out
    }

    /// Normalize spaces around marks without touching straight quotes, ASCII
    /// ellipses, dashes, or apostrophes that may belong to code/foreign text.
    static func normalizeTypography(in text: String, category: AppCategory) -> String {
        var out = replacing(text, pattern: #"\s+([,.!?;:])"#, template: "$1")
        out = replacing(out, pattern: #"\s+(…)"#, template: "$1")
        out = replacing(out, pattern: #"([,!?;])(?=\S)"#, template: "$1 ")
        out = replacing(out, pattern: #"([“‘(\[\{])\s+"#, template: "$1")
        out = replacing(out, pattern: #"\s+([”’)\]\}])"#, template: "$1")

        // A smart quote produced by an explicit command follows Vietnamese
        // prose spacing. Skip the broader outside-spacing repair in code editors.
        if category != .codeEditor {
            out = replacing(out, pattern: #"(?<=[\p{L}\p{N},;:!?])([“‘])"#, template: " $1")
            out = replacing(out, pattern: #"([”’])(?=\p{L})"#, template: "$1 ")
            out = replacing(out, pattern: #":(?=\p{L})"#, template: ": ")
        }
        return out
    }

    /// CLDR's Vietnamese locale places the đồng sign after the number with a
    /// non-breaking space and writes percent without a gap. Only normalize an
    /// already numeric expression; never turn spoken number words into digits.
    static func normalizeLocalizedNumbers(in text: String, category: AppCategory) -> String {
        guard category != .codeEditor else { return text }
        var out = replacing(
            text,
            pattern: #"(?<=\p{Nd})[ \t\x{00A0}]*₫"#,
            template: "\u{00A0}₫")
        out = replacing(
            out,
            pattern: #"(?<=\p{Nd})[ \t\x{00A0}]+%"#,
            template: "%")
        return out
    }

    private static func replacingWholePhrase(
        _ text: String,
        phrase: String,
        with replacement: String
    ) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: phrase)
        return replacing(
            text,
            pattern: #"(?<![\p{L}\p{N}_])"# + escaped + #"(?![\p{L}\p{N}_])"#,
            template: NSRegularExpression.escapedTemplate(for: replacement),
            options: [.caseInsensitive])
    }

    private static func replacing(
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

    /// The shared capitalization pass cannot see line breaks while they are
    /// protected from whitespace collapse. Apply the same plain-token guard
    /// after restoration so a new Vietnamese sentence is capitalized but a
    /// leading `main.py` or `get_user` identifier is not.
    private static func capitalizePlainLineStarts(in text: String) -> String {
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        guard lines.count > 1 else { return text }
        for index in lines.indices.dropFirst() {
            let token = lines[index].prefix(while: { !$0.isWhitespace })
            let core = token.trimmingCharacters(in: .punctuationCharacters)
            guard let first = lines[index].first, first.isLowercase,
                  !core.isEmpty,
                  core.allSatisfy({ $0.isLetter || $0 == "'" }) else {
                continue
            }
            lines[index] = LanguagePack.vietnamese.uppercased(String(first))
                + lines[index].dropFirst()
        }
        return lines.joined(separator: "\n")
    }
}
