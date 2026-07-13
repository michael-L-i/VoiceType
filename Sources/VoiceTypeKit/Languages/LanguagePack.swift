import Foundation

/// Everything the deterministic cleanup path needs to know about one language:
/// its never-content fillers, its spoken punctuation names, and its writing
/// conventions. One Swift file per language (`LanguagePack+English.swift`, …) —
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

    /// Extra lines appended to the LLM cleanup instructions for this language.
    /// Keep minimal — few-shot content leaks into output (see CleanupPrompt).
    public let promptAddendum: String?

    // MARK: - Registry

    /// Every language with bespoke cleanup behavior. Order is irrelevant;
    /// lookup is by primary subtag.
    public static let all: [LanguagePack] = [
        .english, .chinese, .german, .spanish, .french, .italian, .japanese, .korean,
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
        questionSuffixParticles: [],
        promptAddendum: nil)

    /// The pack for a BCP-47 locale ("zh-CN", "en_US"), falling back to
    /// `.neutral` for languages nobody has contributed yet.
    public static func pack(for locale: String) -> LanguagePack {
        let code = LanguageTag.code(for: locale)
        return all.first { $0.code == code } ?? neutral
    }
}
