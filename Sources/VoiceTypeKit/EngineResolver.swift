import Foundation

/// Decides *which* engine kind should actually run, given the user's preference,
/// what is available right now, and consent. This is pure policy — it returns a
/// kind; the app constructs the concrete engine. Keeping it here makes the
/// privacy/fallback rules testable in isolation.
public enum EngineResolver {

    /// Resolve the transcription engine to use.
    /// - Parameters:
    ///   - preferred: the user's choice.
    ///   - cloudEnabled: master consent for off-device paths.
    ///   - available: set of engine kinds reporting themselves available.
    /// - Returns: the kind to run. Always returns a value: rule-based-equivalent
    ///   for transcription is whisper/ apple; if nothing is available we still
    ///   return the preferred local kind so the caller can surface a clear error.
    public static func resolveTranscription(preferred: TranscriptionEngineKind,
                                            cloudEnabled: Bool,
                                            available: Set<TranscriptionEngineKind>) -> TranscriptionEngineKind {
        // Never use a cloud engine without consent.
        if preferred.isCloud && !cloudEnabled {
            return firstAvailableLocalTranscription(available: available) ?? .appleOnDevice
        }
        if available.contains(preferred) {
            return preferred
        }
        // Preferred not available — downgrade through the local chain.
        return firstAvailableLocalTranscription(available: available) ?? preferred
    }

    private static func firstAvailableLocalTranscription(available: Set<TranscriptionEngineKind>) -> TranscriptionEngineKind? {
        for kind in [TranscriptionEngineKind.appleOnDevice, .whisperCpp] where available.contains(kind) {
            return kind
        }
        return nil
    }

    /// Resolve the cleanup engine to use. Rule-based is always the floor.
    public static func resolveCleanup(preferred: CleanupEngineKind,
                                      cloudEnabled: Bool,
                                      available: Set<CleanupEngineKind>) -> CleanupEngineKind {
        if preferred == .none { return .none }
        if preferred.isCloud && !cloudEnabled {
            return firstAvailableLocalCleanup(available: available)
        }
        if preferred == .ruleBased { return .ruleBased }
        if available.contains(preferred) {
            return preferred
        }
        return firstAvailableLocalCleanup(available: available)
    }

    private static func firstAvailableLocalCleanup(available: Set<CleanupEngineKind>) -> CleanupEngineKind {
        if available.contains(.foundationModels) { return .foundationModels }
        // Rule-based needs no availability check — it always works.
        return .ruleBased
    }
}
