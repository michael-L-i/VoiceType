import Foundation

/// Splits a long recording into transcription-sized windows. The Apple batch
/// path degrades (and can run out of memory) on very long audio, so imported
/// files are chunked before transcription and the results joined.
///
/// Cuts are nudged to the quietest spot near each window boundary so we don't
/// slice through the middle of a word, and a small overlap is carried across so a
/// word straddling a boundary still lands in at least one chunk. Pure and
/// framework-free so the boundary logic is unit-tested.
public enum AudioChunker {
    /// Break `buffer` into windows of at most `maxSeconds`, preferring silent cut
    /// points within `silenceSearchSeconds` of each boundary and overlapping
    /// successive windows by `overlapSeconds`. Returns the buffer unchanged when
    /// it's already short enough.
    public static func chunk(_ buffer: PCMBuffer,
                             maxSeconds: TimeInterval = 120,
                             overlapSeconds: TimeInterval = 0.5,
                             silenceSearchSeconds: TimeInterval = 1.0,
                             windowSeconds: TimeInterval = 0.1) -> [PCMBuffer] {
        let rate = buffer.sampleRate
        guard rate > 0, maxSeconds > 0 else { return buffer.isEmpty ? [] : [buffer] }

        let samples = buffer.samples
        let maxSamples = Int(maxSeconds * rate)
        guard samples.count > maxSamples else { return buffer.isEmpty ? [] : [buffer] }

        let overlap = max(0, Int(overlapSeconds * rate))
        let band = max(1, Int(silenceSearchSeconds * rate))
        let win = max(1, Int(windowSeconds * rate))

        var chunks: [PCMBuffer] = []
        var start = 0
        while start < samples.count {
            let nominalEnd = start + maxSamples
            if nominalEnd >= samples.count {
                chunks.append(PCMBuffer(samples: Array(samples[start...]), sampleRate: rate))
                break
            }

            // Slide a small window across the search band before the boundary and
            // cut at the centre of the quietest one.
            let bandStart = max(start + 1, nominalEnd - band)
            var cut = nominalEnd
            var minEnergy = Float.greatestFiniteMagnitude
            var i = bandStart
            while i + win <= nominalEnd {
                var energy: Float = 0
                for j in i..<(i + win) { energy += abs(samples[j]) }
                if energy < minEnergy {
                    minEnergy = energy
                    cut = i + win / 2
                }
                i += win
            }

            chunks.append(PCMBuffer(samples: Array(samples[start..<cut]), sampleRate: rate))
            let next = cut - overlap
            start = next > start ? next : cut          // always make progress
        }
        return chunks
    }
}
