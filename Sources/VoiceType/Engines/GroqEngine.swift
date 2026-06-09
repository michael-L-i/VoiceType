import Foundation
import VoiceTypeKit

/// STUB — replaced by the Groq cloud milestone (task #4).
///
/// Contract to honor when implementing:
///   • Transcription: POST the audio to Groq's audio transcriptions endpoint
///     (whisper-large-v3-turbo). Encode `PCMBuffer` as 16 kHz mono WAV in-memory.
///   • Cleanup: chat-completions call that ONLY tidies delivery, never rewrites.
///   • `isAvailable()` → true when an API key is present (network checked lazily).
///   • These run only when the user has enabled cloud (consent enforced upstream).
struct GroqTranscriptionEngine: TranscriptionEngine {
    let kind: TranscriptionEngineKind = .groqCloud
    let apiKey: String

    func isAvailable() async -> Bool { false }

    func transcribe(_ audio: PCMBuffer, locale: String) async throws -> TranscriptionResult {
        throw TranscriptionError.unavailable(reason: "Groq engine not yet implemented.")
    }
}

struct GroqCleanupEngine: CleanupEngine {
    let kind: CleanupEngineKind = .groqCloud
    let apiKey: String

    func isAvailable() async -> Bool { false }

    func cleanup(_ text: String, options: CleanupOptions) async throws -> String {
        throw CleanupError.unavailable(reason: "Groq cleanup not yet implemented.")
    }
}
