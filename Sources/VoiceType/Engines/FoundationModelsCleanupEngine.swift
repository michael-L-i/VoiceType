import Foundation
import VoiceTypeKit

/// STUB — replaced by the FoundationModels milestone (task #5).
///
/// Contract to honor when implementing:
///   • Use Apple's on-device `FoundationModels` `LanguageModelSession` to tidy
///     punctuation/casing/fillers WITHOUT changing the speaker's words.
///   • `isAvailable()` → reflect `SystemLanguageModel.default.availability`.
///   • On any failure, throw so the pipeline degrades to rule-based cleanup.
struct FoundationModelsCleanupEngine: CleanupEngine {
    let kind: CleanupEngineKind = .foundationModels

    func isAvailable() async -> Bool { false }

    func cleanup(_ text: String, options: CleanupOptions) async throws -> String {
        throw CleanupError.unavailable(reason: "FoundationModels cleanup not yet implemented.")
    }
}
