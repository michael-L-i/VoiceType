import Foundation
import FluidAudio
import VoiceTypeKit

/// Process-wide cache of the loaded Parakeet model. A fresh `TranscriptionEngine`
/// is created per dictation, but loading hundreds of MB of CoreML weights is
/// expensive, so the actual model lives here and loads once on first use.
actor ParakeetRuntime {
    static let shared = ParakeetRuntime()
    private var manager: UnifiedAsrManager?

    /// A loaded manager, loading from the on-disk cache if needed. Forces offline
    /// mode so the transcribe path can never trigger a surprise download; throws
    /// if the weights aren't present (caller should gate on the install marker).
    func loadedManager() async throws -> UnifiedAsrManager {
        if let manager { return manager }
        let manager = UnifiedAsrManager()
        DownloadUtils.enforceOffline = true
        defer { DownloadUtils.enforceOffline = false }
        try await manager.loadModels()
        self.manager = manager
        return manager
    }

    /// Download (if needed) and load the model, reporting download progress.
    func download(progress: @escaping @Sendable (Double?) -> Void) async throws {
        let manager = UnifiedAsrManager()
        DownloadUtils.enforceOffline = false
        try await manager.loadModels(progressHandler: { progress($0.fractionCompleted) })
        self.manager = manager
    }

    func unload() { manager = nil }
}

/// On-device transcription via NVIDIA Parakeet, run as CoreML on the Neural
/// Engine by FluidAudio. The model emits punctuation and capitalization itself —
/// no LLM post-processing is needed for readable text.
final class ParakeetEngine: TranscriptionEngine {
    let kind: TranscriptionEngineKind = .parakeet

    func isAvailable() async -> Bool { ParakeetModelManager().isInstalled() }

    func transcribe(_ audio: PCMBuffer, locale: String) async throws -> TranscriptionResult {
        guard ParakeetModelManager().isInstalled() else {
            throw TranscriptionError.unavailable(reason: "Download the Parakeet model in Settings before using it.")
        }
        let start = Date()

        let manager: UnifiedAsrManager
        do {
            manager = try await ParakeetRuntime.shared.loadedManager()
        } catch {
            throw TranscriptionError.unavailable(reason: "Couldn't load the Parakeet model: \(error.localizedDescription)")
        }

        let text: String
        do {
            text = try await manager.transcribe(AudioSamples.mono16k(audio))
        } catch {
            throw TranscriptionError.failed("Parakeet transcription failed: \(error.localizedDescription)")
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { throw TranscriptionError.noSpeechDetected }
        return TranscriptionResult(text: trimmed, locale: locale,
                                   processingTime: Date().timeIntervalSince(start))
    }
}

/// Manages the Parakeet weights FluidAudio caches under Application Support.
struct ParakeetModelManager: TranscriptionModelManager {
    let kind: TranscriptionEngineKind = .parakeet

    func isInstalled() -> Bool { ModelInstallMarker.isInstalled(.parakeet) }

    func download(progress: @escaping @Sendable (Double?) -> Void) async throws {
        try await ParakeetRuntime.shared.download(progress: progress)
        ModelInstallMarker.set(true, for: .parakeet)
    }

    func delete() async throws {
        ModelInstallMarker.set(false, for: .parakeet)
        await ParakeetRuntime.shared.unload()
        // FluidAudio caches under Application Support/FluidAudio/Models.
        ModelCache.remove(at: ModelCache.applicationSupport("FluidAudio", "Models"))
    }
}
