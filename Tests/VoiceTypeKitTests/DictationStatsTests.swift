import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Dictation stats — word counting")
struct WordCountTests {
    @Test("empty and whitespace count as zero")
    func empty() {
        #expect(DictationStats.wordCount("") == 0)
        #expect(DictationStats.wordCount("   \n\t ") == 0)
    }

    @Test("collapses runs of whitespace")
    func multiSpace() {
        #expect(DictationStats.wordCount("hello") == 1)
        #expect(DictationStats.wordCount("hello   world") == 2)
        #expect(DictationStats.wordCount(" leading and trailing ") == 3)
        #expect(DictationStats.wordCount("line one\nline two") == 4)
    }

    @Test("punctuation stays attached to its word")
    func punctuation() {
        #expect(DictationStats.wordCount("Hello, world!") == 2)
        #expect(DictationStats.wordCount("It's a test.") == 3)
    }
}

@Suite("Dictation stats — totals")
struct StatsTotalsTests {
    @Test("totals accumulate across sessions")
    func accumulate() {
        var stats = DictationStats()
        let day = Date(timeIntervalSince1970: 0)
        stats.record(words: 10, speakingTime: 5, on: day)
        stats.record(words: 5, speakingTime: 3, on: day)
        #expect(stats.totalWords == 15)
        #expect(stats.totalSpeakingTime == 8)
        #expect(stats.sessionCount == 2)
    }

    @Test("negative inputs are clamped to zero")
    func clampNegatives() {
        var stats = DictationStats()
        stats.record(words: -4, speakingTime: -2, on: Date(timeIntervalSince1970: 0))
        #expect(stats.totalWords == 0)
        #expect(stats.totalSpeakingTime == 0)
        #expect(stats.sessionCount == 1)
    }
}

@Suite("Dictation stats — words per minute")
struct StatsWPMTests {
    @Test("no speaking time yields zero")
    func zeroGuard() {
        #expect(DictationStats().averageWordsPerMinute == 0)
    }

    @Test("computes rounded lifetime average from totals")
    func average() {
        var stats = DictationStats()
        let day = Date(timeIntervalSince1970: 0)
        // 150 words over 60s = 150 wpm
        stats.record(words: 150, speakingTime: 60, on: day)
        #expect(stats.averageWordsPerMinute == 150)
        // + 30 words over 30s → 180 words / 90s = 120 wpm
        stats.record(words: 30, speakingTime: 30, on: day)
        #expect(stats.averageWordsPerMinute == 120)
    }
}
