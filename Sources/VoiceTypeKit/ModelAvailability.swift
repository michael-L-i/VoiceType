import Foundation

/// Lifecycle of a transcription engine's on-device weights. Drives the engine
/// list in Settings: the built-in Apple engine is `builtIn` where the OS can run
/// it and `unsupported` where it can't; downloadable engines move
/// `notDownloaded → downloading → ready` (or `failed`).
///
/// Pure value type so the state machine stays in the testable Kit; the app layer
/// computes it from the model managers.
public enum ModelAvailability: Sendable, Equatable {
    /// Ships with the OS / app — no download needed, and usable here.
    case builtIn
    /// Ships with the OS but this Mac can't run it, carrying a user-facing
    /// reason. Apple's on-device recognizer is absent on macOS 14–15 until the
    /// system has downloaded dictation assets, so "built in" is not the same as
    /// "works here" — claiming otherwise strands the user on a dead engine.
    case unsupported(String)
    /// Downloadable engine whose weights aren't present yet.
    case notDownloaded
    /// Download in flight. Fraction is 0...1, or nil when indeterminate.
    case downloading(Double?)
    /// Weights are present and ready to load.
    case ready
    /// The last download attempt failed, carrying a user-facing message.
    case failed(String)

    /// True when the engine can actually run right now.
    public var isReady: Bool {
        switch self {
        case .builtIn, .ready: return true
        case .unsupported, .notDownloaded, .downloading, .failed: return false
        }
    }

    /// True while a download is in progress.
    public var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }
}
