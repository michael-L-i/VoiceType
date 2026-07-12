import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Engine resolver — on-device fallback policy")
struct ResolverTests {
    /// No language metadata: every engine is assumed compatible, which is the
    /// pre-matrix behavior all the availability tests below exercise.
    let anyLanguage = EngineLanguageSupport()

    @Test("uses the preferred transcription engine when available")
    func transcriptionPreferred() {
        let resolved = EngineResolver.resolveTranscription(
            preferred: .appleOnDevice, available: [.appleOnDevice],
            locale: "en-US", support: anyLanguage)
        #expect(resolved == .appleOnDevice)
    }

    @Test("returns the preferred kind even when nothing is available, so the caller can error")
    func transcriptionNoneAvailable() {
        let resolved = EngineResolver.resolveTranscription(
            preferred: .appleOnDevice, available: [],
            locale: "en-US", support: anyLanguage)
        #expect(resolved == .appleOnDevice)
    }

    @Test("uses a downloaded engine (Parakeet) when it's the preference and available")
    func transcriptionDownloadedPreferred() {
        let resolved = EngineResolver.resolveTranscription(
            preferred: .parakeet, available: [.appleOnDevice, .parakeet],
            locale: "en-US", support: anyLanguage)
        #expect(resolved == .parakeet)
    }

    @Test("falls back to an available engine when the preferred model isn't downloaded")
    func transcriptionPreferredNotDownloaded() {
        let resolved = EngineResolver.resolveTranscription(
            preferred: .parakeet, available: [.appleOnDevice],
            locale: "en-US", support: anyLanguage)
        #expect(resolved == .appleOnDevice)
    }

    @Test("cleanup uses Apple Intelligence when available")
    func cleanupPreferred() {
        let resolved = EngineResolver.resolveCleanup(
            preferred: .foundationModels, available: [.foundationModels])
        #expect(resolved == .foundationModels)
    }

    @Test("cleanup falls back to rule-based when foundation models absent")
    func cleanupFallback() {
        let resolved = EngineResolver.resolveCleanup(
            preferred: .foundationModels, available: [])
        #expect(resolved == .ruleBased)
    }

    @Test("cleanup honors an explicit none selection")
    func cleanupNone() {
        let resolved = EngineResolver.resolveCleanup(
            preferred: .none, available: [.foundationModels])
        #expect(resolved == .none)
    }
}

@Suite("Engine resolver — language compatibility")
struct ResolverLanguageTests {
    /// The real static model facts plus a typical Apple locale set.
    let support = EngineLanguageSupport(codes: [
        .appleOnDevice: ["en", "es", "fr", "de", "it", "pt", "ja", "zh", "ko"],
        .parakeet: EngineLanguages.staticCodes(for: .parakeet)!,
        .whisperKit: EngineLanguages.staticCodes(for: .whisperKit)!,
        .nemotron: EngineLanguages.staticCodes(for: .nemotron)!,
    ])

    @Test("keeps the preferred engine when it supports the language")
    func preferredCompatible() {
        let resolved = EngineResolver.resolveTranscription(
            preferred: .parakeet, available: [.appleOnDevice, .parakeet],
            locale: "de-DE", support: support)
        #expect(resolved == .parakeet)
    }

    @Test("falls back for Chinese when Parakeet is preferred — Parakeet is European-only")
    func chineseFallsBackFromParakeet() {
        let resolved = EngineResolver.resolveTranscription(
            preferred: .parakeet, available: [.appleOnDevice, .parakeet],
            locale: "zh-CN", support: support)
        #expect(resolved == .appleOnDevice)
    }

    @Test("prefers a language-compatible downloaded engine over an incompatible preference")
    func compatibleDownloadedBeatsIncompatiblePreference() {
        let resolved = EngineResolver.resolveTranscription(
            preferred: .parakeet, available: [.parakeet, .whisperKit],
            locale: "ja-JP", support: support)
        #expect(resolved == .whisperKit)
    }

    @Test("sticks with the preferred engine when nothing available supports the language")
    func nothingCompatibleKeepsPreference() {
        let resolved = EngineResolver.resolveTranscription(
            preferred: .parakeet, available: [.parakeet],
            locale: "ja-JP", support: support)
        #expect(resolved == .parakeet)
    }

    @Test("missing metadata means assume-supported")
    func missingMetadataAssumesYes() {
        let empty = EngineLanguageSupport()
        #expect(empty.supports(.parakeet, locale: "zh-CN"))
    }

    @Test("support lookup compares primary subtags, not raw locale identifiers")
    func primarySubtagComparison() {
        #expect(support.supports(.nemotron, locale: "zh-Hans-CN"))
        #expect(support.supports(.nemotron, locale: "zh_CN"))
        #expect(!support.supports(.parakeet, locale: "zh-CN"))
    }

    @Test("Nemotron matrix includes Chinese but excludes adaptation-only tier-3 languages")
    func nemotronTiers() {
        #expect(support.supports(.nemotron, locale: "zh-CN"))
        #expect(!support.supports(.nemotron, locale: "th-TH"))
        #expect(!support.supports(.nemotron, locale: "he-IL"))
    }

    @Test("every picker language is transcribable by at least one engine")
    func pickerLanguagesCovered() {
        for language in DictationLanguage.all {
            let covered = TranscriptionEngineKind.allCases.contains {
                support.supports($0, locale: language.code)
            }
            #expect(covered, "\(language.code) has no engine")
        }
    }
}

// MARK: - Pipeline with stub engines

private struct StubTranscriber: TranscriptionEngine {
    let kind: TranscriptionEngineKind
    let text: String
    var fail = false
    func isAvailable() async -> Bool { true }
    func transcribe(_ audio: PCMBuffer, locale: String) async throws -> TranscriptionResult {
        if fail { throw TranscriptionError.failed("stub") }
        return TranscriptionResult(text: text, locale: locale)
    }
}

private struct FailingCleaner: CleanupEngine {
    let kind: CleanupEngineKind = .foundationModels
    func isAvailable() async -> Bool { true }
    func cleanup(_ text: String, options: CleanupOptions, context: CleanupContext, locale: String) async throws -> String {
        throw CleanupError.failed("stub")
    }
}

/// Records the context it was handed so tests can assert threading.
private final class RecordingCleaner: CleanupEngine, @unchecked Sendable {
    let kind: CleanupEngineKind = .foundationModels
    var seenContext: CleanupContext?
    func isAvailable() async -> Bool { true }
    func cleanup(_ text: String, options: CleanupOptions, context: CleanupContext, locale: String) async throws -> String {
        seenContext = context
        return text
    }
}

@Suite("Dictation pipeline")
struct PipelineTests {
    let audio = PCMBuffer(samples: Array(repeating: 0.1, count: 16_000), sampleRate: 16_000)

    @Test("transcribe + cleanup produces final text")
    func happyPath() async throws {
        let pipe = DictationPipeline(
            transcriber: StubTranscriber(kind: .appleOnDevice, text: "um hello world"),
            cleaner: RuleBasedCleanup())
        let result = try await pipe.run(audio, options: .default)
        #expect(result.rawText == "um hello world")
        #expect(result.finalText.hasPrefix("Hello"))
        #expect(result.cleanupEngine == .ruleBased)
    }

    @Test("cleanup failure degrades to the rule-based floor, not an error")
    func cleanupDegrades() async throws {
        let pipe = DictationPipeline(
            transcriber: StubTranscriber(kind: .appleOnDevice, text: "um hello world"),
            cleaner: FailingCleaner())
        let result = try await pipe.run(audio, options: .default)
        #expect(result.finalText == "Hello world.")
        #expect(result.cleanupEngine == .ruleBased)
    }

    @Test("app context reaches the cleanup engine")
    func contextThreading() async throws {
        let cleaner = RecordingCleaner()
        let pipe = DictationPipeline(
            transcriber: StubTranscriber(kind: .appleOnDevice, text: "git status"),
            cleaner: cleaner)
        let context = CleanupContext(appBundleID: "com.apple.Terminal",
                                     appName: "Terminal", category: .terminal)
        _ = try await pipe.run(audio, options: .default, context: context)
        #expect(cleaner.seenContext == context)
    }

    @Test("empty transcript is not an error")
    func emptyTranscript() async throws {
        let pipe = DictationPipeline(
            transcriber: StubTranscriber(kind: .appleOnDevice, text: "   "),
            cleaner: RuleBasedCleanup())
        let result = try await pipe.run(audio, options: .default)
        #expect(result.finalText.isEmpty)
    }

    @Test("records latency metrics")
    func metrics() async throws {
        let pipe = DictationPipeline(
            transcriber: StubTranscriber(kind: .appleOnDevice, text: "hello"),
            cleaner: RuleBasedCleanup())
        let result = try await pipe.run(audio, options: .default)
        #expect(result.metrics.audioDuration == 1.0)
        #expect(result.metrics.timeToText >= 0)
    }
}

@Suite("Dictation history")
struct HistoryTests {
    @Test("keeps newest first and respects the cap")
    func capAndOrder() {
        var h = DictationHistory(limit: 2)
        for i in 0..<3 {
            h.add(DictationRecord(date: Date(timeIntervalSinceReferenceDate: Double(i)),
                                  text: "t\(i)", transcriptionEngine: .appleOnDevice,
                                  cleanupEngine: .ruleBased, timeToText: 0))
        }
        #expect(h.records.count == 2)
        #expect(h.records.first?.text == "t2")
    }
}
