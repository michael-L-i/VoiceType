import Foundation
import os

/// Privacy-respecting logging. The cardinal rule from the constitution: user
/// audio and transcripts are never exfiltrated. This logger therefore:
///   - writes only to Apple's unified logging (local, on-device), and
///   - marks any message that could contain user content as `.private`, so it
///     is redacted in logs unless explicitly opted in on the device.
///
/// Metrics (durations, engine names) are non-sensitive and logged plainly so we
/// can reason about latency.
public enum Log {
    private static let subsystem = "com.voicetype.app"

    public static let pipeline = Logger(subsystem: subsystem, category: "pipeline")
    public static let audio = Logger(subsystem: subsystem, category: "audio")
    public static let hotkey = Logger(subsystem: subsystem, category: "hotkey")
    public static let engine = Logger(subsystem: subsystem, category: "engine")
    public static let injection = Logger(subsystem: subsystem, category: "injection")
    public static let app = Logger(subsystem: subsystem, category: "app")

    /// Log a completed dictation's latency without ever recording its content.
    public static func metrics(_ result: PipelineResult) {
        pipeline.info("""
        dictation ok: transcribe=\(result.transcriptionEngine.rawValue, privacy: .public) \
        cleanup=\(result.cleanupEngine.rawValue, privacy: .public) \
        ttt=\(String(format: "%.0fms", result.metrics.timeToText * 1000), privacy: .public) \
        chars=\(result.finalText.count, privacy: .public)
        """)
    }
}
