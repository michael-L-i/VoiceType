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

    /// User dictionary applied to the final text after any cleanup engine:
    /// chronic mishears, names, jargon.
    public var wordReplacements: [WordReplacement]

    /// BCP-47 locale used for transcription (e.g. "en-US").
    public var locale: String

    /// Push-to-talk trigger.
    public var hotkey: Hotkey

    /// Play a subtle sound when recording starts/stops.
    public var soundFeedback: Bool

    /// Keep a local, on-device history of dictations for review/redo.
    public var keepHistory: Bool

    /// Show the small resting pill when idle. Off only hides the at-rest
    /// sliver — the oval still appears normally once dictation starts.
    public var showRestingIndicator: Bool

    public init(transcriptionEngine: TranscriptionEngineKind = .appleOnDevice,
                cleanupEngine: CleanupEngineKind = .foundationModels,
                cleanupOptions: CleanupOptions = .default,
                wordReplacements: [WordReplacement] = [],
                locale: String = "en-US",
                hotkey: Hotkey = .default,
                soundFeedback: Bool = true,
                keepHistory: Bool = true,
                showRestingIndicator: Bool = true) {
        self.transcriptionEngine = transcriptionEngine
        self.cleanupEngine = cleanupEngine
        self.cleanupOptions = cleanupOptions
        self.wordReplacements = wordReplacements
        self.locale = locale
        self.hotkey = hotkey
        self.soundFeedback = soundFeedback
        self.keepHistory = keepHistory
        self.showRestingIndicator = showRestingIndicator
    }

    // Custom decoding so settings saved before `showRestingIndicator` existed
    // still load instead of silently resetting to defaults (SettingsStore
    // discards the whole struct on any decode failure).
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        transcriptionEngine = try c.decode(TranscriptionEngineKind.self, forKey: .transcriptionEngine)
        cleanupEngine = try c.decode(CleanupEngineKind.self, forKey: .cleanupEngine)
        cleanupOptions = try c.decode(CleanupOptions.self, forKey: .cleanupOptions)
        wordReplacements = try c.decodeIfPresent([WordReplacement].self, forKey: .wordReplacements) ?? []
        locale = try c.decode(String.self, forKey: .locale)
        hotkey = try c.decode(Hotkey.self, forKey: .hotkey)
        soundFeedback = try c.decode(Bool.self, forKey: .soundFeedback)
        keepHistory = try c.decode(Bool.self, forKey: .keepHistory)
        showRestingIndicator = try c.decodeIfPresent(Bool.self, forKey: .showRestingIndicator) ?? true
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
