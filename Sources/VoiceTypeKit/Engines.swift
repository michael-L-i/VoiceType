import Foundation

// MARK: - Identity of the swappable backends

/// The company behind an engine's model, used to show its logo.
public enum EngineVendor: String, Sendable {
    case apple
    case nvidia
    case openai

    public var name: String {
        switch self {
        case .apple: return "Apple"
        case .nvidia: return "NVIDIA"
        case .openai: return "OpenAI"
        }
    }
}

/// Which transcription backend produced (or should produce) text. Everything
/// runs on-device. Apple's model is built into the OS; the others download their
/// weights on demand. More local engines plug in here over time.
public enum TranscriptionEngineKind: String, Sendable, Codable, CaseIterable {
    /// Apple on-device `SpeechTranscriber` (macOS 26+). Built in; the default.
    case appleOnDevice
    /// NVIDIA Parakeet TDT 0.6B V3 (FastConformer-TDT) on the Neural Engine via
    /// FluidAudio.
    case parakeet
    /// OpenAI Whisper "base" on the Neural Engine via WhisperKit — small and fast.
    case whisperKit

    public var displayName: String {
        switch self {
        case .appleOnDevice: return "Apple Speech"
        case .parakeet: return "Parakeet TDT 0.6B V3"
        case .whisperKit: return "Whisper Base"
        }
    }

    /// The model's vendor, for the logo shown next to it.
    public var vendor: EngineVendor {
        switch self {
        case .appleOnDevice: return .apple
        case .parakeet: return .nvidia
        case .whisperKit: return .openai
        }
    }

    /// One-line description of what the model is, shown under its name.
    public var summary: String {
        switch self {
        case .appleOnDevice:
            return "Ships with macOS and runs entirely on your Mac — ready the moment you are."
        case .parakeet:
            return "NVIDIA's compact speech model — quick, multilingual, and punctuation-aware."
        case .whisperKit:
            return "OpenAI's small Whisper model — lightweight, fast, and broadly multilingual."
        }
    }

    /// Short feature chips shown in the Models list (no accuracy/speed numbers).
    public var features: [String] {
        switch self {
        case .appleOnDevice: return ["Built-in", "Streaming", "Multilingual"]
        case .parakeet: return ["~500 MB", "Multilingual", "Punctuation built-in"]
        case .whisperKit: return ["~150 MB", "Multilingual", "Light & fast"]
        }
    }

    /// True when the engine's weights must be downloaded before first use. Apple's
    /// model ships with the OS; the others are fetched on demand.
    public var requiresDownload: Bool { self != .appleOnDevice }

    /// Rough on-disk download size, shown on the download button. Nil for the
    /// built-in engine.
    public var approxDownloadSize: String? {
        switch self {
        case .appleOnDevice: return nil
        case .parakeet: return "~500 MB"
        case .whisperKit: return "~150 MB"
        }
    }

    /// Attribution we're obliged to surface (e.g. Parakeet's CC-BY-4.0). Nil when
    /// none is required.
    public var attribution: String? {
        switch self {
        case .appleOnDevice: return nil
        case .parakeet: return "Speech model © NVIDIA, licensed under CC-BY-4.0."
        case .whisperKit: return "OpenAI Whisper (MIT), run on-device via WhisperKit (Argmax)."
        }
    }
}

/// Which cleanup backend tidies the raw transcript.
public enum CleanupEngineKind: String, Sendable, Codable, CaseIterable {
    /// Apple on-device LLM via FoundationModels. Default when available.
    case foundationModels
    /// Deterministic regex/heuristic cleanup. Always available; final fallback.
    case ruleBased
    /// No cleanup — inject the raw transcript verbatim.
    case none

    public var displayName: String {
        switch self {
        case .foundationModels: return "Apple Intelligence (on-device)"
        case .ruleBased: return "Built-in rules"
        case .none: return "None (raw)"
        }
    }
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
    /// hardware unsupported, etc).
    case unavailable(reason: String)
    /// Audio was empty or below the speech threshold.
    case noSpeechDetected
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

    /// Tidy a transcript's delivery. `locale` is the BCP-47 language the text is
    /// in (the same one transcription used); engines must keep the output in that
    /// language and may use it to apply language-appropriate rules.
    func cleanup(_ text: String, options: CleanupOptions, locale: String) async throws -> String
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
