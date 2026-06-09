import Foundation
import VoiceTypeKit

/// STUB — replaced by the whisper.cpp milestone (task #3).
///
/// Contract to honor when implementing:
///   • `isAvailable()` → true only once a model file is present on disk.
///   • `transcribe(_:locale:)` → run whisper.cpp on the mono 16 kHz `PCMBuffer`
///     and return the text. Throw `TranscriptionError.unavailable` if no model.
///   • Owns a model download/cache manager (models/ is gitignored).
/// Until then it reports unavailable so `EngineResolver` downgrades cleanly.
struct WhisperCppEngine: TranscriptionEngine {
    let kind: TranscriptionEngineKind = .whisperCpp

    func isAvailable() async -> Bool { false }

    func transcribe(_ audio: PCMBuffer, locale: String) async throws -> TranscriptionResult {
        throw TranscriptionError.unavailable(reason: "Whisper engine not yet installed.")
    }
}
