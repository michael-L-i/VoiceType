import Foundation
import VoiceTypeKit

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Optional on-device natural-language usage summary via Apple Intelligence
/// (`FoundationModels`, macOS 26+). Mirrors `FoundationModelsCleanupEngine`'s
/// availability + session pattern.
///
/// Privacy: fed only the aggregate `UsageInsights` facts (counts, app names) —
/// never transcript text — and runs entirely on-device. Degrades silently: if
/// the model is unavailable or generation fails, the caller keeps the
/// deterministic insights and shows no error.
struct FoundationModelsSummaryEngine {
    enum SummaryError: Error {
        case unavailable(String)
        case failed(String)
    }

    func isAvailable() async -> Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available: return true
            case .unavailable: return false
            }
        }
        return false
        #else
        return false
        #endif
    }

    func summarize(_ insights: UsageInsights) async throws -> String {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            return try await Self.run(insights)
        }
        throw SummaryError.unavailable("FoundationModels requires macOS 26 or later.")
        #else
        throw SummaryError.unavailable("FoundationModels is not available in this build.")
        #endif
    }
}

#if canImport(FoundationModels)
@available(macOS 26.0, *)
extension FoundationModelsSummaryEngine {
    static func run(_ insights: UsageInsights) async throws -> String {
        switch SystemLanguageModel.default.availability {
        case .available: break
        case .unavailable: throw SummaryError.unavailable("The on-device model is unavailable.")
        }

        let session = LanguageModelSession(instructions: SummaryPrompt.instructions())
        // Slightly warmer than cleanup (0.2): this is friendly prose, not a
        // fidelity-critical transform.
        let options = GenerationOptions(temperature: 0.4)

        do {
            let response = try await session.respond(to: SummaryPrompt.prompt(for: insights),
                                                     options: options)
            let summary = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !summary.isEmpty else { throw SummaryError.failed("Model returned empty output.") }
            return summary
        } catch let error as SummaryError {
            throw error
        } catch {
            // Keep the error generic by type, never leaking the stats content.
            throw SummaryError.failed("FoundationModels generation failed: \(type(of: error)).")
        }
    }
}
#endif
