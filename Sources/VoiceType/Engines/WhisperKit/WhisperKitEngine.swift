import Foundation
import WhisperKit
import VoiceTypeKit

/// The Whisper variant we run: multilingual "base" — small (~150 MB) and fast.
/// Download and load must reference the same name and storage location.
private let whisperVariant = "openai_whisper-base"

/// We pin WhisperKit's storage to a folder we own so installs are deterministic
/// to find and remove (its default location varies across versions).
private func whisperDownloadBase() -> URL? {
    ModelCache.applicationSupport("VoiceType", "WhisperKit")
}

/// Process-wide cache of the loaded WhisperKit pipeline. Loading compiles the
/// CoreML model onto the Neural Engine, so we do it once and reuse it across the
/// per-dictation engine instances.
actor WhisperKitRuntime {
    static let shared = WhisperKitRuntime()
    private var pipe: WhisperKit?

    /// A loaded pipeline, loading already-downloaded weights from disk (no network).
    func loadedPipe() async throws -> WhisperKit {
        if let pipe { return pipe }
        let pipe = try await WhisperKit(
            WhisperKitConfig(model: whisperVariant, downloadBase: whisperDownloadBase(), download: false))
        self.pipe = pipe
        return pipe
    }

    /// Download the model (reporting progress) then load/compile it so it's warm —
    /// when this returns, the engine is genuinely ready to use.
    func download(progress: @escaping @Sendable (Double?) -> Void) async throws {
        _ = try await WhisperKit.download(
            variant: whisperVariant,
            downloadBase: whisperDownloadBase(),
            progressCallback: { progress($0.fractionCompleted) })
        pipe = try await WhisperKit(
            WhisperKitConfig(model: whisperVariant, downloadBase: whisperDownloadBase(), download: false))
    }

    func unload() { pipe = nil }
}

/// On-device transcription via OpenAI Whisper (base), run as CoreML on the Neural
/// Engine by WhisperKit. The small, fast, broadly-multilingual option.
final class WhisperKitEngine: TranscriptionEngine {
    let kind: TranscriptionEngineKind = .whisperKit

    func isAvailable() async -> Bool { WhisperKitModelManager().isInstalled() }

    // Qualified return type: WhisperKit also exports a `TranscriptionResult`.
    func transcribe(_ audio: PCMBuffer, locale: String) async throws -> VoiceTypeKit.TranscriptionResult {
        guard WhisperKitModelManager().isInstalled() else {
            throw TranscriptionError.unavailable(reason: "Download the Whisper Base model first.")
        }
        let start = Date()

        let pipe: WhisperKit
        do {
            pipe = try await WhisperKitRuntime.shared.loadedPipe()
        } catch {
            throw TranscriptionError.unavailable(reason: "Couldn't load Whisper Base: \(error.localizedDescription)")
        }

        let text: String
        do {
            // The array overload returns one result per decoded segment; join them.
            let results = try await pipe.transcribe(audioArray: AudioSamples.mono16k(audio))
            text = results.map(\.text).joined(separator: " ")
        } catch {
            throw TranscriptionError.failed("Whisper transcription failed: \(error.localizedDescription)")
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { throw TranscriptionError.noSpeechDetected }
        return VoiceTypeKit.TranscriptionResult(text: trimmed, locale: locale,
                                                processingTime: Date().timeIntervalSince(start))
    }
}

/// Manages the Whisper weights WhisperKit caches under our controlled folder.
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
        ModelCache.remove(at: whisperDownloadBase())
    }
}
