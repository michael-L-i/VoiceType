import Foundation

/// Decides *which* engine kind should actually run, given the user's preference
/// and what is available right now. This is pure policy — it returns a kind; the
/// app constructs the concrete engine. Keeping it here makes the fallback rules
/// testable in isolation. Everything resolves to an on-device engine.
public enum EngineResolver {

    /// Resolve the transcription engine to use.
    /// - Parameters:
    ///   - preferred: the user's choice.
    ///   - available: set of engine kinds reporting themselves available.
    ///   - locale: the BCP-47 dictation language.
    ///   - support: which languages each engine can transcribe.
    /// - Returns: the kind to run. Always returns a value, preferring engines
    ///   that can actually transcribe the language: the preferred engine when
    ///   available and language-compatible, else the first compatible available
    ///   one (`allCases` order puts Apple first), else the preferred/first
    ///   available regardless of language (the UI has already warned), else the
    ///   preferred kind so the caller can surface a clear error.
    public static func resolveTranscription(preferred: TranscriptionEngineKind,
                                            available: Set<TranscriptionEngineKind>,
                                            locale: String,
                                            support: EngineLanguageSupport) -> TranscriptionEngineKind {
        if available.contains(preferred), support.supports(preferred, locale: locale) {
            return preferred
        }
        if let compatible = firstAvailableTranscription(available: available,
                                                        where: { support.supports($0, locale: locale) }) {
            return compatible
        }
        if available.contains(preferred) {
            return preferred
        }
        return firstAvailableTranscription(available: available, where: { _ in true }) ?? preferred
    }

    private static func firstAvailableTranscription(available: Set<TranscriptionEngineKind>,
                                                    where matches: (TranscriptionEngineKind) -> Bool) -> TranscriptionEngineKind? {
        for kind in TranscriptionEngineKind.allCases where available.contains(kind) && matches(kind) {
            return kind
        }
        return nil
    }

    /// Resolve the cleanup engine to use. Rule-based is always the floor.
    public static func resolveCleanup(preferred: CleanupEngineKind,
                                      available: Set<CleanupEngineKind>) -> CleanupEngineKind {
        if preferred == .none { return .none }
        if preferred == .ruleBased { return .ruleBased }
        if available.contains(preferred) {
            return preferred
        }
        return firstAvailableCleanup(available: available)
    }

    private static func firstAvailableCleanup(available: Set<CleanupEngineKind>) -> CleanupEngineKind {
        if available.contains(.foundationModels) { return .foundationModels }
        // Rule-based needs no availability check — it always works.
        return .ruleBased
    }
}
