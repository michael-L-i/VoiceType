import Foundation

/// What kind of app the user is dictating into. Used only to bias the cleanup
/// pass (e.g. terminal dictation is likely shell commands, not prose).
public enum AppCategory: String, Sendable, Equatable, CaseIterable {
    case terminal
    case codeEditor
    case messaging
    case general
}

/// Per-dictation context about the app the text will be injected into.
///
/// Deliberately NOT Codable: this is ephemeral, never persisted alongside
/// settings, and — like everything else in the pipeline — never leaves the
/// machine. The bundle ID/name feed only the on-device cleanup prompt and the
/// local usage stats.
public struct CleanupContext: Sendable, Equatable {
    public var appBundleID: String?
    public var appName: String?
    public var category: AppCategory

    public init(appBundleID: String? = nil,
                appName: String? = nil,
                category: AppCategory = .general) {
        self.appBundleID = appBundleID
        self.appName = appName
        self.category = category
    }

    /// The default context when the target app is unknown (file imports, tests).
    public static let general = CleanupContext()
}

/// Pure bundle-ID → category mapping. Takes plain strings so the Kit stays
/// framework-free; the app resolves the frontmost application via NSWorkspace
/// and hands the bundle ID in.
public enum AppCategorizer {
    /// Exact bundle-ID matches.
    static let exact: [String: AppCategory] = [
        // Terminals
        "com.apple.Terminal": .terminal,
        "com.googlecode.iterm2": .terminal,
        "com.mitchellh.ghostty": .terminal,
        "io.alacritty": .terminal,
        "net.kovidgoyal.kitty": .terminal,
        "com.github.wez.wezterm": .terminal,
        // Code editors
        "com.apple.dt.Xcode": .codeEditor,
        "dev.zed.Zed": .codeEditor,
        "com.todesktop.230313mzl4w4u92": .codeEditor, // Cursor
        "com.sublimetext.4": .codeEditor,
        // Messaging
        "com.tinyspeck.slackmacgap": .messaging, // Slack
        "com.apple.MobileSMS": .messaging, // Messages
        "com.hnc.Discord": .messaging,
    ]

    /// Prefix matches, for app families whose IDs vary by channel or product
    /// (VS Code Insiders, every JetBrains IDE, Warp stable vs preview).
    static let prefixes: [(prefix: String, category: AppCategory)] = [
        ("dev.warp.Warp", .terminal),
        ("com.microsoft.VSCode", .codeEditor),
        ("com.jetbrains.", .codeEditor),
    ]

    public static func category(forBundleID bundleID: String?) -> AppCategory {
        guard let bundleID, !bundleID.isEmpty else { return .general }
        if let match = exact[bundleID] { return match }
        if let match = prefixes.first(where: { bundleID.hasPrefix($0.prefix) }) {
            return match.category
        }
        return .general
    }
}
