import Foundation

/// High-level state of a single dictation, surfaced to the app UI (Home window + HUD).
public enum DictationState: Sendable, Equatable {
    case idle
    case recording
    case transcribing
    case cleaning
    case injecting
    case done
    case error(String)
}

/// Per-dictation latency breakdown. Latency is the product, so we measure it
/// explicitly and keep it on-device. Times are in seconds.
public struct LatencyMetrics: Sendable, Equatable {
    public var audioDuration: TimeInterval = 0
    public var transcription: TimeInterval = 0
    public var cleanup: TimeInterval = 0
    /// Time from end-of-speech (key release) to text ready for injection — the
    /// number the user actually feels.
    public var timeToText: TimeInterval = 0

    public init() {}
}

public struct PipelineResult: Sendable, Equatable {
    public var rawText: String
    public var cleanedText: String
    public var transcriptionEngine: TranscriptionEngineKind
    public var cleanupEngine: CleanupEngineKind
    public var metrics: LatencyMetrics

    public init(rawText: String, cleanedText: String,
                transcriptionEngine: TranscriptionEngineKind,
                cleanupEngine: CleanupEngineKind, metrics: LatencyMetrics) {
        self.rawText = rawText
        self.cleanedText = cleanedText
        self.transcriptionEngine = transcriptionEngine
        self.cleanupEngine = cleanupEngine
        self.metrics = metrics
    }

    /// The text that should actually be injected.
    public var finalText: String { cleanedText.isEmpty ? rawText : cleanedText }
}

/// Orchestrates transcribe → cleanup for one utterance. Pure with respect to
/// the system: it holds injected engines and a clock, touches no UI, no audio
/// hardware, and no network of its own — which makes it fully unit-testable.
///
/// Degradation is built in: if cleanup fails or is unavailable, the raw
/// transcript is returned rather than surfacing an error to the user.
public struct DictationPipeline: Sendable {
    private let transcriber: TranscriptionEngine
    private let cleaner: CleanupEngine
    private let clock: @Sendable () -> TimeInterval

    public init(transcriber: TranscriptionEngine,
                cleaner: CleanupEngine,
                clock: @escaping @Sendable () -> TimeInterval = { Date().timeIntervalSinceReferenceDate }) {
        self.transcriber = transcriber
        self.cleaner = cleaner
        self.clock = clock
    }

    /// Run the full pipeline on a captured utterance.
    /// - Parameter onState: optional progress callback for the UI.
    public func run(_ audio: PCMBuffer,
                    locale: String = "en-US",
                    options: CleanupOptions,
                    onState: (@Sendable (DictationState) -> Void)? = nil) async throws -> PipelineResult {
        var metrics = LatencyMetrics()
        metrics.audioDuration = audio.duration
        let started = clock()

        onState?(.transcribing)
        let tStart = clock()
        let transcription = try await transcriber.transcribe(audio, locale: locale)
        metrics.transcription = clock() - tStart

        let raw = transcription.text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Empty transcription is not an error — the user may have keyed by
        // accident. Return cleanly with no text to inject.
        guard !raw.isEmpty else {
            metrics.timeToText = clock() - started
            return PipelineResult(rawText: "", cleanedText: "",
                                  transcriptionEngine: transcriber.kind,
                                  cleanupEngine: .none, metrics: metrics)
        }

        onState?(.cleaning)
        let cStart = clock()
        let cleaned: String
        let usedCleanup: CleanupEngineKind
        do {
            cleaned = try await cleaner.cleanup(raw, options: options, locale: locale)
            usedCleanup = cleaner.kind
        } catch {
            // Degrade gracefully: ship the raw text.
            cleaned = raw
            usedCleanup = .none
        }
        metrics.cleanup = clock() - cStart
        metrics.timeToText = clock() - started

        return PipelineResult(rawText: raw, cleanedText: cleaned,
                              transcriptionEngine: transcriber.kind,
                              cleanupEngine: usedCleanup, metrics: metrics)
    }
}
