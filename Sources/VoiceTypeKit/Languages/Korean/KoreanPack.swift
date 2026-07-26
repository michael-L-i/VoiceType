import Foundation

extension LanguagePack {
    /// Korean (South Korean standard orthography; keyed on "ko").
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - 어 / 음 / 아 / 그 / 저 / 뭐 / 이제 / 막 / 그러니까: all occur as
    ///   hesitation or discourse fillers, but every one also carries ordinary
    ///   lexical, interactional, or pragmatic meaning. Only distinctly
    ///   prolonged hesitation spellings are removed blindly; the prompt makes
    ///   the contextual decisions.
    /// - 흠: expresses doubt or evaluation, so the old stub's unconditional
    ///   removal erased the speaker's stance.
    /// - Korean word spacing: particles and endings attach, while dependent
    ///   nouns space, but many surface strings require morphological or
    ///   semantic analysis. The deterministic floor fixes punctuation spacing,
    ///   not words.
    /// - Bare 점 ("point/dot/store/score") and 대시 ("dash") never become
    ///   punctuation in prose. The code renderer consumes them only in
    ///   structurally anchored file-name/identifier patterns.
    /// - Informal question endings such as -니, -냐, -나, -요, and -지 are
    ///   also valid in statements or collide with lexical endings. Only formal
    ///   or otherwise distinctive interrogative endings opt into the blind
    ///   question-mark heuristic.
    /// - Number words stay number words. Dates, currency, abbreviations,
    ///   apostrophes, and English brand casing are normalized by the model only
    ///   when context makes the intended written form clear.
    static let korean = LanguagePack(
        code: "ko",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: [
            "으음", "으으음", "어엄",
        ],
        // These are the documented Korean Apple dictation commands plus the
        // unambiguous official Korean names of common marks. Like Apple's
        // dictation UI, speaking about the name itself still renders the mark.
        spokenPunctuation: KoreanCleanup.spokenPunctuation,
        // Korean wh-forms can be indefinite or occur after a topic, so an
        // initial-token list creates more false questions than true ones.
        questionPrefixWords: [],
        questionSuffixParticles: [
            "습니까", "입니까", "까요", "인가요", "는가요", "던가요",
            "었나요", "았나요", "했나요",
        ],
        stopwords: KoreanCleanup.stopwords,
        prompt: .none,
        rules: KoreanCleanup.rules,
        // Modern horizontal Korean uses ASCII-width sentence punctuation, but
        // full-width CJK marks are also legitimate Korean typography. Preserve
        // them rather than treating them as model script drift.
        preservesFullWidthMarks: true,
        spokenSymbolWords: KoreanCleanup.spokenSymbolWords,
        // An eojeol can contain several morphemes, so Korean reaches meaningful
        // length with fewer whitespace tokens than English. Start guarding at
        // six content tokens while keeping the conservative 50% retention bar.
        guardPolicy: CleanupGuardPolicy(minimumContentWords: 6),
        modelLeadInPatterns: [
            #"^\s*(?:네[,!.]?\s*)?(?:다듬은|정리한|정리된|수정한)\s+(?:문장|텍스트|내용)(?:은|는)?\s*(?:다음과\s+같습니다)?\s*:\s*"#,
        ])
}

/// Pack-local mechanics needed because Korean combines space-separated words
/// with a caseless script. No shared engine branch needs to know the locale.
enum KoreanCleanup {
    /// Private-use placeholders survive the shared whitespace/punctuation
    /// passes and are restored before output.
    private static let groupingComma = "\u{E000}"
    private static let lowercaseLatinBoundary = "\u{2060}"
    private static let lineBreak = "\u{E001}"
    private static let paragraphBreak = "\u{E002}"

    static let spokenPunctuation: [String: String] = [
        // Apple Korean dictation commands.
        "마침표": ".",
        "쉼표": ",",
        "느낌표": "!",
        "물음표": "?",
        "달러 기호": "$",
        "괄호 열기": "(",
        "괄호 닫기": ")",
        "따옴표": "“",
        "따옴표 종료": "”",
        "콜론": ":",
        "세미 콜론": ";",
        "세미콜론": ";",
        "해시태그": "#",
        // Official Korean punctuation names that have one literal rendering.
        "가운뎃점": "·",
        "쌍점": ":",
        "쌍반점": ";",
        "빗금": "/",
        "붙임표": "-",
        "물결표": "~",
        "줄임표": "……",
        // Explicit symbol-name phrases; bare 원/퍼센트/앳 remain content.
        "원 기호": "₩",
        "퍼센트 기호": "%",
        "앳 기호": "@",
    ]

    static let stopwords: Set<String> = [
        "이", "그", "저", "것", "수", "등", "및", "또는",
        "그리고", "그러나", "하지만", "그래서", "그러면",
        "나는", "내가", "저는", "제가", "우리", "우리는",
        "너", "네가", "당신", "그가", "그녀가",
        "여기", "거기", "저기", "이것", "그것", "저것",
        "예", "네", "아니요", "아니", "잠깐",
        "어", "음", "아", "그", "저", "뭐", "이제", "막", "그러니까",
    ]

    static let spokenSymbolWords: Set<String> = [
        "마침표", "쉼표", "느낌표", "물음표", "기호", "괄호", "열기", "닫기",
        "따옴표", "종료", "콜론", "세미", "세미콜론", "해시태그",
        "가운뎃점", "쌍점", "쌍반점", "빗금", "붙임표", "물결표", "줄임표",
        "점", "닷", "언더스코어", "대시", "하이픈", "슬래시", "틸드",
        "골뱅이", "앳", "여는", "닫는", "소괄호", "대괄호", "브래킷",
        "새로운", "줄", "단락",
    ]

    static let rules: [CleanupRule] = [
        CleanupRule(
            name: "protect Korean numeric grouping commas",
            stage: .early,
            runsInTerminal: true
        ) { text, _ in
            replace(text, pattern: #"(?<=\d),(?=\d{3}(?:\D|$))"#,
                    template: groupingComma)
        },
        CleanupRule(
            name: "render Korean dictation commands and spoken code symbols",
            stage: .early,
            runsInTerminal: true
        ) { text, context in
            var out = text
            // Apple documents these as formatting commands. Mask them because
            // the shared Latin whitespace pass intentionally flattens newlines.
            out = out.replacingOccurrences(of: "새로운 단락", with: paragraphBreak)
            out = out.replacingOccurrences(of: "새로운 줄", with: lineBreak)
            out = renderSpokenPunctuation(out)
            return SpokenSymbols.render(
                out, category: context.category, vocabulary: .korean)
        },
        CleanupRule(
            name: "protect lowercase Latin text from Korean sentence casing",
            stage: .early
        ) { text, _ in
            // Hangul has no case. Preserve the transcriber's casing for a
            // leading Latin brand, command, or identifier instead of applying
            // English sentence capitalization to Korean dictation.
            replace(
                text,
                pattern: #"(^|[.!?]\s+)([a-z])(?=[A-Za-z']*(?:[\p{P}\s]|$))"#,
                template: "$1\(lowercaseLatinBoundary)$2")
        },
        CleanupRule(
            name: "restore Korean numeric grouping commas",
            stage: .afterPunctuation,
            runsInTerminal: true
        ) { text, _ in
            text.replacingOccurrences(of: groupingComma, with: ",")
        },
        CleanupRule(
            name: "attach Korean numeric symbols",
            stage: .afterPunctuation,
            runsInTerminal: true
        ) { text, _ in
            var out = replace(
                text,
                pattern: #"([₩$€¥])\s+(?=\d)"#,
                template: "$1")
            out = replace(
                out,
                pattern: #"(?<=\d)\s+([%‰℃°])"#,
                template: "$1")
            return out
        },
        CleanupRule(
            name: "normalize Korean prose punctuation spacing",
            stage: .afterPunctuation
        ) { text, context in
            // Do not rewrite string literals or syntax in a code editor.
            guard context.category != .codeEditor else { return text }
            var out = replace(text, pattern: #"\s*·\s*"#, template: "·")
            out = replace(
                out,
                pattern: #"([\(\[\{“‘「『《〈"])\s+"#,
                template: "$1")
            out = replace(
                out,
                pattern: #"\s+([\)\]\}”’」』》〉"])"#,
                template: "$1")
            // In Korean prose a colon after a Hangul label is followed by a
            // space; numeric time/ratio colons and code are intentionally out.
            out = replace(
                out,
                pattern: #"(?<=[가-힣]):(?=[가-힣0-9])"#,
                template: ": ")
            return out
        },
        CleanupRule(
            name: "restore Korean line breaks and Latin casing",
            stage: .final
        ) { text, _ in
            var out = text.replacingOccurrences(
                of: lowercaseLatinBoundary, with: "")
            out = replace(
                out,
                pattern: #"\s*\u{E002}\s*"#,
                template: "\n\n")
            out = replace(
                out,
                pattern: #"\s*\u{E001}\s*"#,
                template: "\n")
            return out
        },
    ]

    private static func renderSpokenPunctuation(_ text: String) -> String {
        var out = text
        let absorbed = #"[，。、；：？！,.!?;:]*"#
        for (name, mark) in spokenPunctuation.sorted(by: { $0.key.count > $1.key.count }) {
            let pattern = absorbed
                + NSRegularExpression.escapedPattern(for: name)
                + absorbed
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(out.startIndex..., in: out)
            out = regex.stringByReplacingMatches(
                in: out,
                range: range,
                withTemplate: NSRegularExpression.escapedTemplate(for: mark))
        }
        return out
    }

    private static func replace(_ text: String,
                                pattern: String,
                                template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: template)
    }
}
