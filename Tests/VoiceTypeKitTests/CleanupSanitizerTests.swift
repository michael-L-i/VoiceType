import Testing
@testable import VoiceTypeKit

@Suite("Cleanup sanitizer — strip conversational wrappers")
struct CleanupSanitizerTests {
    @Test("strips an opener-led lead-in and the wrapping quotes (the real bug)")
    func realWorldFailure() {
        let bad = """
        Sure, here's the cleaned transcript:

        "Can you clean up the table, then push it to michael-L-i's profile page."
        """
        let out = CleanupSanitizer.strip(bad)
        #expect(out == "Can you clean up the table, then push it to michael-L-i's profile page.")
    }

    @Test("strips a transcript-named lead-in without an opener")
    func transcriptNamedLeadIn() {
        let out = CleanupSanitizer.strip("Here's the cleaned transcript: hello world.")
        #expect(out == "hello world.")
    }

    @Test("strips wrapping double quotes around the whole output")
    func wrappingQuotes() {
        #expect(CleanupSanitizer.strip("\"hello world\"") == "hello world")
        #expect(CleanupSanitizer.strip("“hello world”") == "hello world")
    }

    @Test("leaves clean output untouched")
    func cleanPassthrough() {
        let s = "Open app.py and fix the parser."
        #expect(CleanupSanitizer.strip(s) == s)
    }

    @Test("does NOT strip legitimate prose that starts with 'Here is …:'")
    func proseColonGuard() {
        // No opener, no transcript-noun → must be preserved verbatim.
        let s = "Here is my plan: buy milk and eggs."
        #expect(CleanupSanitizer.strip(s) == s)
    }

    @Test("does NOT strip quotes when the inner text also contains a quote")
    func unbalancedQuoteGuard() {
        let s = "\"she said \"hi\" to me\""
        #expect(CleanupSanitizer.strip(s) == s)
    }

    @Test("never strips down to empty")
    func neverEmpties() {
        // A lead-in with nothing after it stays as-is rather than vanishing.
        let s = "Here's the cleaned transcript:"
        #expect(!CleanupSanitizer.strip(s).isEmpty)
    }

    @Test("leaves single-quoted / apostrophe text alone")
    func singleQuotesUntouched() {
        let s = "it's a test"
        #expect(CleanupSanitizer.strip(s) == s)
    }
}
