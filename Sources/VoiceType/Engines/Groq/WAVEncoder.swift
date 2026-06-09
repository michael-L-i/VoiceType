import Foundation

/// Minimal in-memory WAV (RIFF/PCM) writer. Groq's audio endpoint accepts WAV;
/// rather than pull in AVFoundation just to serialize a file, we emit a tiny,
/// correct 16-bit PCM mono container ourselves.
///
/// Input is our pipeline currency — mono float samples in [-1, 1] — which we
/// clamp and scale to signed 16-bit little-endian. No user audio is ever logged.
enum WAVEncoder {

    /// Encode mono float samples into a 16-bit PCM WAV byte stream.
    /// - Parameters:
    ///   - samples: mono audio, nominally in [-1, 1] (clamped defensively).
    ///   - sampleRate: samples per second (e.g. 16_000).
    static func encodePCM16Mono(samples: [Float], sampleRate: Double) -> Data {
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let bytesPerSample = Int(bitsPerSample / 8)
        let rate = UInt32(max(1, sampleRate.rounded()))
        let byteRate = rate * UInt32(channels) * UInt32(bytesPerSample)
        let blockAlign = channels * UInt16(bytesPerSample)
        let dataSize = UInt32(samples.count * bytesPerSample)
        let riffSize = 36 + dataSize // 4 (WAVE) + 24 (fmt) + 8 (data hdr) + data

        var data = Data(capacity: Int(riffSize) + 8)

        // RIFF header
        data.append(ascii: "RIFF")
        data.append(le: riffSize)
        data.append(ascii: "WAVE")

        // fmt subchunk (PCM)
        data.append(ascii: "fmt ")
        data.append(le: UInt32(16))          // subchunk size for PCM
        data.append(le: UInt16(1))           // audio format = 1 (PCM)
        data.append(le: channels)
        data.append(le: rate)
        data.append(le: byteRate)
        data.append(le: blockAlign)
        data.append(le: bitsPerSample)

        // data subchunk
        data.append(ascii: "data")
        data.append(le: dataSize)

        // PCM samples: clamp to [-1, 1], scale to Int16.
        data.reserveCapacity(data.count + samples.count * bytesPerSample)
        for sample in samples {
            let clamped = max(-1, min(1, sample))
            // Scale by 32767 to keep within Int16 on the positive side.
            let value = Int16((clamped * 32767).rounded())
            data.append(le: UInt16(bitPattern: value))
        }

        return data
    }
}

// MARK: - Little-endian append helpers

private extension Data {
    mutating func append(ascii string: String) {
        append(contentsOf: string.utf8)
    }

    mutating func append(le value: UInt16) {
        var le = value.littleEndian
        Swift.withUnsafeBytes(of: &le) { append(contentsOf: $0) }
    }

    mutating func append(le value: UInt32) {
        var le = value.littleEndian
        Swift.withUnsafeBytes(of: &le) { append(contentsOf: $0) }
    }
}
