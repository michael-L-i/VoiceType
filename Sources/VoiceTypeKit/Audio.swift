import Foundation

/// A buffer of mono PCM audio as 32-bit float samples in [-1, 1].
///
/// This is the single audio currency between the app's capture layer and any
/// `TranscriptionEngine`. Keeping it framework-free (no AVFoundation) is what
/// lets `VoiceTypeKit` stay pure and testable.
public struct PCMBuffer: Sendable, Equatable {
    /// Interleaved-not-applicable: always a single mono channel.
    public var samples: [Float]
    /// Samples per second (e.g. 16_000 for speech models).
    public var sampleRate: Double

    public init(samples: [Float], sampleRate: Double) {
        self.samples = samples
        self.sampleRate = sampleRate
    }

    /// Audio length in seconds.
    public var duration: TimeInterval {
        guard sampleRate > 0 else { return 0 }
        return Double(samples.count) / sampleRate
    }

    public var isEmpty: Bool { samples.isEmpty }

    /// Peak absolute amplitude — a cheap "did the user actually say anything"
    /// signal and the basis for a live input-level meter.
    public var peakAmplitude: Float {
        var peak: Float = 0
        for s in samples {
            let a = abs(s)
            if a > peak { peak = a }
        }
        return peak
    }

    /// Root-mean-square loudness over the buffer.
    public var rms: Float {
        guard !samples.isEmpty else { return 0 }
        var sum: Float = 0
        for s in samples { sum += s * s }
        return (sum / Float(samples.count)).squareRoot()
    }
}
