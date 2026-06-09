import Foundation

// MARK: - Identity of the swappable backends

/// Which transcription backend produced (or should produce) text.
public enum TranscriptionEngineKind: String, Sendable, Codable, CaseIterable {
    /// Apple on-device `SpeechTranscriber` (macOS 26+). Default when available.
    case appleOnDevice
    /// Bundled `whisper.cpp`. Local fallback for unsupported hardware/locales.
    case whisperCpp
    /// Groq cloud (whisper-large-v3-turbo). Opt-in, requires an API key.
    case groqCloud

    public var displayName: String {
        switch self {
        case .appleOnDevice: return "Apple (on-device)"
        case .whisperCpp: return "Whisper (local)"
        case .groqCloud: return "Groq (cloud)"
        }
    }

    /// True if using this engine sends audio off-device.
    public var isCloud: Bool { self == .groqCloud }
}

/// Which cleanup backend tidies the raw transcript.
public enum CleanupEngineKind: String, Sendable, Codable, CaseIterable {
    /// Apple on-device LLM via FoundationModels. Default when available.
    case foundationModels
    /// Deterministic regex/heuristic cleanup. Always available; final fallback.
    case ruleBased
    /// Groq cloud LLM. Opt-in, requires an API key.
    case groqCloud
    /// No cleanup — inject the raw transcript verbatim.
    case none

    public var displayName: String {
        switch self {
        case .foundationModels: return "Apple Intelligence (on-device)"
        case .ruleBased: return "Built-in rules"
        case .groqCloud: return "Groq (cloud)"
        case .none: return "None (raw)"
        }
    }

    public var isCloud: Bool { self == .groqCloud }
}

// MARK: - Transcription

public struct TranscriptionResult: Sendable, Equatable {
    /// The recognized text, untouched by cleanup.
    public var text: String
    /// BCP-47 locale the audio was transcribed in (e.g. "en-US").
    public var locale: String
    /// Wall-clock time the engine spent producing the result.
    public var processingTime: TimeInterval

    public init(text: String, locale: String, processingTime: TimeInterval = 0) {
        self.text = text
        self.locale = locale
        self.processingTime = processingTime
    }
}

public enum TranscriptionError: Error, Sendable, Equatable {
    /// The engine cannot run in the current environment (model missing,
    /// hardware unsupported, no API key, offline, etc).
    case unavailable(reason: String)
    /// Audio was empty or below the speech threshold.
    case noSpeechDetected
    /// A networked engine failed to reach its provider.
    case network(String)
    /// Anything else, carrying a human-readable message.
    case failed(String)
}

/// A swappable speech-to-text backend.
///
/// Implementations live in the app target (they touch system or network
/// frameworks); this contract is the only thing the pipeline and UI depend on.
public protocol TranscriptionEngine: Sendable {
    var kind: TranscriptionEngineKind { get }

    /// Cheap, side-effect-free check used to pick a default and to gray out
    /// unavailable options in the UI. Must not prompt the user.
    func isAvailable() async -> Bool

    /// Transcribe one complete utterance. The pipeline calls this once, after
    /// the push-to-talk key is released, with the full captured buffer.
    func transcribe(_ audio: PCMBuffer, locale: String) async throws -> TranscriptionResult
}

// MARK: - Cleanup

public struct CleanupOptions: Sendable, Equatable, Codable {
    public var removeFillers: Bool
    public var addPunctuation: Bool
    public var fixCapitalization: Bool

    public init(removeFillers: Bool = true,
                addPunctuation: Bool = true,
                fixCapitalization: Bool = true) {
        self.removeFillers = removeFillers
        self.addPunctuation = addPunctuation
        self.fixCapitalization = fixCapitalization
    }

    public static let `default` = CleanupOptions()
}

/// A swappable transcript-tidying backend. Cleanup must *never* change the
/// user's meaning — only delivery (fillers, punctuation, casing).
///
/// Contract: cleanup degrades gracefully. If an implementation cannot run, it
/// throws and the pipeline falls back to the raw text rather than failing.
public protocol CleanupEngine: Sendable {
    var kind: CleanupEngineKind { get }

    func isAvailable() async -> Bool

    func cleanup(_ text: String, options: CleanupOptions) async throws -> String
}

public enum CleanupError: Error, Sendable, Equatable {
    case unavailable(reason: String)
    case failed(String)
}

// MARK: - Text injection

/// Delivers the final text into whatever app is focused.
public protocol TextInjector: Sendable {
    func inject(_ text: String) async throws
}

public enum InjectionError: Error, Sendable, Equatable {
    /// Accessibility permission has not been granted.
    case notTrusted
    case failed(String)
}
