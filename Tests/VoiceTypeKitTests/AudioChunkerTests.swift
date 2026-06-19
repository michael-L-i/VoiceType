import Testing
import Foundation
@testable import VoiceTypeKit

@Suite("Audio chunker")
struct AudioChunkerTests {
    @Test("short audio is returned as a single chunk")
    func short() {
        let buf = PCMBuffer(samples: Array(repeating: 0.5, count: 50), sampleRate: 10)  // 5s
        let chunks = AudioChunker.chunk(buf, maxSeconds: 10)
        #expect(chunks.count == 1)
        #expect(chunks.first?.samples.count == 50)
    }

    @Test("empty audio yields no chunks")
    func empty() {
        #expect(AudioChunker.chunk(PCMBuffer(samples: [], sampleRate: 10)).isEmpty)
    }

    @Test("long audio splits into multiple windows that cover everything")
    func splits() {
        // 100 samples at 10 Hz = 10s; max 2s (20 samples), no overlap → ~5 chunks.
        let buf = PCMBuffer(samples: Array(repeating: 0.5, count: 100), sampleRate: 10)
        let chunks = AudioChunker.chunk(buf, maxSeconds: 2, overlapSeconds: 0, silenceSearchSeconds: 0.1)
        #expect(chunks.count >= 4)
        // Each chunk respects the max window (allowing the silence-search slack).
        #expect(chunks.allSatisfy { $0.samples.count <= 20 })
        // With no overlap, concatenation reproduces the whole signal.
        let total = chunks.reduce(0) { $0 + $1.samples.count }
        #expect(total == 100)
    }

    @Test("overlap makes successive chunks share samples (total exceeds original)")
    func overlap() {
        let buf = PCMBuffer(samples: Array(repeating: 0.5, count: 100), sampleRate: 10)
        let chunks = AudioChunker.chunk(buf, maxSeconds: 2, overlapSeconds: 0.5, silenceSearchSeconds: 0.1)
        let total = chunks.reduce(0) { $0 + $1.samples.count }
        #expect(total > 100)
    }

    @Test("cuts are nudged into a silent gap near the boundary")
    func silenceAware() {
        // 60 loud samples at 10 Hz, max 3s (30 samples). Punch a silent gap just
        // before the boundary at indices 24–27; the cut should land in it.
        var samples = Array(repeating: Float(1.0), count: 60)
        for i in 24..<28 { samples[i] = 0 }
        let buf = PCMBuffer(samples: samples, sampleRate: 10)
        let chunks = AudioChunker.chunk(buf, maxSeconds: 3, overlapSeconds: 0,
                                        silenceSearchSeconds: 1.0, windowSeconds: 0.1)
        let firstLen = chunks.first!.samples.count
        #expect(firstLen >= 24 && firstLen <= 28)   // cut inside the silent gap, not at 30
    }
}
