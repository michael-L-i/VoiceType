import Foundation
import VoiceTypeKit

/// Central place that maps an engine *kind* to a concrete instance and reports
/// which kinds are usable right now. This is the seam the pluggable backends
/// hang off: as whisper.cpp / Groq / FoundationModels land, they're registered
/// here and everything else (resolver, settings UI) picks them up for free.
///
/// `secrets` supplies any API keys (from the Keychain) the cloud engines need.
enum EngineFactory {

    struct Secrets: Sendable {
        var groqAPIKey: String?
        init(groqAPIKey: String? = nil) { self.groqAPIKey = groqAPIKey }
    }

    // MARK: - Transcription

    static func makeTranscriber(_ kind: TranscriptionEngineKind, secrets: Secrets) -> TranscriptionEngine? {
        switch kind {
        case .appleOnDevice:
            return AppleSpeechEngine()
        case .whisperCpp:
            return WhisperCppEngine()
        case .groqCloud:
            guard let key = secrets.groqAPIKey, !key.isEmpty else { return nil }
            return GroqTranscriptionEngine(apiKey: key)
        }
    }

    /// Which transcription engines report themselves available (model present,
    /// key configured, etc). Cloud engines require a key to count as available;
    /// consent is enforced separately by `EngineResolver`.
    static func availableTranscription(secrets: Secrets) async -> Set<TranscriptionEngineKind> {
        var set: Set<TranscriptionEngineKind> = []
        for kind in TranscriptionEngineKind.allCases {
            if let engine = makeTranscriber(kind, secrets: secrets), await engine.isAvailable() {
                set.insert(kind)
            }
        }
        return set
    }

    // MARK: - Cleanup

    static func makeCleaner(_ kind: CleanupEngineKind, secrets: Secrets) -> CleanupEngine {
        switch kind {
        case .ruleBased, .none:
            return RuleBasedCleanup()
        case .foundationModels:
            return FoundationModelsCleanupEngine()
        case .groqCloud:
            guard let key = secrets.groqAPIKey, !key.isEmpty else { return RuleBasedCleanup() }
            return GroqCleanupEngine(apiKey: key)
        }
    }

    static func availableCleanup(secrets: Secrets) async -> Set<CleanupEngineKind> {
        var set: Set<CleanupEngineKind> = [.ruleBased, .none]
        let fm = FoundationModelsCleanupEngine()
        if await fm.isAvailable() { set.insert(.foundationModels) }
        if let key = secrets.groqAPIKey, !key.isEmpty {
            if await GroqCleanupEngine(apiKey: key).isAvailable() { set.insert(.groqCloud) }
        }
        return set
    }
}
