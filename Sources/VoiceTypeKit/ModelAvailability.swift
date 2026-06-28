import Foundation

/// Lifecycle of a transcription engine's on-device weights. Drives the engine
/// list in Settings: the built-in Apple engine is always `builtIn`; downloadable
/// engines move `notDownloaded → downloading → ready` (or `failed`).
///
/// Pure value type so the state machine stays in the testable Kit; the app layer
/// computes it from the model managers.
public enum ModelAvailability: Sendable, Equatable {
    /// Ships with the OS / app — no download, always usable (Apple).
    case builtIn
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
        case .notDownloaded, .downloading, .failed: return false
        }
    }

    /// True while a download is in progress.
    public var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }
}
