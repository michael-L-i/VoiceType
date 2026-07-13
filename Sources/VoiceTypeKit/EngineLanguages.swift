import Foundation

/// Which languages each transcription engine can actually transcribe, keyed by
/// ISO 639-1 primary subtag ("en", "zh"). The engines' language sets don't
/// overlap cleanly (Parakeet is European-only; Nemotron covers 40 locales), so
/// the picker offers the union and `EngineResolver` falls back to a compatible
/// engine instead of intersecting everyone down to the lowest common set.
public struct EngineLanguageSupport: Sendable, Equatable {
    /// Supported language codes per engine. A missing entry means "unknown —
    /// assume yes": Apple's set is queried from the OS at runtime and injected
    /// by the app layer, and an engine we know nothing about shouldn't be
    /// filtered out by stale metadata.
    public var codes: [TranscriptionEngineKind: Set<String>]

    public init(codes: [TranscriptionEngineKind: Set<String>] = [:]) {
        self.codes = codes
    }

    public func supports(_ kind: TranscriptionEngineKind, locale: String) -> Bool {
        guard let supported = codes[kind] else { return true }
        return supported.contains(LanguageTag.code(for: locale))
    }
}

/// Static model facts: the languages each downloadable model was trained on,
/// from its vendor's model card. Apple's list is runtime-queried (nil here).
/// Sources (verified 2026-07-12):
/// - Parakeet TDT 0.6B v3 — huggingface.co/nvidia/parakeet-tdt-0.6b-v3
/// - Nemotron 3.5 ASR streaming 0.6B — huggingface.co/nvidia/nemotron-3.5-asr-streaming-0.6b
/// - Whisper — the tokenizer's 99-language list (base is the multilingual build)
public enum EngineLanguages {

    public static func staticCodes(for kind: TranscriptionEngineKind) -> Set<String>? {
        switch kind {
        case .appleOnDevice: return nil
        case .parakeet: return parakeetV3
        case .whisperKit: return whisper
        case .nemotron: return nemotron
        }
    }

    /// Parakeet TDT v3: exactly 25 European languages. No CJK.
    static let parakeetV3: Set<String> = [
        "bg", "hr", "cs", "da", "nl", "en", "et", "fi", "fr", "de", "el", "hu",
        "it", "lv", "lt", "mt", "pl", "pt", "ro", "sk", "sl", "es", "sv", "ru",
        "uk",
    ]

    /// Nemotron 3.5 ASR: the model card's tier-1 + tier-2 locales, reduced to
    /// primary subtags. Tier-3 "adaptation-ready" languages (el, lt, lv, mt,
    /// sl, he, th, nn) are deliberately excluded — the card says they perform
    /// poorly without fine-tuning, and Nemotron's strict language filter would
    /// turn that into empty transcripts.
    static let nemotron: Set<String> = [
        // Tier 1
        "en", "es", "fr", "it", "pt", "nl", "de", "tr", "ru", "ar", "hi", "ja",
        "ko", "vi", "uk",
        // Tier 2
        "pl", "sv", "cs", "nb", "da", "bg", "fi", "hr", "sk", "zh", "hu", "ro",
        "et",
    ]

    /// Whisper's multilingual tokenizer languages (99).
    static let whisper: Set<String> = [
        "en", "zh", "de", "es", "ru", "ko", "fr", "ja", "pt", "tr", "pl", "ca",
        "nl", "ar", "sv", "it", "id", "hi", "fi", "vi", "he", "uk", "el", "ms",
        "cs", "ro", "da", "hu", "ta", "no", "th", "ur", "hr", "bg", "lt", "la",
        "mi", "ml", "cy", "sk", "te", "fa", "lv", "bn", "sr", "az", "sl", "kn",
        "et", "mk", "br", "eu", "is", "hy", "ne", "mn", "bs", "kk", "sq", "sw",
        "gl", "mr", "pa", "si", "km", "sn", "yo", "so", "af", "oc", "ka", "be",
        "tg", "sd", "gu", "am", "yi", "lo", "uz", "fo", "ht", "ps", "tk", "nn",
        "mt", "sa", "lb", "my", "bo", "tl", "mg", "as", "tt", "haw", "ln", "ha",
        "ba", "jw", "su",
    ]
}
