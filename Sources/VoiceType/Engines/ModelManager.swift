import Foundation
import VoiceTypeKit

/// Downloads, locates, and removes the on-disk weights a downloadable
/// transcription engine needs. Apple's engine is built into the OS and has no
/// manager (`EngineFactory.modelManager(for:)` returns nil for it). Concrete
/// implementations wrap each SDK's own download/cache machinery.
protocol TranscriptionModelManager: Sendable {
    var kind: TranscriptionEngineKind { get }

    /// Cheap check — are the weights present and ready to load? Must not touch
    /// the network or load the model.
    func isInstalled() -> Bool

    /// Fetch the weights (and warm the runtime). `progress` reports a 0...1
    /// fraction, or nil when the source can't report fine-grained progress.
    func download(progress: @escaping @Sendable (Double?) -> Void) async throws

    /// Remove the downloaded weights, freeing disk, and unload from memory.
    func delete() async throws
}

/// Best-effort removal of a cached model directory under Application Support. The
/// SDKs re-download on demand, so a failure here is non-fatal — we just log it.
enum ModelCache {
    static func applicationSupport(_ components: String...) -> URL? {
        guard let base = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: false) else { return nil }
        return components.reduce(base) { $0.appendingPathComponent($1, isDirectory: true) }
    }

    static func remove(at url: URL?) {
        guard let url, FileManager.default.fileExists(atPath: url.path) else { return }
        do { try FileManager.default.removeItem(at: url) }
        catch { Log.engine.error("model cache removal failed: \(error.localizedDescription, privacy: .public)") }
    }

    /// The on-disk model folders for the "reveal in Finder" affordance. Downloads
    /// span two SDK caches — FluidAudio (NVIDIA models) and our own WhisperKit
    /// cache — so there is no single canonical VoiceType models folder.
    static func modelLocations() -> [URL] {
        let exactLocations = [
            applicationSupport("FluidAudio", "Models", "parakeet-tdt-0.6b-v3"),
            applicationSupport("FluidAudio", "Models", "nemotron-multilingual"),
            applicationSupport("VoiceType", "WhisperKit", "models", "argmaxinc", "whisperkit-coreml", "openai_whisper-base")
        ]
            .compactMap { $0 }
            .filter { FileManager.default.fileExists(atPath: $0.path) }

        if !exactLocations.isEmpty { return exactLocations }

        return [
            applicationSupport("FluidAudio", "Models"),
            applicationSupport("VoiceType", "WhisperKit")
        ]
            .compactMap { $0 }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }
}
