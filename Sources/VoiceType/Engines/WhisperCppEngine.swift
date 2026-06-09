import Foundation
import SwiftWhisper
import VoiceTypeKit

/// Fully-local transcription via whisper.cpp (through the `SwiftWhisper`
/// binding). This is the privacy fallback: it runs entirely on-device on any
/// hardware/locale, so audio never leaves the machine.
///
/// The contract is batch (one utterance in, text out): the pipeline calls this
/// once, after the push-to-talk key is released, with the full captured buffer.
/// `SwiftWhisper.transcribe(audioFrames:)` takes exactly our currency — mono
/// 16 kHz `Float` samples — so the bridge is a direct hand-off, no resampling.
final class WhisperCppEngine: TranscriptionEngine {
    let kind: TranscriptionEngineKind = .whisperCpp

    private let models: WhisperModelManager

    init(models: WhisperModelManager = WhisperModelManager()) {
        self.models = models
    }

    /// Available only once the ggml weights are on disk. Until then the resolver
    /// downgrades to another engine rather than failing a dictation — the user
    /// downloads the model from Settings first.
    func isAvailable() async -> Bool {
        models.isModelDownloaded()
    }

    func transcribe(_ audio: PCMBuffer, locale localeID: String) async throws -> TranscriptionResult {
        let start = Date()

        guard models.isModelDownloaded(), let modelURL = try? models.modelURL() else {
            throw TranscriptionError.unavailable(reason: "Whisper model not downloaded yet.")
        }
        guard !audio.isEmpty else { throw TranscriptionError.noSpeechDetected }

        // whisper.cpp expects mono 16 kHz float frames, which is precisely the
        // shape of `PCMBuffer` the capture layer hands us. Map the requested
        // BCP-47 locale to whisper's language, falling back to auto-detection.
        let params = WhisperParams(strategy: .greedy)
        params.language = Self.whisperLanguage(for: localeID)
        let whisper = Whisper(fromFileURL: modelURL, withParams: params)

        let segments: [Segment]
        do {
            segments = try await whisper.transcribe(audioFrames: audio.samples)
        } catch {
            throw TranscriptionError.failed("Whisper transcription failed: \(error.localizedDescription)")
        }

        let text = segments
            .map(\.text)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { throw TranscriptionError.noSpeechDetected }

        return TranscriptionResult(text: text, locale: localeID,
                                   processingTime: Date().timeIntervalSince(start))
    }

    /// Map a BCP-47 locale ("en-US") to whisper's language code, defaulting to
    /// auto-detection when we can't resolve it.
    private static func whisperLanguage(for localeID: String) -> WhisperLanguage {
        guard let code = Locale(identifier: localeID).language.languageCode?.identifier,
              let lang = WhisperLanguage(rawValue: code) else {
            return .auto
        }
        return lang
    }
}
