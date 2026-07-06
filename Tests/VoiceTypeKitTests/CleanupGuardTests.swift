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

    @Test("fillers and symbols are excluded from the raw content count")
    func contentWordCount() {
        #expect(CleanupGuard.contentWordCount("um uh open paren hello world close paren") == 2)
    }

    @Test("every few-shot example passes the guard")
    func fewShotExamplesPass() {
        for pair in CleanupExamples.fewShot {
            #expect(!CleanupGuard.looksLikeSummary(raw: pair.spoken, cleaned: pair.cleaned),
                    "example flagged as summary: \(pair.spoken)")
        }
    }
}
