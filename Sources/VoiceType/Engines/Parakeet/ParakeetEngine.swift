import Foundation
import FluidAudio
import VoiceTypeKit

/// The Parakeet variant we run: TDT 0.6B **V3** — the multilingual FastConformer
/// model. One place so download and load always agree.
private let parakeetVersion: AsrModelVersion = .v3

/// Process-wide cache of the loaded Parakeet model. A fresh `TranscriptionEngine`
/// is created per dictation, but loading hundreds of MB of CoreML weights is
/// expensive, so the actual model lives here and loads once on first use.
actor ParakeetRuntime {
    static let shared = ParakeetRuntime()
    private var manager: AsrManager?
    /// The warm-up in flight, if any. Transcription waits for it rather than
    /// running alongside: FluidAudio suspends between model stages, so two
    /// calls on one manager would interleave.
    private var warmup: Task<Void, Never>?

    /// A loaded manager, ready to transcribe.
    func loadedManager() async throws -> AsrManager {
        await warmup?.value
        return try await load()
    }

    /// Load the model and run it once on a second of silence.
    ///
    /// Loading is not the whole cost. CoreML compiles the model for the Neural
    /// Engine and caches the result per macOS build, and it can need to
    /// recompile even in a long-running process: measured at ~11 s for a
    /// fresh compile, and seen in the field as 12–22 s stalls on the first
    /// dictation after a long idle. Running the model is what triggers the
    /// compile, so it is the warm-up; when nothing needs compiling it costs
    /// ~50 ms.
    func prewarm() async {
        if let warmup { return await warmup.value }
        let task = Task {
            let start = Date()
            do {
                let manager = try await self.load()
                var state = try TdtDecoderState()
                _ = try await manager.transcribe([Float](repeating: 0, count: 16_000),
                                                 decoderState: &state)
                Log.engine.info("parakeet warm in \(Int(Date().timeIntervalSince(start) * 1000), privacy: .public)ms")
            } catch {
                Log.engine.error("parakeet warm-up failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        warmup = task
        await task.value
        warmup = nil
    }

    /// Load from the on-disk cache if needed. Forces offline mode so the
    /// transcribe path can never trigger a surprise download; throws if the
    /// weights aren't present (caller gates on `modelsExist`).
    private func load() async throws -> AsrManager {
        if let manager { return manager }
        ModelHub.offlineMode = true
        defer { ModelHub.offlineMode = false }
        let models = try await AsrModels.loadFromCache(version: parakeetVersion)
        let manager = AsrManager(config: .default)
        try await manager.loadModels(models)
        self.manager = manager
        return manager
    }

    /// Download (if needed) and load the model, reporting download progress.
    func download(progress: @escaping @Sendable (Double?) -> Void) async throws {
        ModelHub.offlineMode = false
        let models = try await AsrModels.downloadAndLoad(
            version: parakeetVersion,
            progressHandler: { progress($0.fractionCompleted) })
        let manager = AsrManager(config: .default)
        try await manager.loadModels(models)
        self.manager = manager
    }

    func unload() { manager = nil }
}

/// On-device transcription via NVIDIA Parakeet TDT 0.6B V3, run as CoreML on the
/// Neural Engine by FluidAudio. The model emits punctuation and capitalization
/// itself — no LLM post-processing is needed for readable text.
final class ParakeetEngine: TranscriptionEngine {
    let kind: TranscriptionEngineKind = .parakeet

    func isAvailable() async -> Bool { ParakeetModelManager().isInstalled() }

    func prewarm() async {
        guard ParakeetModelManager().isInstalled() else { return }
        await ParakeetRuntime.shared.prewarm()
    }

    func transcribe(_ audio: PCMBuffer, locale: String) async throws -> TranscriptionResult {
        guard ParakeetModelManager().isInstalled() else {
            throw TranscriptionError.unavailable(reason: "Download the Parakeet model first.")
        }
        let start = Date()

        let manager: AsrManager
        do {
            manager = try await ParakeetRuntime.shared.loadedManager()
        } catch {
            throw TranscriptionError.unavailable(reason: "Couldn't load the Parakeet model: \(error.localizedDescription)")
        }

        let text: String
        do {
            var state = try TdtDecoderState()
            // Pass the selected language as a hint: on the multilingual V3 model it
            // biases token selection toward that language's script. Codes V3 doesn't
            // model (e.g. "ja") map to nil, leaving the model to decide on its own.
            let language = Language(rawValue: LanguageTag.code(for: locale))
            let result = try await manager.transcribe(AudioSamples.mono16k(audio),
                                                      decoderState: &state, language: language)
            text = result.text
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

    /// Real on-disk check: are the required v3 model files present?
    func isInstalled() -> Bool {
        AsrModels.modelsExist(at: AsrModels.defaultCacheDirectory(for: parakeetVersion),
                              version: parakeetVersion)
    }

    func download(progress: @escaping @Sendable (Double?) -> Void) async throws {
        try await ParakeetRuntime.shared.download(progress: progress)
    }

    func delete() async throws {
        await ParakeetRuntime.shared.unload()
        // FluidAudio caches under Application Support/FluidAudio/Models.
        ModelCache.remove(at: ModelCache.applicationSupport("FluidAudio", "Models"))
    }
}
