import Foundation

/// Everything the deterministic cleanup path needs to know about one language:
/// its never-content fillers, its spoken punctuation names, and its writing
/// conventions. One directory per language (`Languages/English/EnglishPack.swift`, …) —
/// adding a language means adding a pack, registering it in `all`, and shipping
/// tests plus eval cases with it. See docs/LOCALIZATION.md.
///
/// Packs are Swift values rather than JSON resources so `VoiceTypeKit` stays
/// resource-free and every entry is type-checked and unit-testable.
public struct LanguagePack: Sendable {
    /// ISO 639-1 primary subtag ("en", "zh").
    public let code: String

    /// False for languages written without spaces between words (CJK). Gates
    /// every word-boundary-based pass: regex fillers, sentence capitalization.
    public let separatesWordsWithSpaces: Bool

    /// True when the language's orthography uses full-width punctuation
    /// （，。？）. Swaps `fixPunctuationSpacing` for `CJKPunctuation.normalize`.
    public let usesFullWidthPunctuation: Bool

    /// The sentence-terminal mark `ensureTerminalPunctuation` appends ("." / "。").
    public let terminalPeriod: String

    /// Standalone disfluencies that are NEVER content in this language.
    /// Ambiguous fillers (zh 那个/就是, en "like") are deliberately excluded —
    /// judging those needs meaning, which is LLM territory, not a blind rule.
    public let fillers: Set<String>

    /// Spoken punctuation names → the rendered mark ("句号" → "。"). Applied as
    /// direct longest-name-first replacement, so it only suits languages where
    /// the names are unambiguous enough to render unconditionally; leave empty
    /// to opt out (English uses the richer `SpokenSymbols` pipeline instead).
    public let spokenPunctuation: [String: String]

    /// Question heuristics for the deterministic question-mark rule: words that
    /// open a direct question (English "what/is/can…") …
    public let questionPrefixWords: Set<String>
    /// … or sentence-final particles that end one (Chinese 吗).
    public let questionSuffixParticles: Set<String>

    /// Function words that prove nothing about a sentence's content: the guard
    /// skips them when probing whether a dictation's opening survived, and the
    /// spoken-symbol renderer refuses to join them into identifiers. Empty is
    /// safe — it only makes both checks more conservative.
    public let stopwords: Set<String>

    /// The words this language uses to speak a symbol out loud. Non-nil opts
    /// the language into the `SpokenSymbols` token pipeline ("main dot pie" →
    /// main.py); nil skips it entirely, which is what every language except
    /// English does today.
    public let symbols: SpokenSymbolVocabulary?

    /// A one-letter pronoun written capitalized even mid-sentence — English
    /// "i" → "I". Nil for every other language, which is the common case:
    /// almost no orthography has one.
    public let capitalizedStandalonePronoun: String?

    /// What this language contributes to the LLM cleanup instruction — its
    /// hesitation sounds, capitalization rule, spoken-code triggers. See
    /// `LanguagePromptGuidance`; `.none` means "generic instructions".
    public let prompt: LanguagePromptGuidance

    /// Explicit rather than synthesized so a language can fill in only the
    /// fields it needs: everything after `questionSuffixParticles` defaults to
    /// "this language doesn't do that", and adding a new field here never
    /// touches the 16 existing packs.
    public init(code: String,
                separatesWordsWithSpaces: Bool,
                usesFullWidthPunctuation: Bool,
                terminalPeriod: String,
                fillers: Set<String>,
                spokenPunctuation: [String: String],
                questionPrefixWords: Set<String>,
                questionSuffixParticles: Set<String>,
                stopwords: Set<String> = [],
                symbols: SpokenSymbolVocabulary? = nil,
                capitalizedStandalonePronoun: String? = nil,
                prompt: LanguagePromptGuidance = .none) {
        self.code = code
        self.separatesWordsWithSpaces = separatesWordsWithSpaces
        self.usesFullWidthPunctuation = usesFullWidthPunctuation
        self.terminalPeriod = terminalPeriod
        self.fillers = fillers
        self.spokenPunctuation = spokenPunctuation
        self.questionPrefixWords = questionPrefixWords
        self.questionSuffixParticles = questionSuffixParticles
        self.stopwords = stopwords
        self.symbols = symbols
        self.capitalizedStandalonePronoun = capitalizedStandalonePronoun
        self.prompt = prompt
    }

    // MARK: - Registry

    /// Every language with bespoke cleanup behavior. Order is irrelevant;
    /// lookup is by primary subtag.
    public static let all: [LanguagePack] = [
        .english, .chinese, .german, .spanish, .french, .italian, .japanese, .korean, .dutch, .polish, .portuguese, .russian, .swedish, .turkish, .ukrainian, .vietnamese,
    ]

    /// Languages without a pack get neutral behavior: no fillers, no spoken
    /// punctuation, whitespace words, ASCII period — exactly what non-English
    /// locales received before packs existed.
    public static let neutral = LanguagePack(
        code: "",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: [],
        spokenPunctuation: [:],
        questionPrefixWords: [],
        questionSuffixParticles: [])

    /// The pack for a BCP-47 locale ("zh-CN", "en_US"), falling back to
    /// `.neutral` for languages nobody has contributed yet.
    public static func pack(for locale: String) -> LanguagePack {
        let code = LanguageTag.code(for: locale)
        return all.first { $0.code == code } ?? neutral
    }
}
