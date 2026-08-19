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

    @Test("a dropped closing sentence is flagged even though most words survive")
    func flagsDroppedEnding() {
        // The retention ratio can't catch this: ~80% of the words are still
        // there, and only the last thought is gone.
        #expect(CleanupGuard.droppedEnding(
            raw: "we should ship the fix on monday and then watch the crash rate for a day anyway that's my take let me know what you think",
            cleaned: "We should ship the fix on Monday and then watch the crash rate for a day."))
        #expect(CleanupGuard.looksUnfaithful(
            raw: "we should ship the fix on monday and then watch the crash rate for a day anyway that's my take let me know what you think",
            cleaned: "We should ship the fix on Monday and then watch the crash rate for a day."))
    }

    @Test("intact endings are not flagged")
    func allowsIntactEnding() {
        #expect(!CleanupGuard.droppedEnding(
            raw: "I was thinking about the launch next week and whether we should delay it um you know",
            cleaned: "I was thinking about the launch next week and whether we should delay it."))
        // A self-correction at the end legitimately drops one probe word.
        #expect(!CleanupGuard.droppedEnding(
            raw: "send the report to the team before lunch on tuesday no wait on wednesday",
            cleaned: "Send the report to the team before lunch on Wednesday."))
    }

    @Test("short inputs are exempt from the ending probe")
    func shortEndingExempt() {
        #expect(!CleanupGuard.droppedEnding(raw: "I want two, no three", cleaned: "I want three"))
    }

    @Test("code rendering at the end is not a dropped ending")
    func endingCodeJoinSafe() {
        #expect(!CleanupGuard.droppedEnding(
            raw: "rename the parse data function to something clearer and then open utils dot t s",
            cleaned: "rename the parseData function to something clearer and then open utils.ts"))
    }

    @Test("a probe word colliding with an earlier unrelated word still counts as dropped")
    func endingPositional() {
        // "release" appears early too; survival has to be positional or the
        // vanished closing clause reads as intact.
        #expect(CleanupGuard.droppedEnding(
            raw: "the release is blocked on the migration script and the staging soak so we should tell everyone the release slips to friday",
            cleaned: "The release is blocked on the migration script and the staging soak."))
    }

    @Test("fillers and symbols are excluded from the raw content count")
    func contentWordCount() {
        #expect(CleanupGuard.contentWordCount("um uh open paren hello world close paren") == 2)
    }

    @Test("every few-shot example passes the guard")
    func fewShotExamplesPass() {
        // The whole guard, not just the ratio: these pairs are the closest
        // thing we have to a corpus of *correct* cleanups, so any probe that
        // flags one is a false positive we'd otherwise ship.
        for pair in CleanupExamples.fewShot + CleanupExamples.terminalFewShot {
            #expect(!CleanupGuard.looksUnfaithful(raw: pair.spoken, cleaned: pair.cleaned),
                    "example flagged as unfaithful: \(pair.spoken)")
        }
    }
}

@Suite("Cleanup script guard")
struct CleanupScriptGuardTests {

    @Test("foreign-script words in the output of a Latin dictation are unfaithful")
    func introducedHan() {
        let raw = "let's meet tomorrow at nine to go over the launch plan"
        let cleaned = "Let's meet tomorrow at nine 去讨论 the launch plan."
        #expect(CleanupGuard.introducedForeignScript(raw: raw, cleaned: cleaned))
        #expect(CleanupGuard.looksUnfaithful(raw: raw, cleaned: cleaned))
    }

    @Test("a script already present in the dictation is never flagged")
    func sameScriptPasses() {
        let raw = "今天天气很好我们去公园吧"
        let cleaned = "今天天气很好，我们去公园吧。"
        #expect(!CleanupGuard.introducedForeignScript(raw: raw, cleaned: cleaned))
    }

    @Test("latin insertions into CJK dictation are tolerated")
    func latinIntoCJKTolerated() {
        // Latin is deliberately not a guarded script: code and brand names
        // bleed into CJK dictation legitimately.
        #expect(!CleanupGuard.introducedForeignScript(
            raw: "请打开那个文件", cleaned: "请打开 main.py 那个文件"))
    }

    @Test("accents, emoji, and CJK punctuation alone do not trip the guard")
    func nonLetterNoise() {
        #expect(!CleanupGuard.introducedForeignScript(
            raw: "see you at the cafe", cleaned: "See you at the café 🎉。"))
    }

    @Test("cyrillic drift is caught too")
    func cyrillicDrift() {
        #expect(CleanupGuard.introducedForeignScript(
            raw: "send the report before lunch", cleaned: "Отправьте отчёт before lunch."))
    }
}
