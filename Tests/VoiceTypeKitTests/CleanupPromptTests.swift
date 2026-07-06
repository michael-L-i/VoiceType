import Testing
@testable import VoiceTypeKit

@Suite("Cleanup prompt")
struct CleanupPromptTests {
    let opts = CleanupOptions.default

    @Test("length preservation is the first absolute rule")
    func lengthRuleFirst() {
        let instructions = CleanupPrompt.instructions(for: opts)
        let rulesStart = instructions.range(of: "Absolute rules")
        let entireRule = instructions.range(of: "Output the ENTIRE dictation")
        let onlyRule = instructions.range(of: "Output ONLY the cleaned dictation")
        #expect(rulesStart != nil && entireRule != nil && onlyRule != nil)
        if let rulesStart, let entireRule, let onlyRule {
            #expect(rulesStart.lowerBound < entireRule.lowerBound)
            #expect(entireRule.lowerBound < onlyRule.lowerBound)
        }
    }

    @Test("closing reminder forbids summarizing")
    func closingReminder() {
        let instructions = CleanupPrompt.instructions(for: opts)
        let lastLines = instructions.split(separator: "\n").suffix(3).joined(separator: "\n")
        #expect(lastLines.contains("FULL dictation"))
        #expect(lastLines.contains("never a summary"))
    }

    @Test("terminal context adds command guidance and examples")
    func terminalGuidance() {
        let terminal = CleanupContext(category: .terminal)
        let instructions = CleanupPrompt.instructions(for: opts, context: terminal)
        #expect(instructions.contains("--verbose"))
        #expect(instructions.contains("never add a trailing period to a command"))
        #expect(instructions.contains("git commit -m"))
    }

    @Test("code editor context adds a mild code bias")
    func codeEditorGuidance() {
        let editor = CleanupContext(category: .codeEditor)
        let instructions = CleanupPrompt.instructions(for: opts, context: editor)
        #expect(instructions.contains("dictating into a code editor"))
        #expect(!instructions.contains("git commit -m"))
    }

    @Test("general and messaging contexts add no category guidance")
    func neutralContexts() {
        for category in [AppCategory.general, .messaging] {
            let instructions = CleanupPrompt.instructions(
                for: opts, context: CleanupContext(category: category))
            #expect(!instructions.contains("dictating into a terminal"))
            #expect(!instructions.contains("dictating into a code editor"))
        }
    }

    @Test("disabled options omit their task lines")
    func disabledOptions() {
        let none = CleanupOptions(removeFillers: false, addPunctuation: false, fixCapitalization: false)
        let instructions = CleanupPrompt.instructions(for: none)
        #expect(!instructions.contains("filler words"))
        #expect(!instructions.contains("Fix capitalization"))
        #expect(instructions.contains("return the words exactly as given"))
        // The anti-summarization contract still holds in passthrough mode.
        #expect(instructions.contains("Output the ENTIRE dictation"))
    }

    @Test("locale renders as an English language name")
    func localeName() {
        let instructions = CleanupPrompt.instructions(for: opts, locale: "de-DE")
        #expect(instructions.contains("German"))
    }

    @Test("per-request prompt fences the transcript as data")
    func fencedPrompt() {
        let prompt = CleanupPrompt.prompt(for: "hello world")
        #expect(prompt.contains("<<<TRANSCRIPT\nhello world\nTRANSCRIPT>>>"))
    }
}
