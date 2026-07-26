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
    /// … or sentence-final particles that end one (Chinese 吗, Japanese
    /// ですか). Matched with `hasSuffix`, so a particle may be several
    /// characters long — Korean and Japanese mark questions with verb endings,
    /// which a single-character probe could never see.
    public let questionSuffixParticles: Set<String>

    /// The mark that ends a question in this orthography. Full-width for CJK,
    /// and the extension point for Greek, which writes its question mark ";".
    public let questionMark: String

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

    /// This language's own deterministic fixes, for the conventions the fields
    /// above don't ask about — French's space before `;:!?`, Spanish's opening
    /// `¿`, an engine quirk only this language sees. Run by both cleanup paths
    /// at the stage each rule declares. See `CleanupRule`.
    ///
    /// This is the pack's escape hatch, and deliberately so: improving a
    /// language should never require editing shared code, because that is
    /// where languages collide with each other.
    public let rules: [CleanupRule]

    /// The locale whose casing conventions apply, for orthographies where
    /// Swift's locale-independent `uppercased()` is wrong: Turkish maps `i` to
    /// `İ`, not `I`. Nil means the locale-independent default, which is
    /// correct for almost every language.
    public let casingLocaleIdentifier: String?

    /// True when full-width marks （，。？）are correct output for this
    /// language, so `CleanupPolish` must not "repair" them into ASCII.
    /// Defaults to `usesFullWidthPunctuation`, and is separate from it because
    /// the two are not the same claim: Korean writes spaced words with Latin
    /// punctuation yet still admits full-width marks, and the old shared code
    /// had to hardcode a language list to say so.
    public let preservesFullWidthMarks: Bool

    /// Marks that already end a sentence, so `ensureTerminalPunctuation` leaves
    /// the text alone. Defaults to the Latin + CJK set; a language whose
    /// orthography ends sentences differently (Devanagari `।`, Arabic `؟`)
    /// overrides it.
    public let terminalMarks: Set<Character>

    /// Words that name a symbol out loud and legitimately collapse into one
    /// character during cleanup ("open paren" → `(`). The faithfulness guard
    /// discounts them when counting content words, so a heavily-dictated
    /// identifier doesn't read as a summary. Defaults to the English set,
    /// which is what every language received before packs could say otherwise.
    public let spokenSymbolWords: Set<String>

    /// How aggressively the faithfulness guard judges this language. The
    /// defaults are calibrated on English; agglutinative languages (Turkish,
    /// Korean, Finnish) pack more meaning per word and may need different
    /// ratios. See `CleanupGuardPolicy`.
    public let guardPolicy: CleanupGuardPolicy

    /// Extra regex patterns for `CleanupSanitizer`, matching a conversational
    /// lead-in the model might emit *in this language* ("Klar, hier ist der
    /// bereinigte Text:"). The shared English patterns always apply; these are
    /// added to them.
    public let modelLeadInPatterns: [String]

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
                questionMark: String = "?",
                stopwords: Set<String> = [],
                symbols: SpokenSymbolVocabulary? = nil,
                capitalizedStandalonePronoun: String? = nil,
                prompt: LanguagePromptGuidance = .none,
                rules: [CleanupRule] = [],
                casingLocaleIdentifier: String? = nil,
                preservesFullWidthMarks: Bool? = nil,
                terminalMarks: Set<Character> = LanguagePack.defaultTerminalMarks,
                spokenSymbolWords: Set<String> = LanguagePack.defaultSpokenSymbolWords,
                guardPolicy: CleanupGuardPolicy = .default,
                modelLeadInPatterns: [String] = []) {
        self.code = code
        self.separatesWordsWithSpaces = separatesWordsWithSpaces
        self.usesFullWidthPunctuation = usesFullWidthPunctuation
        self.terminalPeriod = terminalPeriod
        self.fillers = fillers
        self.spokenPunctuation = spokenPunctuation
        self.questionPrefixWords = questionPrefixWords
        self.questionSuffixParticles = questionSuffixParticles
        self.questionMark = questionMark
        self.stopwords = stopwords
        self.symbols = symbols
        self.capitalizedStandalonePronoun = capitalizedStandalonePronoun
        self.prompt = prompt
        self.rules = rules
        self.casingLocaleIdentifier = casingLocaleIdentifier
        self.preservesFullWidthMarks = preservesFullWidthMarks ?? usesFullWidthPunctuation
        self.terminalMarks = terminalMarks
        self.spokenSymbolWords = spokenSymbolWords
        self.guardPolicy = guardPolicy
        self.modelLeadInPatterns = modelLeadInPatterns
    }

    // MARK: - Defaults

    /// Sentence-ending marks across the orthographies shipped so far, plus the
    /// newline a spoken "new paragraph" leaves behind.
    public static let defaultTerminalMarks: Set<Character> =
        Set(".!?:,。！？：，…；;\n")

    /// The English spoken-symbol names, which every language used before a
    /// pack could name its own. Kept as the default so no language silently
    /// changes behavior; a language overrides it with its own words.
    public static let defaultSpokenSymbolWords: Set<String> = [
        "dot", "period", "comma", "dash", "hyphen", "underscore", "slash",
        "backslash", "tilde", "colon", "semicolon", "equals", "plus", "minus",
        "star", "asterisk", "percent", "ampersand", "pipe", "backtick",
        "quote", "unquote", "open", "close", "paren", "parens", "parenthesis",
        "bracket", "brackets", "brace", "braces", "angle", "camel", "case",
        "capital", "uppercase", "lowercase", "newline", "tab", "hash",
        "pound", "dollar", "caret", "at", "sign", "mark", "point", "space",
    ]

    // MARK: - Casing

    /// Uppercase one character the way this language does. Turkish is the
    /// reason this exists: `"i".uppercased()` is `"I"` everywhere except
    /// Turkish and Azerbaijani, where it must be `"İ"`.
    public func uppercased(_ text: String) -> String {
        guard let identifier = casingLocaleIdentifier else { return text.uppercased() }
        return text.uppercased(with: Locale(identifier: identifier))
    }

    // MARK: - Registry

    /// Every language with bespoke cleanup behavior. Order is irrelevant;
    /// lookup is by primary subtag.
    ///
    /// One entry per line, alphabetical by code: this array is the single
    /// shared line every new language must touch, and one-per-line keeps two
    /// contributors landing different languages from colliding on it.
    public static let all: [LanguagePack] = [
        .chinese,
        .czech,
        .danish,
        .dutch,
        .english,
        .finnish,
        .french,
        .german,
        .hungarian,
        .italian,
        .japanese,
        .korean,
        .norwegian,
        .polish,
        .portuguese,
        .romanian,
        .russian,
        .slovak,
        .slovenian,
        .spanish,
        .swedish,
        .turkish,
        .ukrainian,
        .vietnamese,
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
