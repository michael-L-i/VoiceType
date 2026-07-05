import Foundation

/// User-facing, persisted configuration. Pure value type so it is easy to test
/// and to diff. The app layer is responsible for loading/saving (UserDefaults).
/// Everything runs on-device, so there are no secrets to keep.
public struct AppSettings: Sendable, Codable, Equatable {
    /// Preferred transcription engine. The resolver downgrades to an available
    /// one if this is not usable right now.
    public var transcriptionEngine: TranscriptionEngineKind
    /// Preferred cleanup engine, same downgrade rule.
    public var cleanupEngine: CleanupEngineKind
    public var cleanupOptions: CleanupOptions

    /// BCP-47 locale used for transcription (e.g. "en-US").
    public var locale: String

    /// Push-to-talk trigger.
    public var hotkey: Hotkey

    /// Play a subtle sound when recording starts/stops.
    public var soundFeedback: Bool

    /// Keep a local, on-device history of dictations for review/redo.
    public var keepHistory: Bool

    /// Show the floating pill/waveform indicator while dictation is active.
    public var showDictationIndicator: Bool

    public init(transcriptionEngine: TranscriptionEngineKind = .appleOnDevice,
                cleanupEngine: CleanupEngineKind = .foundationModels,
                cleanupOptions: CleanupOptions = .default,
                locale: String = "en-US",
                hotkey: Hotkey = .default,
                soundFeedback: Bool = true,
                keepHistory: Bool = true,
                showDictationIndicator: Bool = true) {
        self.transcriptionEngine = transcriptionEngine
        self.cleanupEngine = cleanupEngine
        self.cleanupOptions = cleanupOptions
        self.locale = locale
        self.hotkey = hotkey
        self.soundFeedback = soundFeedback
        self.keepHistory = keepHistory
        self.showDictationIndicator = showDictationIndicator
    }

    public static let `default` = AppSettings()
}

/// A push-to-talk trigger. The prototype default is "hold Right Option": easy
/// to detect via modifier-flag changes, ergonomic, and rarely used as a real
/// modifier in everyday typing.
public struct Hotkey: Sendable, Codable, Equatable {
    public enum Trigger: String, Sendable, Codable, CaseIterable {
        case rightOption
        case leftOption
        case rightCommand
        case fn

        public var displayName: String {
            switch self {
            case .rightOption: return "Right Option (⌥)"
            case .leftOption: return "Left Option (⌥)"
            case .rightCommand: return "Right Command (⌘)"
            case .fn: return "Fn / Globe"
            }
        }

        /// The key-cap glyph, for a compact selector.
        public var keyCap: String {
            switch self {
            case .rightOption, .leftOption: return "⌥"
            case .rightCommand: return "⌘"
            case .fn: return "fn"
            }
        }

        /// The name without the glyph, paired with `keyCap` in the selector.
        public var shortName: String {
            switch self {
            case .rightOption: return "Right Option"
            case .leftOption: return "Left Option"
            case .rightCommand: return "Right Command"
            case .fn: return "Fn / Globe"
            }
        }
    }

    public var trigger: Trigger
    /// Hold-to-talk (true) vs. tap-to-toggle (false).
    public var holdToTalk: Bool

    public init(trigger: Trigger = .rightOption, holdToTalk: Bool = true) {
        self.trigger = trigger
        self.holdToTalk = holdToTalk
    }

    public static let `default` = Hotkey()
}
