import Foundation
import AVFoundation
import VoiceTypeKit

/// Bridges our `PCMBuffer` to the 16 kHz mono `[Float]` the neural ASR SDKs
/// (FluidAudio / WhisperKit) expect. Mic capture is already 16 kHz, so this is a
/// no-op there; imported files at other rates are resampled.
enum AudioSamples {
    static func mono16k(_ audio: PCMBuffer) -> [Float] {
        if audio.sampleRate == 16_000 { return audio.samples }

        guard !audio.samples.isEmpty,
              let srcFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                            sampleRate: audio.sampleRate, channels: 1, interleaved: false),
              let dstFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                            sampleRate: 16_000, channels: 1, interleaved: false),
              let inBuffer = AVAudioPCMBuffer(pcmFormat: srcFormat,
                                              frameCapacity: AVAudioFrameCount(audio.samples.count)) else {
            return audio.samples
        }
        inBuffer.frameLength = AVAudioFrameCount(audio.samples.count)
        if let ch = inBuffer.floatChannelData {
            audio.samples.withUnsafeBufferPointer { src in
                if let base = src.baseAddress { ch[0].update(from: base, count: audio.samples.count) }
            }
        }

        guard let converter = AVAudioConverter(from: srcFormat, to: dstFormat) else { return audio.samples }
        let capacity = AVAudioFrameCount(Double(audio.samples.count) * 16_000 / audio.sampleRate) + 4096
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: dstFormat, frameCapacity: capacity) else { return audio.samples }

        var fed = false
        var error: NSError?
        _ = converter.convert(to: outBuffer, error: &error) { _, status in
            if fed { status.pointee = .endOfStream; return nil }
            fed = true; status.pointee = .haveData; return inBuffer
        }
        guard let ch = outBuffer.floatChannelData else { return audio.samples }
        return Array(UnsafeBufferPointer(start: ch[0], count: Int(outBuffer.frameLength)))
    }
}
