import Foundation
import VoiceTypeKit

#if canImport(FoundationModels)
import FoundationModels
#endif

/// On-device cleanup via Apple Intelligence (`FoundationModels`, macOS 26+).
///
/// Runs the system language model entirely on-device to tidy a raw transcript's
/// *delivery* — punctuation, capitalization, filler removal — without ever
/// changing the speaker's words. Nothing leaves the machine.
///
/// Degrades gracefully: if the framework is unavailable, Apple Intelligence is
/// off, or generation fails for any reason, `cleanup` throws a `CleanupError`
/// and the pipeline falls back to `RuleBasedCleanup`. We never return model
/// output we can't trust, and we never log transcript content.
struct FoundationModelsCleanupEngine: CleanupEngine {
    let kind: CleanupEngineKind = .foundationModels

    func isAvailable() async -> Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            return Self.modelIsAvailable()
        }
        return false
        #else
        return false
        #endif
    }

    func cleanup(_ text: String, options: CleanupOptions) async throws -> String {
        // Empty/whitespace-only input has nothing to clean; short-circuit so we
        // never spin up the model for it.
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            return try await Self.run(trimmed, options: options)
        }
        throw CleanupError.unavailable(reason: "FoundationModels requires macOS 26 or later.")
        #else
        throw CleanupError.unavailable(reason: "FoundationModels is not available in this build.")
        #endif
    }
}

#if canImport(FoundationModels)
@available(macOS 26.0, *)
extension FoundationModelsCleanupEngine {

    /// True only when the on-device model reports `.available`. Anything else
    /// (device ineligible, Apple Intelligence not enabled, model still
    /// downloading) counts as unavailable.
    static func modelIsAvailable() -> Bool {
        switch SystemLanguageModel.default.availability {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }

    /// Run one batch cleanup request and return the corrected text.
    static func run(_ text: String, options: CleanupOptions) async throws -> String {
        // Re-check availability rather than assume the caller did: the model can
        // go unavailable between selection and use.
        switch SystemLanguageModel.default.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw CleanupError.unavailable(reason: describe(reason))
        }

        let session = LanguageModelSession(
            instructions: CleanupPrompt.instructions(for: options)
        )

        // Low temperature keeps the model faithful to the input (we want a tidy,
        // not a creative, rewrite). Batch response — no streaming needed since
        // the pipeline injects the text only once it's complete.
        let generationOptions = GenerationOptions(temperature: 0.2)

        do {
            let response = try await session.respond(
                to: CleanupPrompt.prompt(for: text),
                options: generationOptions
            )
            let raw = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            // Deterministic safety net: strip any "Sure, here's the transcript:"
            // lead-in or wrapping quotes the model added despite the instructions.
            let cleaned = CleanupSanitizer.strip(raw)
            // A blank result means the model declined or produced nothing usable;
            // treat as failure so the pipeline falls back rather than emitting "".
            guard !cleaned.isEmpty else {
                throw CleanupError.failed("Model returned empty output.")
            }
            return cleaned
        } catch let error as CleanupError {
            throw error
        } catch {
            // Surface a stable error without leaking the transcript. The model's
            // own error descriptions can include guardrail/context detail but not
            // the user's words; still, we keep it generic by type, not content.
            throw CleanupError.failed("FoundationModels generation failed: \(type(of: error)).")
        }
    }

    private static func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "This device does not support Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is not enabled in System Settings."
        case .modelNotReady:
            return "The on-device model is still downloading or not ready."
        @unknown default:
            return "The on-device model is unavailable."
        }
    }
}
#endif
