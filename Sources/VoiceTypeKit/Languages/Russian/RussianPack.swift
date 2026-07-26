import Foundation

extension LanguagePack {
    /// Russian (ru-RU orthography and typography).
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `ну`, `вот`, `значит`, `короче`, `типа`, `как бы`, `это самое`:
    ///   all can organize discourse or carry ordinary lexical meaning. The
    ///   deterministic pass keeps them; the model may remove them only when
    ///   context proves that they are throwaway hesitation.
    /// - `э`, `эм`, `м-м`, `ммм`, `гм`: a single `э` and `эм` can be dictated
    ///   letter names, while the nasal forms can express doubt, agreement, or
    ///   pleasure. Only visibly lengthened `ээ`/`эээ` and `э-э`/`э-э-э` are
    ///   blind-safe fillers.
    /// - `точка`, `плюс`, `минус`: besides punctuation or code, these mean a
    ///   point/location, an advantage, and a disadvantage. `точка` renders
    ///   only when the spoken-symbol pipeline can prove a file extension,
    ///   email domain, or terminal path; plus/minus remain model territory.
    /// - Specific conventional controls such as `вопросительный знак`,
    ///   `точка с запятой`, and `новая строка` do render unconditionally in
    ///   prose. Dictating *about* one of those controls therefore renders it,
    ///   the same explicit trade-off as Apple/Yandex/Microsoft dictation.
    /// - Russian yes/no questions are normally marked by intonation, and `ли`
    ///   is usually second rather than final. The deterministic heuristic can
    ///   only catch interrogative-word openers; it intentionally does not
    ///   guess intonation or rewrite embedded `ли` clauses.
    /// - `е` versus `ё`, `не` versus `ни`, `-тся` versus `-ться`, agreement,
    ///   commas, and proper-name casing require lexical/syntactic judgment.
    ///   The model gets guidance; blind rules never invent a spelling.
    /// - Decimal dots are not converted to commas: Russian standards prefer a
    ///   comma in prose, but dots are legitimate in versions, IP addresses,
    ///   identifiers, and machine-readable data. Existing decimal commas are
    ///   protected from the shared punctuation-spacing pass instead.
    /// - Apostrophes are preserved. Modern Russian uses them in foreign names
    ///   and at Latin/Cyrillic suffix boundaries; replacing them with `ъ`
    ///   would corrupt legitimate text.
    static let russian = LanguagePack(
        code: "ru",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["ээ", "эээ", "э-э", "э-э-э"],
        // Single-word names such as `точка` are too ambiguous for the flat,
        // unconditional table. Russian-owned rules below render the safer
        // conventional commands and run on model output as well.
        spokenPunctuation: [:],
        questionPrefixWords: [
            "что", "кто", "когда", "где", "куда", "откуда", "почему",
            "зачем", "как", "какой", "какая", "какое", "какие", "какого",
            "какую", "каким", "какими", "сколько", "чей", "чья", "чьё",
            "чьи", "кому", "кого",
        ],
        questionSuffixParticles: [],
        stopwords: LanguagePack.russianStopwords,
        prompt: .russian,
        rules: RussianCleanupRules.all,
        spokenSymbolWords: RussianSpokenSymbols.spokenWords,
        modelLeadInPatterns: [
            #"(?i)^\s*(?:конечно|хорошо|ладно)[,!.]+\s*(?:вот|ниже)[^\n:]{0,70}:\s+"#,
            #"(?i)^\s*(?:вот|ниже)?\s*(?:очищенн(?:ый|ая)|исправленн(?:ый|ая)|отредактированн(?:ый|ая))\s+(?:текст|транскрипт|расшифровка|версия)\s*:\s+"#,
        ])

    /// Function words carry too little lexical identity to prove that a model
    /// preserved the beginning of a dictation, and must never become pieces of
    /// a rendered identifier merely because they surround `подчёркивание`.
    static let russianStopwords: Set<String> = [
        "а", "без", "бы", "был", "была", "были", "было", "в", "вам", "вас",
        "ваш", "ваша", "ваше", "ваши", "ведь", "во", "вот", "все", "всё",
        "вы", "где", "да", "для", "до", "его", "ее", "её", "если", "есть",
        "еще", "ещё", "же", "за", "здесь", "и", "из", "или", "им", "их",
        "как", "к", "когда", "кто", "ли", "либо", "мне", "мы", "на", "над",
        "не", "него", "нее", "неё", "нет", "ни", "но", "ну", "о", "об",
        "однако", "он", "она", "они", "оно", "от", "по", "под", "при", "про",
        "с", "со", "так", "там", "тебе", "тебя", "то", "тоже", "тот", "ты",
        "у", "уже", "хотя", "чем", "что", "чтобы", "эта", "эти", "это", "я",
        // Conversational lead-ins and correction markers may legitimately
        // disappear during cleanup, so they cannot prove content retention.
        "ладно", "короче", "значит", "вообще", "нет", "неверно", "точнее",
        "вернее", "стоп", "подожди", "извини",
    ]
}

private enum RussianCleanupRules {
    static let all: [CleanupRule] = [
        // These placeholders shield Russian sequences from shared passes that
        // otherwise split 3,14, collapse ... to ".", or treat the periods in
        // `т. е.` as sentence boundaries. Both halves run in terminals so a
        // placeholder can never leak.
        CleanupRule(
            name: "protect Russian decimals ellipses and abbreviations",
            stage: .early,
            runsInTerminal: true
        ) { text, _ in
            RussianOrthography.maskProtectedSequences(text)
        },
        CleanupRule(
            name: "render context-anchored Russian spoken symbols",
            stage: .early,
            runsInTerminal: true
        ) { text, context in
            RussianSpokenSymbols.render(text, category: context.category)
        },
        CleanupRule(
            name: "restore Russian decimals ellipses and abbreviations",
            stage: .final,
            runsInTerminal: true
        ) { text, _ in
            RussianOrthography.restoreProtectedSequences(text)
        },
        CleanupRule(
            name: "render unambiguous Russian dictation commands",
            stage: .afterPunctuation
        ) { text, _ in
            RussianSpokenPunctuation.render(text)
        },
        CleanupRule(
            name: "normalize Russian quote typography",
            stage: .afterPunctuation
        ) { text, _ in
            RussianOrthography.normalizeQuotes(text)
        },
        CleanupRule(
            name: "keep Russian grouped numbers amounts and units together",
            stage: .afterPunctuation
        ) { text, context in
            guard context.category != .codeEditor else { return text }
            return RussianOrthography.normalizeNumberSpacing(text)
        },
        CleanupRule(
            name: "place Russian periods outside closing quotes",
            stage: .final
        ) { text, _ in
            RussianOrthography.normalizeQuotePunctuation(text)
        },
    ]
}

private enum RussianOrthography {
    // Private-use placeholders are deliberately non-punctuation so the shared
    // punctuation and capitalization passes cannot reinterpret their content.
    private static let decimalComma = "\u{E120}"
    private static let ellipsis = "\u{E121}"
    private static let questionEllipsis = "\u{E122}"
    private static let exclamationEllipsis = "\u{E123}"
    private static let abbreviationPeriod = "\u{E124}"

    static func maskProtectedSequences(_ input: String) -> String {
        var text = input
        text = replacing(text, pattern: #"\?\.\."#, template: questionEllipsis)
        text = replacing(text, pattern: #"!\.\."#, template: exclamationEllipsis)
        text = replacing(text, pattern: #"\.\.\."#, template: ellipsis)
        text = replacing(text, pattern: #"(?<=\d),(?=\d)"#, template: decimalComma)

        // Academic spelling references require spaces in т. е., т. д., т. п.
        // Capture the letters so an existing sentence-initial capital survives.
        text = replacing(
            text,
            pattern: #"(?i)(?<![\p{L}\p{N}])([т])\s*\.\s*([едп])\s*\."#,
            template: "$1\(abbreviationPeriod) $2\(abbreviationPeriod)")
        return text
    }

    static func restoreProtectedSequences(_ input: String) -> String {
        var text = input
            // The shared terminal-period pass cannot see punctuation while it
            // is masked. Discard only the period it appended immediately after
            // a protected terminal sequence.
            .replacingOccurrences(of: questionEllipsis + ".", with: questionEllipsis)
            .replacingOccurrences(of: exclamationEllipsis + ".", with: exclamationEllipsis)
            .replacingOccurrences(of: ellipsis + ".", with: ellipsis)
            .replacingOccurrences(of: abbreviationPeriod + ".", with: abbreviationPeriod)
            .replacingOccurrences(of: questionEllipsis, with: "?..")
            .replacingOccurrences(of: exclamationEllipsis, with: "!..")
            .replacingOccurrences(of: ellipsis, with: "...")
            .replacingOccurrences(of: decimalComma, with: ",")
            .replacingOccurrences(of: abbreviationPeriod, with: ".")
        if text.hasPrefix("т. е.") || text.hasPrefix("т. д.") || text.hasPrefix("т. п.") {
            text.replaceSubrange(text.startIndex...text.startIndex, with: "Т")
        }
        return text
    }

    static func normalizeQuotes(_ input: String) -> String {
        var text = input
        // Russian computer typography uses guillemets as the outer pair.
        text = replacing(
            text,
            pattern: #"“([^”\n]+)”"#,
            template: "«$1»")
        text = replacing(
            text,
            pattern: #""([^"\n]+)""#,
            template: "«$1»")
        text = replacing(text, pattern: #"«[ \t]+"#, template: "«")
        text = replacing(text, pattern: #"[ \t]+»"#, template: "»")
        return text
    }

    static func normalizeNumberSpacing(_ input: String) -> String {
        var text = input
        let nbsp = "\u{00A0}"

        // Preserve an already-dictated grouping while preventing a line break.
        // We do not insert group separators into an ungrouped digit string:
        // that could be a phone number, account number, or identifier.
        text = replacing(
            text,
            pattern: #"(?<=\d)[ \t]+(?=\d{3}(?:\D|$))"#,
            template: nbsp)

        // Russian standards put symbols and unit designations after the number
        // with a space. Restrict the blind fix to a compact, well-known set.
        text = replacing(
            text,
            pattern: #"(?<=\d)[ \t]*(?=(?:₽|руб\.|р\.|коп\.|%|‰)(?:\s|$|[,.!?;:]))"#,
            template: nbsp)
        text = replacing(
            text,
            pattern: #"(?<=\d)[ \t]*(?=(?:°[CС]|кг|мг|г|км|см|мм|м|мл|л|кВт|Вт|Гц|МГц|КБ|МБ|ГБ|ТБ)(?:\s|$|[,.!?;:]))"#,
            template: nbsp)
        return text
    }

    static func normalizeQuotePunctuation(_ input: String) -> String {
        var text = input
        // A full stop never sits immediately before a Russian closing quote.
        // If the shared terminal pass has already added the outside full stop,
        // remove only the duplicate inside one.
        text = replacing(text, pattern: #"\.»\."#, template: "».")
        text = replacing(text, pattern: #"\.»(?=[,;:—\s])"#, template: "»")
        text = replacing(text, pattern: #"\.»$"#, template: "».")
        // Question/exclamation/ellipsis marks belonging to the quoted sentence
        // already end the surrounding sentence; the shared period is redundant.
        text = replacing(text, pattern: #"([?!…])»\.$"#, template: "$1»")
        text = replacing(text, pattern: #"(\.\.\.)»\.$"#, template: "$1»")
        if text.hasPrefix("«") {
            let letter = text.index(after: text.startIndex)
            if letter < text.endIndex, text[letter].isLowercase {
                text.replaceSubrange(letter...letter, with: String(text[letter]).uppercased())
            }
        }
        return text
    }

    private static func replacing(_ input: String,
                                  pattern: String,
                                  template: String,
                                  options: NSRegularExpression.Options = []) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return input
        }
        return regex.stringByReplacingMatches(
            in: input,
            range: NSRange(input.startIndex..., in: input),
            withTemplate: template)
    }
}
