import Foundation

extension LanguagePack {
    /// Bulgarian (български; keyed on "bg").
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - `а` is a conjunction, while `ами`, `значи`, `нали`, `така`, `такова`,
    ///   and `в смисъл` all have ordinary discourse or lexical meanings. Only
    ///   unmistakably prolonged hesitation spellings are blind fillers; the
    ///   model may remove the other forms when context proves they are empty.
    /// - `мхм`, `аха`, `да`, `не`, `ех`, and `ах` communicate agreement,
    ///   disagreement, or emotion. They are never deterministic fillers.
    /// - `точка` can mean a point, location, grade, or full stop. It is not a
    ///   flat spoken-punctuation replacement; the Bulgarian symbol rule uses it
    ///   only beside a known file extension, email TLD, or terminal path.
    /// - The interrogative clitic `ли` can occur inside a statement
    ///   ("Не знам има ли време"). The shared first-token heuristic handles
    ///   unambiguous question openers and sentence-final `ли`; contextual
    ///   punctuation for other `ли` questions belongs to the model.
    /// - Decimal points are not blindly changed to commas: dots also occur in
    ///   versions, dates, IPv4 addresses, and identifiers. Existing Bulgarian
    ///   decimal commas are protected deterministically; conversion needs
    ///   context and is requested from the model.
    /// - No spelling or homophone correction is attempted in code. In
    ///   particular, `и` → `ѝ` needs syntax and semantic context, and rare
    ///   names or embedded English identifiers must not be guessed.
    static let bulgarian = LanguagePack(
        code: "bg",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        // Research on spontaneous Bulgarian identifies prolonged [ъ] and [a]
        // as hesitation vowels. A single `а` is meaningful, so only sustained
        // or explicitly nasalized transcriptions are safe here.
        fillers: [
            "ъъ", "ъъъ", "ъъъъ",
            "ъм", "ъъм", "ъъъм",
            "аа", "ааа", "аааа",
        ],
        // The local spoken-symbol rule handles these names. Keeping the flat
        // table empty prevents unconditional `точка` replacement and lets the
        // same vocabulary repair model output as well as raw transcription.
        spokenPunctuation: [:],
        questionPrefixWords: [
            "кой", "коя", "кое", "кои", "кого", "кому",
            "чий", "чия", "чие", "чии",
            "какво", "какъв", "каква", "какви",
            "къде", "откъде", "докъде", "накъде",
            "кога", "защо", "как", "колко", "дали",
        ],
        questionSuffixParticles: [" ли"],
        stopwords: LanguagePack.bulgarianStopwords,
        prompt: .bulgarian,
        rules: BulgarianCleanup.rules,
        spokenSymbolWords: BulgarianCleanup.spokenSymbolWords,
        modelLeadInPatterns: [
            #"(?is)^\s*(?:разбира се[,!]?\s*)?(?:ето|това е)\s+(?:почистеният|редактираният|коригираният)\s+(?:текст|транскрипт|транскрипция)[\s:–—-]+"#,
        ])

    /// Function words must not become parts of identifiers merely because
    /// `точка`, `долна черта`, or another spoken trigger follows them.
    static let bulgarianStopwords: Set<String> = [
        "а", "ако", "ала", "ами", "без", "беше", "би", "бих", "биха",
        "бихме", "бихте", "бях", "бяха", "бяхме", "бяхте",
        "в", "вас", "ваш", "ваша", "ваше", "ваши", "ви", "вие", "все",
        "всички", "всичко", "във",
        "да", "дали", "до", "е", "за", "защото", "и", "или", "им", "има",
        "как", "какво", "като", "кога", "кой", "колко", "къде",
        "между", "ме", "ми", "му", "на", "над", "нали", "нас", "не", "него",
        "нея", "ние", "ни", "но", "няма",
        "от", "по", "под", "при", "са", "с", "си", "сме", "сте", "със", "съм",
        "така", "такова", "те", "теб", "тебе", "ти", "това", "той", "тя", "то",
        "че", "ще", "я",
        // Explicit repair markers may disappear with retracted words, so they
        // do not prove that the opening of the dictation was lost.
        "всъщност", "извинявай", "нека", "поправка", "чакай",
    ]
}
