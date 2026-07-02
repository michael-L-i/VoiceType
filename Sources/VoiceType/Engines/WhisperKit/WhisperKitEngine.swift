import Foundation
import WhisperKit
import VoiceTypeKit

/// The Whisper variant we run: multilingual "base" — small (~150 MB) and fast.
/// Download and load must reference the same variant and storage location.
private let whisperVariant = "openai_whisper-base"

/// We pin WhisperKit's storage to a folder we own so installs are deterministic
/// to find and remove (its default location varies across versions).
private func whisperDownloadBase() -> URL? {
    ModelCache.applicationSupport("VoiceType", "WhisperKit")
}

/// The exact folder WhisperKit downloads the variant into, holding the CoreML
/// components (`AudioEncoder.mlmodelc`, `TextDecoder.mlmodelc`, `MelSpectrogram.mlmodelc`).
/// We pass this as `modelFolder` so WhisperKit loads from disk instead of leaving
/// the model folder unset (which throws "Model folder is not set").
private func whisperModelFolder() -> URL? {
    whisperDownloadBase()?.appendingPathComponent(
        "models/argmaxinc/whisperkit-coreml/\(whisperVariant)", isDirectory: true)
}

/// Process-wide cache of the loaded WhisperKit pipeline. Loading compiles the
/// CoreML model onto the Neural Engine, so we do it once and reuse it across the
/// per-dictation engine instances.
actor WhisperKitRuntime {
    static let shared = WhisperKitRuntime()
    private var pipe: WhisperKit?

    /// A loaded pipeline, loading the already-downloaded weights from our folder.
    func loadedPipe() async throws -> WhisperKit {
        if let pipe { return pipe }
        guard let folder = whisperModelFolder() else {
            throw TranscriptionError.unavailable(reason: "Couldn't locate the Whisper model folder.")
        }
        // Explicit modelFolder + load:true → WhisperKit loads from disk (no network).
        let config = WhisperKitConfig(
            model: whisperVariant,
            downloadBase: whisperDownloadBase(),
            modelFolder: folder.path,
            load: true)
        let pipe = try await WhisperKit(config)
        self.pipe = pipe
        return pipe
    }

    /// Download the model (reporting progress) then load/compile it so it's warm —
    /// when this returns, the engine is genuinely ready to use.
    func download(progress: @escaping @Sendable (Double?) -> Void) async throws {
        let folder = try await WhisperKit.download(
            variant: whisperVariant,
            downloadBase: whisperDownloadBase(),
            progressCallback: { progress($0.fractionCompleted) })
        let config = WhisperKitConfig(
            model: whisperVariant,
            downloadBase: whisperDownloadBase(),
            modelFolder: folder.path,
            load: true)
        pipe = try await WhisperKit(config)
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
            // Force the selected language rather than letting Whisper auto-detect:
            // with `usePrefillPrompt` on (the default) a set `language` pins the
            // decoder to it. Whisper keys on the ISO 639-1 code ("en", "es", ...).
            let options = DecodingOptions(language: LanguageTag.code(for: locale))
            // The array overload returns one result per decoded segment; join them.
            let results = try await pipe.transcribe(audioArray: AudioSamples.mono16k(audio),
                                                    decodeOptions: options)
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

    /// Real on-disk check: is the model folder present with the encoder bundle?
    func isInstalled() -> Bool {
        guard let folder = whisperModelFolder() else { return false }
        return FileManager.default.fileExists(
            atPath: folder.appendingPathComponent("AudioEncoder.mlmodelc").path)
    }

    func download(progress: @escaping @Sendable (Double?) -> Void) async throws {
        try await WhisperKitRuntime.shared.download(progress: progress)
    }

    func delete() async throws {
        await WhisperKitRuntime.shared.unload()
        ModelCache.remove(at: whisperDownloadBase())
    }
}
