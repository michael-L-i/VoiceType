import Testing
@testable import VoiceTypeKit

@Suite("Spoken symbol rendering")
struct SpokenSymbolsTests {

    // MARK: - Dot / extensions

    @Test("extension homophone joins a file name")
    func dotHomophone() {
        #expect(SpokenSymbols.render("open main dot pie", category: .general)
            == "open main.py")
    }

    @Test("spelled letters after dot form an extension")
    func dotSpelledLetters() {
        #expect(SpokenSymbols.render("the entry point is index dot j s", category: .general)
            == "the entry point is index.js")
        #expect(SpokenSymbols.render("open utils dot t s and rename it", category: .codeEditor)
            == "open utils.ts and rename it")
    }

    @Test("dot in ordinary prose stays a word")
    func dotProseGuard() {
        #expect(SpokenSymbols.render("compute the dot product of the two vectors", category: .general)
            == "compute the dot product of the two vectors")
    }

    @Test("dot before a non-extension word stays a word")
    func dotNonExtension() {
        #expect(SpokenSymbols.render("we met at the dot yesterday", category: .general)
            == "we met at the dot yesterday")
    }

    // MARK: - Underscore

    @Test("underscore joins identifier parts, including chains")
    func underscoreJoins() {
        #expect(SpokenSymbols.render("set max underscore retries to five", category: .general)
            == "set max_retries to five")
        #expect(SpokenSymbols.render("update test underscore client dot pie now", category: .general)
            == "update test_client.py now")
    }

    @Test("underscore as a verb stays prose")
    func underscoreProseGuard() {
        let text = "I want to underscore the importance of testing"
        #expect(SpokenSymbols.render(text, category: .general) == text)
    }

    // MARK: - Dash

    @Test("dash joins single spoken letters into a handle, lowering the pronoun I")
    func dashHandle() {
        #expect(SpokenSymbols.render("the repo is under michael dash L dash I on github", category: .general)
            == "the repo is under michael-L-i on github")
    }

    @Test("dash in prose stays a word outside the terminal")
    func dashProseGuard() {
        let text = "add a dash of salt and stir"
        #expect(SpokenSymbols.render(text, category: .general) == text)
    }

    @Test("terminal renders short and long flags")
    func terminalFlags() {
        #expect(SpokenSymbols.render("npm run build dash dash verbose", category: .terminal)
            == "npm run build --verbose")
        #expect(SpokenSymbols.render("tmux attach dash t work", category: .terminal)
            == "tmux attach -t work")
        #expect(SpokenSymbols.render("ls dash l", category: .terminal)
            == "ls -l")
    }

    // MARK: - Terminal paths

    @Test("terminal renders tilde, dot-slash, and slash paths")
    func terminalPaths() {
        #expect(SpokenSymbols.render("cd tilde slash projects slash voicetype", category: .terminal)
            == "cd ~/projects/voicetype")
        #expect(SpokenSymbols.render("run dot slash build", category: .terminal)
            == "run ./build")
    }

    @Test("slash outside the terminal stays a word")
    func slashProseOutsideTerminal() {
        let text = "the slash in the url is wrong"
        #expect(SpokenSymbols.render(text, category: .general) == text)
    }

    // MARK: - Parens

    @Test("open and close paren become attached symbols with literal commas inside")
    func parens() {
        #expect(SpokenSymbols.render("print open paren x comma y close paren", category: .general)
            == "print(x, y)")
    }

    @Test("comma outside a paren pair stays a word")
    func commaOutsideParens() {
        let text = "use a comma between the names"
        #expect(SpokenSymbols.render(text, category: .general) == text)
    }

    // MARK: - Email

    @Test("spoken email renders compactly")
    func email() {
        #expect(SpokenSymbols.render("send it to john dot smith at gmail dot com", category: .general)
            == "send it to john.smith@gmail.com")
    }

    @Test("a lone verb or function word never becomes an email local part")
    func emailStopwordGuard() {
        let text = "have a look at gmail dot com"
        #expect(SpokenSymbols.render(text, category: .general) == text)
    }

    @Test("plain at in prose stays a word")
    func atProseGuard() {
        let text = "see you at the office"
        #expect(SpokenSymbols.render(text, category: .general) == text)
    }
}

@Suite("Rule-based cleanup end-to-end with symbols")
struct RuleBasedSymbolTests {
    let opts = CleanupOptions.default

    @Test("file dictation matches the model's exact contract")
    func dotPieExact() {
        #expect(RuleBasedCleanup.process("open main dot pie", options: opts) == "Open main.py")
    }

    @Test("terminal commands render flags with no capital and no period")
    func terminalExacts() {
        let terminal = CleanupContext(category: .terminal)
        #expect(RuleBasedCleanup.process("npm run build dash dash verbose", options: opts, context: terminal)
            == "npm run build --verbose")
        #expect(RuleBasedCleanup.process("ls dash l", options: opts, context: terminal)
            == "ls -l")
        #expect(RuleBasedCleanup.process("tmux attach dash t work", options: opts, context: terminal)
            == "tmux attach -t work")
    }

    @Test("question openers gain a question mark, not a period")
    func questionMark() {
        let out = RuleBasedCleanup.process("what time does the demo start tomorrow", options: opts)
        #expect(out == "What time does the demo start tomorrow?")
    }

    @Test("a sentence ending in an identifier gets no trailing period")
    func noPeriodAfterIdentifier() {
        #expect(RuleBasedCleanup.process("rename it to blue underscore file", options: opts)
            == "Rename it to blue_file")
        #expect(RuleBasedCleanup.process("send it to john dot smith at gmail dot com", options: opts)
            == "Send it to john.smith@gmail.com")
    }

    @Test("rendered identifiers survive capitalization and spacing passes")
    func identifierSurvivesLaterPasses() {
        let out = RuleBasedCleanup.process(
            "so um the fix is simple you just open main dot pie and update test underscore client dot pie",
            options: opts)
        #expect(out.contains("main.py"))
        #expect(out.contains("test_client.py"))
        #expect(!out.contains("main. py"))
        #expect(!out.contains("Py"))
    }

    @Test("symbol rendering is skipped for non-English locales")
    func nonEnglishSkipsRendering() {
        let out = RuleBasedCleanup.process("apri main dot pie", options: opts, locale: "it-IT")
        #expect(out.contains("dot"))
    }
}
