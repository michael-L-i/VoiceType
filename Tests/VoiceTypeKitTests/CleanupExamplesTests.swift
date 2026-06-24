import Testing
@testable import VoiceTypeKit

@Suite("Cleanup few-shot examples")
struct CleanupExamplesTests {
    @Test("set is non-empty and every pair is well-formed")
    func wellFormed() {
        let pairs = CleanupExamples.fewShot
        #expect(!pairs.isEmpty)
        for pair in pairs {
            #expect(!pair.spoken.trimmingCharacters(in: .whitespaces).isEmpty)
            #expect(!pair.cleaned.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    @Test("teaches compact file-name rendering")
    func fileNameRendering() {
        #expect(CleanupExamples.fewShot.contains { $0.cleaned.contains("app.py") })
    }

    @Test("teaches self-correction resolution")
    func selfCorrection() {
        // "two, no three" must collapse to just "three".
        let pair = CleanupExamples.fewShot.first { $0.spoken.contains("two, no three") }
        #expect(pair != nil)
        #expect(pair?.cleaned == "I want three")
    }

    @Test("includes a prose guard so triggers in prose stay prose")
    func proseGuard() {
        // "dot product" must survive as prose, never collapse to "the.product".
        let pair = CleanupExamples.fewShot.first { $0.spoken.contains("dot product") }
        #expect(pair != nil)
        #expect(pair?.cleaned.contains("dot product") == true)
        #expect(pair?.cleaned.contains(".product") == false)
    }

    @Test("rendered block lists every pair with an arrow")
    func blockFormat() {
        let block = CleanupExamples.block()
        let lines = block.split(separator: "\n")
        #expect(lines.count == CleanupExamples.fewShot.count)
        #expect(lines.allSatisfy { $0.contains("→") })
    }
}
