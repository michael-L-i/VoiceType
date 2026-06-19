import Foundation

/// Single seam for file-backed app data under
/// `~/Library/Application Support/VoiceType/`. Matches the location
/// `WhisperModelManager` already uses, so all on-device data lives together.
/// Larger data (transcripts) lives here rather than UserDefaults.
enum AppSupport {
    /// Absolute URL for a file in the VoiceType support directory, creating the
    /// directory on demand. Throws only if the support directory can't be made.
    static func fileURL(_ name: String) throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = support.appendingPathComponent("VoiceType", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(name, isDirectory: false)
    }
}
