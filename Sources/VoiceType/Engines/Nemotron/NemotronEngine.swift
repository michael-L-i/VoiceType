import Foundation
import FluidAudio
import VoiceTypeKit

/// Cache/variant coordinates for NVIDIA's Nemotron 3.5 ASR streaming model. We
/// run the full-vocab **multilingual** ship (covers every language the picker
/// offers) at the recommended 2240 ms chunk tier. One place so download, load,
/// and the on-disk check always agree.
private enum NemotronVariant {
    /// "auto" resolves to the multilingual ship inside FluidAudio.
    static let languageCode = "auto"
    static let chunkMs = 2240

    /// The `<repo>/<language>/<chunkMs>ms` directory FluidAudio downloads this
    /// variant into, mirroring `downloadVariant`'s own path arithmetic.
    static func variantDirectory() -> URL? {
        guard let models = ModelCache.applicationSupport("FluidAudio", "Models") else { return nil }
        let langDir = StreamingNemotronMultilingualAsrManager.languageDirectory(for: languageCode)
        return repoDirectory(under: models)?
            .appendingPathComponent("\(langDir)/\(chunkMs)ms", isDirectory: true)
    }

    /// The Nemotron repo's own cache folder — used to scope deletion so removing
    /// this model never touches Parakeet's weights (both live under FluidAudio).
    static func repoDirectory(under models: URL) -> URL? {
        models.appendingPathComponent(Repo.nemotronMultilingual.folderName, isDirectory: true)
    }
}

/// Process-wide cache of the loaded Nemotron model. A fresh `TranscriptionEngine`
/// is created per dictation, but loading ~1.5 GB of CoreML weights is expensive,
/// so the actual manager lives here and loads once on first use. The manager is
/// stateful (streaming), so `transcribe` resets it before each utterance.
actor NemotronRuntime {
    static let shared = NemotronRuntime()
    private var manager: StreamingNemotronMultilingualAsrManager?

    /// A loaded manager, loading from the on-disk cache if needed. Throws if the
    /// weights aren't present (caller gates on `isInstalled`).
    func loadedManager() async throws -> StreamingNemotronMultilingualAsrManager {
        if let manager { return manager }
        guard let dir = NemotronVariant.variantDirectory() else {
            throw TranscriptionError.unavailable(reason: "Couldn't locate the Nemotron model folder.")
        }
        let bundle = try await StreamingNemotronMultilingualAsrManager.preloadShared(from: dir)
        let mgr = StreamingNemotronMultilingualAsrManager()
        try await mgr.loadFromShared(bundle)
        self.manager = mgr
        return mgr
    }

    /// Download (if needed) and load the model, reporting download progress.
    func download(progress: @escaping @Sendable (Double?) -> Void) async throws {
        let bundle = try await StreamingNemotronMultilingualAsrManager.downloadAndPreloadShared(
            languageCode: NemotronVariant.languageCode,
            chunkMs: NemotronVariant.chunkMs,
            progressHandler: { progress($0.fractionCompleted) })
        let mgr = StreamingNemotronMultilingualAsrManager()
        try await mgr.loadFromShared(bundle)
        self.manager = mgr
    }

    func unload() async {
        if let manager { await manager.cleanup() }
        manager = nil
    }
}

/// On-device transcription via NVIDIA Nemotron 3.5 ASR streaming 0.6B, run as
/// CoreML on the Neural Engine by FluidAudio. A cache-aware FastConformer-RNNT
/// covering 100+ languages, with an explicit per-language prompt we set from the
/// chosen locale. We drive its streaming API in one shot (process → finish) to
/// fit the push-to-talk pipeline.
final class NemotronEngine: TranscriptionEngine {
    let kind: TranscriptionEngineKind = .nemotron

    func isAvailable() async -> Bool { NemotronModelManager().isInstalled() }

    func transcribe(_ audio: PCMBuffer, locale: String) async throws -> TranscriptionResult {
        guard NemotronModelManager().isInstalled() else {
            throw TranscriptionError.unavailable(reason: "Download the Nemotron model first.")
        }
        let start = Date()

        let manager: StreamingNemotronMultilingualAsrManager
        do {
            manager = try await NemotronRuntime.shared.loadedManager()
        } catch {
            throw TranscriptionError.unavailable(reason: "Couldn't load the Nemotron model: \(error.localizedDescription)")
        }

        let samples = AudioSamples.mono16k(audio)
        let text: String
        do {
            // The manager is stateful and reused across dictations: clear any
            // prior audio/decoder state, set the language prompt for this
            // utterance, then feed the whole buffer and flush the tail.
            await manager.reset()
            await manager.setLanguage(locale)
            _ = try await manager.process(samples: samples)
            var out = try await manager.finish()

            // Nemotron's per-language prompt is a hard *script* filter: fed speech
            // that doesn't match the selected language (e.g. English with a
            // Chinese prompt), it emits nothing at all. Rather than report "didn't
            // catch that", retry once letting the model auto-detect the language.
            if out.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await manager.reset()
                await manager.setLanguage("auto")
                _ = try await manager.process(samples: samples)
                out = try await manager.finish()
            }
            text = out
        } catch {
            throw TranscriptionError.failed("Nemotron transcription failed: \(error.localizedDescription)")
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { throw TranscriptionError.noSpeechDetected }
        return TranscriptionResult(text: trimmed, locale: locale,
                                   processingTime: Date().timeIntervalSince(start))
    }
}

/// Manages the Nemotron weights FluidAudio caches under Application Support.
struct NemotronModelManager: TranscriptionModelManager {
    let kind: TranscriptionEngineKind = .nemotron

    /// Real on-disk check: is the variant's `metadata.json` present? FluidAudio
    /// writes it last-ish and refuses to load without it, so it's a good sentinel.
    func isInstalled() -> Bool {
        guard let dir = NemotronVariant.variantDirectory() else { return false }
        let metadata = dir.appendingPathComponent(ModelNames.NemotronMultilingualStreaming.metadata)
        return FileManager.default.fileExists(atPath: metadata.path)
    }

    func download(progress: @escaping @Sendable (Double?) -> Void) async throws {
        try await NemotronRuntime.shared.download(progress: progress)
    }

    func delete() async throws {
        await NemotronRuntime.shared.unload()
        // Scope removal to the Nemotron repo folder — Parakeet lives alongside it
        // under FluidAudio/Models and must survive.
        guard let models = ModelCache.applicationSupport("FluidAudio", "Models") else { return }
        ModelCache.remove(at: NemotronVariant.repoDirectory(under: models))
    }
}
