import Foundation
import VoiceTypeKit

/// Central place that maps an engine *kind* to a concrete instance and reports
/// which kinds are usable right now. This is the seam the pluggable backends
/// hang off: as new on-device engines land, they're registered here and
/// everything else (resolver, settings UI) picks them up for free.
enum EngineFactory {

    // MARK: - Transcription

    static func makeTranscriber(_ kind: TranscriptionEngineKind) -> TranscriptionEngine? {
        switch kind {
        case .appleOnDevice:
            return AppleSpeechEngine()
        case .parakeet:
            return ParakeetEngine()
        case .whisperKit:
            return WhisperKitEngine()
        case .nemotron:
            return NemotronEngine()
        }
    }

    /// The download/cache manager for an engine's weights, or nil for the
    /// built-in Apple engine which ships with the OS.
    static func modelManager(for kind: TranscriptionEngineKind) -> TranscriptionModelManager? {
        switch kind {
        case .appleOnDevice:
            return nil
        case .parakeet:
            return ParakeetModelManager()
        case .whisperKit:
            return WhisperKitModelManager()
        case .nemotron:
            return NemotronModelManager()
        }
    }

    /// Which transcription engines report themselves available (model present,
    /// permission granted, etc).
    static func availableTranscription() async -> Set<TranscriptionEngineKind> {
        var set: Set<TranscriptionEngineKind> = []
        for kind in TranscriptionEngineKind.allCases {
            if let engine = makeTranscriber(kind), await engine.isAvailable() {
                set.insert(kind)
            }
        }
        return set
    }

    // MARK: - Cleanup

    static func makeCleaner(_ kind: CleanupEngineKind) -> CleanupEngine {
        switch kind {
        case .ruleBased, .none:
            return RuleBasedCleanup()
        case .foundationModels:
            return FoundationModelsCleanupEngine()
        }
    }

    static func availableCleanup() async -> Set<CleanupEngineKind> {
        var set: Set<CleanupEngineKind> = [.ruleBased, .none]
        let fm = FoundationModelsCleanupEngine()
        if await fm.isAvailable() { set.insert(.foundationModels) }
        return set
    }
}
