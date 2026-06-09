import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Engine resolver — privacy & fallback policy")
struct ResolverTests {
    @Test("never uses cloud transcription without consent")
    func cloudGated() {
        let resolved = EngineResolver.resolveTranscription(
            preferred: .groqCloud, cloudEnabled: false,
            available: [.appleOnDevice, .whisperCpp, .groqCloud])
        #expect(resolved != .groqCloud)
        #expect(resolved == .appleOnDevice)
    }

    @Test("uses cloud transcription when consented and preferred")
    func cloudAllowed() {
        let resolved = EngineResolver.resolveTranscription(
            preferred: .groqCloud, cloudEnabled: true,
            available: [.appleOnDevice, .groqCloud])
        #expect(resolved == .groqCloud)
    }

    @Test("downgrades apple -> whisper when apple unavailable")
    func downgradeToWhisper() {
        let resolved = EngineResolver.resolveTranscription(
            preferred: .appleOnDevice, cloudEnabled: false,
            available: [.whisperCpp])
        #expect(resolved == .whisperCpp)
    }

    @Test("cleanup falls back to rule-based when foundation models absent")
    func cleanupFallback() {
        let resolved = EngineResolver.resolveCleanup(
            preferred: .foundationModels, cloudEnabled: false, available: [])
        #expect(resolved == .ruleBased)
    }

    @Test("cloud cleanup gated by consent")
    func cleanupCloudGated() {
        let resolved = EngineResolver.resolveCleanup(
            preferred: .groqCloud, cloudEnabled: false, available: [.foundationModels])
        #expect(resolved == .foundationModels)
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
    func cleanup(_ text: String, options: CleanupOptions) async throws -> String {
        throw CleanupError.failed("stub")
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

    @Test("cleanup failure degrades to raw text, not an error")
    func cleanupDegrades() async throws {
        let pipe = DictationPipeline(
            transcriber: StubTranscriber(kind: .appleOnDevice, text: "hello world"),
            cleaner: FailingCleaner())
        let result = try await pipe.run(audio, options: .default)
        #expect(result.finalText == "hello world")
        #expect(result.cleanupEngine == .none)
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
