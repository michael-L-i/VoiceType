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

    /// Each downloadable model paired with where its weights actually live on
    /// disk. Downloads span two SDK caches — FluidAudio (the NVIDIA models) and
    /// our own WhisperKit cache — so there is no single canonical folder. Only
    /// models that are currently installed are returned.
    static func installedModelDirs() -> [(name: String, url: URL)] {
        let candidates: [(String, URL?)] = [
            ("Parakeet TDT 0.6B V3", applicationSupport("FluidAudio", "Models", "parakeet-tdt-0.6b-v3")),
            ("Nemotron 3.5 ASR 0.6B", applicationSupport("FluidAudio", "Models", "nemotron-multilingual")),
            ("Whisper Base", applicationSupport("VoiceType", "WhisperKit", "models", "argmaxinc", "whisperkit-coreml", "openai_whisper-base")),
        ]
        return candidates.compactMap { name, url in
            guard let url, FileManager.default.fileExists(atPath: url.path) else { return nil }
            return (name, url)
        }
    }

    /// A single folder the user can open to see everything they've downloaded.
    /// The real weights sit in separate per-SDK caches we can't merge without
    /// forcing a re-download, so we assemble one tidy folder of symlinks — one
    /// per installed model, named for the model — and return it. Rebuilt on every
    /// call so a deleted model never leaves a dangling link. Returns nil when
    /// nothing is downloaded yet.
    static func aggregatedModelsFolder() -> URL? {
        let installed = installedModelDirs()
        guard !installed.isEmpty,
              let root = applicationSupport("VoiceType", "Downloaded Models") else { return nil }
        let fm = FileManager.default
        try? fm.removeItem(at: root)
        guard (try? fm.createDirectory(at: root, withIntermediateDirectories: true)) != nil else { return nil }
        for (name, target) in installed {
            try? fm.createSymbolicLink(at: root.appendingPathComponent(name), withDestinationURL: target)
        }
        return root
    }
}
