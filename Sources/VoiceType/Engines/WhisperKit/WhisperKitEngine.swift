import Foundation
import WhisperKit
import VoiceTypeKit

/// The Whisper variant we run: multilingual `base` — a good size/speed balance
/// that delivers WhisperKit's main value over Apple/Parakeet (broad language
/// coverage). Both download and load must reference the same name.
private let whisperKitModelVariant = "openai_whisper-base"

/// Process-wide cache of the loaded WhisperKit pipeline. Loading compiles the
/// CoreML model onto the Neural Engine, so we do it once and reuse it across the
/// per-dictation engine instances.
actor WhisperKitRuntime {
    static let shared = WhisperKitRuntime()
    private var pipe: WhisperKit?

    /// A loaded pipeline, loading already-downloaded weights from disk (no
    /// network). Throws if the model isn't present (gate on the install marker).
    func loadedPipe() async throws -> WhisperKit {
        if let pipe { return pipe }
        let pipe = try await WhisperKit(WhisperKitConfig(model: whisperKitModelVariant, download: false))
        self.pipe = pipe
        return pipe
    }

    /// Download the model (reporting progress) then load it ready for use.
    func download(progress: @escaping @Sendable (Double?) -> Void) async throws {
        _ = try await WhisperKit.download(variant: whisperKitModelVariant,
                                          progressCallback: { progress($0.fractionCompleted) })
        pipe = try await WhisperKit(WhisperKitConfig(model: whisperKitModelVariant, download: false))
    }

    func unload() { pipe = nil }
}

/// On-device transcription via OpenAI Whisper, run as CoreML on the Neural Engine
/// by WhisperKit. The multilingual option for languages Apple/Parakeet don't cover.
final class WhisperKitEngine: TranscriptionEngine {
    let kind: TranscriptionEngineKind = .whisperKit

    func isAvailable() async -> Bool { WhisperKitModelManager().isInstalled() }

    // Qualified return type: WhisperKit also exports a `TranscriptionResult`.
    func transcribe(_ audio: PCMBuffer, locale: String) async throws -> VoiceTypeKit.TranscriptionResult {
        guard WhisperKitModelManager().isInstalled() else {
            throw TranscriptionError.unavailable(reason: "Download the WhisperKit model in Settings before using it.")
        }
        let start = Date()

        let pipe: WhisperKit
        do {
            pipe = try await WhisperKitRuntime.shared.loadedPipe()
        } catch {
            throw TranscriptionError.unavailable(reason: "Couldn't load the WhisperKit model: \(error.localizedDescription)")
        }

        let text: String
        do {
            // The array overload returns one result per decoded segment; join them.
            let results = try await pipe.transcribe(audioArray: AudioSamples.mono16k(audio))
            text = results.map(\.text).joined(separator: " ")
        } catch {
            throw TranscriptionError.failed("WhisperKit transcription failed: \(error.localizedDescription)")
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { throw TranscriptionError.noSpeechDetected }
        return VoiceTypeKit.TranscriptionResult(text: trimmed, locale: locale,
                                                processingTime: Date().timeIntervalSince(start))
    }
}

/// Manages the Whisper weights WhisperKit caches under Application Support.
struct WhisperKitModelManager: TranscriptionModelManager {
    let kind: TranscriptionEngineKind = .whisperKit

    func isInstalled() -> Bool { ModelInstallMarker.isInstalled(.whisperKit) }

    func download(progress: @escaping @Sendable (Double?) -> Void) async throws {
        try await WhisperKitRuntime.shared.download(progress: progress)
        ModelInstallMarker.set(true, for: .whisperKit)
    }

    func delete() async throws {
        ModelInstallMarker.set(false, for: .whisperKit)
        await WhisperKitRuntime.shared.unload()
        // WhisperKit caches Hugging Face snapshots under Application Support/huggingface.
        ModelCache.remove(at: ModelCache.applicationSupport("huggingface", "models", "argmaxinc", "whisperkit-coreml"))
    }
}
