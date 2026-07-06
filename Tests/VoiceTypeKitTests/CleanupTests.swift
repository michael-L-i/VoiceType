import Testing
@testable import VoiceTypeKit

@Suite("Rule-based cleanup")
struct CleanupTests {
    let opts = CleanupOptions.default

    @Test("removes standalone filler words")
    func removesFillers() {
        let out = RuleBasedCleanup.process("um so I was uh thinking", options: opts)
        #expect(!out.lowercased().contains("um "))
        #expect(!out.lowercased().contains(" uh "))
        #expect(out.contains("thinking"))
    }

    @Test("does not strip real words that resemble fillers")
    func keepsContentWords() {
        // "so", "like", "well" are intentionally preserved.
        let out = RuleBasedCleanup.process("so I like it well enough", options: opts)
        #expect(out.lowercased().contains("so"))
        #expect(out.lowercased().contains("like"))
        #expect(out.lowercased().contains("well"))
    }

    @Test("capitalizes sentences and standalone I")
    func capitalizes() {
        let out = RuleBasedCleanup.process("hello there. i am here", options: opts)
        #expect(out.hasPrefix("Hello"))
        #expect(out.contains(" I "))
        #expect(out.contains("Here") || out.contains("here."))
    }

    @Test("adds terminal punctuation")
    func terminalPunctuation() {
        let out = RuleBasedCleanup.process("this is a test", options: opts)
        #expect(out.hasSuffix("."))
    }

    @Test("collapses whitespace and fixes punctuation spacing")
    func whitespace() {
        let out = RuleBasedCleanup.process("hello   ,  world", options: opts)
        #expect(!out.contains("  "))
        #expect(out.contains("hello, world") || out.contains("Hello, world"))
    }

    @Test("empty input yields empty output")
    func empty() {
        #expect(RuleBasedCleanup.process("   ", options: opts).isEmpty)
    }

    @Test("terminal context keeps commands lowercase with no trailing period")
    func terminalContext() {
        let terminal = CleanupContext(appBundleID: "com.apple.Terminal", category: .terminal)
        let out = RuleBasedCleanup.process("git status", options: opts, context: terminal)
        #expect(out == "git status")
    }

    @Test("terminal context still strips fillers and fixes spacing")
    func terminalStillCleans() {
        let terminal = CleanupContext(category: .terminal)
        let out = RuleBasedCleanup.process("um git   commit", options: opts, context: terminal)
        #expect(out == "git commit")
    }

    @Test("general context is unchanged by the context parameter")
    func generalContext() {
        let out = RuleBasedCleanup.process("this is a test", options: opts, context: .general)
        #expect(out == "This is a test.")
    }

    @Test("respects disabled options")
    func disabledOptions() {
        let raw = CleanupOptions(removeFillers: false, addPunctuation: false, fixCapitalization: false)
        let out = RuleBasedCleanup.process("um hello", options: raw)
        #expect(out.lowercased().contains("um"))
        #expect(!out.hasSuffix("."))
    }
}
