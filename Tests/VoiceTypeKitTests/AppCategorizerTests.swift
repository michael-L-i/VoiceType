import Testing
@testable import VoiceTypeKit

@Suite("App categorizer")
struct AppCategorizerTests {
    @Test("known terminals map to .terminal")
    func terminals() {
        for id in ["com.apple.Terminal", "com.googlecode.iterm2", "com.mitchellh.ghostty",
                   "io.alacritty", "net.kovidgoyal.kitty", "com.github.wez.wezterm"] {
            #expect(AppCategorizer.category(forBundleID: id) == .terminal)
        }
    }

    @Test("known code editors map to .codeEditor")
    func codeEditors() {
        for id in ["com.apple.dt.Xcode", "dev.zed.Zed", "com.todesktop.230313mzl4w4u92",
                   "com.sublimetext.4"] {
            #expect(AppCategorizer.category(forBundleID: id) == .codeEditor)
        }
    }

    @Test("known messaging apps map to .messaging")
    func messaging() {
        for id in ["com.tinyspeck.slackmacgap", "com.apple.MobileSMS", "com.hnc.Discord"] {
            #expect(AppCategorizer.category(forBundleID: id) == .messaging)
        }
    }

    @Test("prefix families match channel-suffixed IDs")
    func prefixes() {
        #expect(AppCategorizer.category(forBundleID: "dev.warp.Warp-Stable") == .terminal)
        #expect(AppCategorizer.category(forBundleID: "com.microsoft.VSCodeInsiders") == .codeEditor)
        #expect(AppCategorizer.category(forBundleID: "com.jetbrains.intellij") == .codeEditor)
    }

    @Test("unknown, empty, and nil bundle IDs fall back to .general")
    func fallback() {
        #expect(AppCategorizer.category(forBundleID: "com.apple.TextEdit") == .general)
        #expect(AppCategorizer.category(forBundleID: "") == .general)
        #expect(AppCategorizer.category(forBundleID: nil) == .general)
    }

    @Test("default context is general with no app identity")
    func defaultContext() {
        #expect(CleanupContext.general.category == .general)
        #expect(CleanupContext.general.appBundleID == nil)
        #expect(CleanupContext.general.appName == nil)
    }
}
