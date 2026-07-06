import Testing
@testable import VoiceTypeKit

@Suite("Cleanup length guard")
struct CleanupGuardTests {
    /// 40 content words of rambling dictation.
    let ramble = """
    I was thinking about the design review tomorrow and I think we should \
    probably move it to thursday because half the team is going to be out on \
    wednesday and also we still need to finish the mockups before we can talk
    """

    @Test("a drastically shortened output is flagged as a summary")
    func flagsSummary() {
        #expect(CleanupGuard.looksLikeSummary(raw: ramble, cleaned: "Move the design review."))
    }

    @Test("normal filler-level shrinkage is not flagged")
    func allowsNormalCleanup() {
        let cleaned = """
        I was thinking about the design review tomorrow, and I think we should \
        move it to Thursday, because half the team is out on Wednesday, and we \
        still need to finish the mockups before we can talk.
        """
        #expect(!CleanupGuard.looksLikeSummary(raw: ramble, cleaned: cleaned))
    }

    @Test("spoken-symbol rendering never trips the guard")
    func symbolCollapse() {
        #expect(!CleanupGuard.looksLikeSummary(
            raw: "print open paren x comma y close paren and then call get underscore user data",
            cleaned: "print(x, y) and then call get_user_data"))
    }

    @Test("short utterances are exempt even when they halve")
    func shortInputExempt() {
        #expect(!CleanupGuard.looksLikeSummary(raw: "I want two, no three", cleaned: "I want three"))
    }

    @Test("output longer than input is never flagged")
    func longerOutput() {
        #expect(!CleanupGuard.looksLikeSummary(raw: ramble, cleaned: ramble + " extra words here"))
    }

    @Test("boundary: exactly half the content words is flagged, just above is not")
    func boundary() {
        // 10 content words on the raw side.
        let raw = "one two three four five six seven eight nine ten"
        #expect(CleanupGuard.looksLikeSummary(raw: raw, cleaned: "one two three four"))
        #expect(!CleanupGuard.looksLikeSummary(raw: raw, cleaned: "one two three four five"))
    }

    @Test("fabricated output much longer than the input is flagged")
    func flagsFabrication() {
        // The observed failure mode: a 12-word dictation answered with a
        // regurgitated 40-word prompt example.
        let raw = "the meeting I think we should move to thursday because wednesday is packed"
        #expect(CleanupGuard.looksFabricated(raw: raw, cleaned: ramble))
        #expect(CleanupGuard.looksUnfaithful(raw: raw, cleaned: ramble))
    }

    @Test("punctuation-only growth is not fabrication")
    func allowsPunctuationGrowth() {
        let raw = "okay lets do it"
        #expect(!CleanupGuard.looksFabricated(raw: raw, cleaned: "Okay, let's do it."))
    }

    @Test("tiny utterances are exempt from the fabrication check")
    func shortFabricationExempt() {
        #expect(!CleanupGuard.looksFabricated(raw: "yes", cleaned: "Yes, absolutely, let's do that."))
    }

    @Test("unfaithful combines both directions")
    func unfaithfulBothDirections() {
        #expect(CleanupGuard.looksUnfaithful(raw: ramble, cleaned: "Move the review."))
        #expect(!CleanupGuard.looksUnfaithful(raw: ramble, cleaned: ramble))
    }

    @Test("a dropped opening clause is flagged even when the rest survives")
    func flagsDroppedOpening() {
        #expect(CleanupGuard.droppedOpening(
            raw: "we have to do three things um update the docs bump the version and then tag the release",
            cleaned: "Update the docs bump the version and then tag the release"))
        #expect(CleanupGuard.droppedOpening(
            raw: "okay so the way I see it there are three problems with the current design and we should fix them",
            cleaned: "There are three problems with the current design and we should fix them."))
    }

    @Test("intact openings are not flagged")
    func allowsIntactOpening() {
        #expect(!CleanupGuard.droppedOpening(
            raw: "um so I was thinking about the launch next week and whether we should delay it",
            cleaned: "I was thinking about the launch next week and whether we should delay it."))
        // A self-correction near the opening legitimately drops one probe word.
        #expect(!CleanupGuard.droppedOpening(
            raw: "send the report to bob no wait to alice before lunch and copy the team as well",
            cleaned: "Send the report to Alice before lunch and copy the team as well."))
    }

    @Test("short inputs are exempt from the opening probe")
    func shortOpeningExempt() {
        #expect(!CleanupGuard.droppedOpening(raw: "I want two, no three", cleaned: "I want three"))
    }

    @Test("code rendering near the opening is not a dropped opening")
    func openingCodeJoinSafe() {
        // "utils dot t s" joins into utils.ts — the probe must credit the
        // fragment and skip the single spoken letters.
        #expect(!CleanupGuard.droppedOpening(
            raw: "open utils dot t s and rename the parse data function to something clearer",
            cleaned: "open utils.ts and rename the parseData function to something clearer"))
    }

    @Test("a probe word colliding with a later unrelated word still counts as dropped")
    func openingPositional() {
        // Real eval pair: "way" from the dropped opener ("the way I see it")
        // reappears later in "way too much space" — survival must be
        // positional, not anywhere-in-text, to catch this.
        #expect(CleanupGuard.droppedOpening(
            raw: "okay so the way I see it there are three problems with the current design uh first the sidebar takes up way too much space on small screens",
            cleaned: "There are three problems with the current design. First, the sidebar takes up way too much space on small screens."))
    }

    @Test("an answered question is flagged as invented content")
    func flagsAnsweredQuestion() {
        // The real bug: dictating a question, getting the answer typed.
        #expect(CleanupGuard.inventedWords(
            raw: "do you know what one plus one is",
            cleaned: "One plus one is two.") == ["two"])
        #expect(CleanupGuard.looksUnfaithful(
            raw: "do you know what one plus one is",
            cleaned: "One + one is 2."))
        #expect(!CleanupGuard.looksUnfaithful(
            raw: "do you know what one plus one is",
            cleaned: "Do you know what one plus one is?"))
    }

    @Test("legitimate code rendering is never invented content")
    func renderingNotInvented() {
        for (raw, cleaned) in [
            ("open utils dot t s and rename it", "open utils.ts and rename it"),
            ("define camel case parse request", "define parseRequest"),
            ("cd tilde slash projects slash voice type", "cd ~/projects/voicetype"),
            ("send it to john dot smith at gmail dot com", "send it to john.smith@gmail.com"),
            ("npm run build dash dash verbose", "npm run build --verbose"),
            ("print open paren x comma y close paren", "print(x, y)"),
            ("okay lets do it", "Okay, let's do it."),
        ] {
            #expect(CleanupGuard.inventedWords(raw: raw, cleaned: cleaned).isEmpty,
                    "false invention in: \(cleaned)")
        }
    }

    @Test("every few-shot example is free of invented content")
    func fewShotNotInvented() {
        for pair in CleanupExamples.fewShot + CleanupExamples.terminalFewShot {
            #expect(CleanupGuard.inventedWords(raw: pair.spoken, cleaned: pair.cleaned).isEmpty,
                    "example invents words: \(pair.spoken)")
        }
    }

    @Test("fillers and symbols are excluded from the raw content count")
    func contentWordCount() {
        #expect(CleanupGuard.contentWordCount("um uh open paren hello world close paren") == 2)
    }

    @Test("every few-shot example passes the guard")
    func fewShotExamplesPass() {
        for pair in CleanupExamples.fewShot + CleanupExamples.terminalFewShot {
            #expect(!CleanupGuard.looksLikeSummary(raw: pair.spoken, cleaned: pair.cleaned),
                    "example flagged as summary: \(pair.spoken)")
        }
    }
}
