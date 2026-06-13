import AVFoundation
import VoiceTypeKit

/// Captures microphone audio while push-to-talk is held, then hands back a
/// mono 16 kHz Float `PCMBuffer` — the format every transcription engine wants.
///
/// We accumulate the input node's native float samples on the realtime tap
/// thread (guarded by a lock) and resample once at stop, keeping the hot path
/// cheap. Audio never leaves this object except as the in-memory buffer the
/// pipeline consumes; nothing is written to disk.
final class AudioCaptureService {
    /// Target sample rate for speech models.
    static let targetSampleRate: Double = 16_000

    private let engine = AVAudioEngine()
    private let lock = NSLock()
    private var nativeSamples: [Float] = []
    private var nativeSampleRate: Double = 48_000
    private(set) var isRunning = false
    private var configurationObserver: NSObjectProtocol?

    /// Live input level (0...1), published on the main actor for the UI meter.
    var onLevel: (@Sendable (Float) -> Void)?
    var onConfigurationChange: (@Sendable () -> Void)?

    init() {
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main) { [weak self] _ in
                self?.handleConfigurationChange()
            }
    }

    deinit {
        if let configurationObserver {
            NotificationCenter.default.removeObserver(configurationObserver)
        }
    }

    func start() throws {
        guard !isRunning else { return }
        lock.lock(); nativeSamples.removeAll(keepingCapacity: true); lock.unlock()

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        nativeSampleRate = format.sampleRate

        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            self?.append(buffer)
        }
        engine.prepare()
        try engine.start()
        isRunning = true
        Log.audio.info("capture started @ \(self.nativeSampleRate, privacy: .public)Hz")
    }

    /// Stop capture and return the resampled mono 16 kHz buffer.
    func stop() -> PCMBuffer {
        guard isRunning else { return PCMBuffer(samples: [], sampleRate: Self.targetSampleRate) }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false

        lock.lock()
        let samples = nativeSamples
        let rate = nativeSampleRate
        nativeSamples.removeAll(keepingCapacity: false)
        lock.unlock()

        let resampled = Self.resampleToTarget(samples, from: rate)
        Log.audio.info("capture stopped: \(resampled.count, privacy: .public) samples")
        return PCMBuffer(samples: resampled, sampleRate: Self.targetSampleRate)
    }

    /// Abort the current recording without returning audio. Used when the audio
    /// hardware graph changes under us, e.g. AirPods reconnecting mid-capture.
    func cancel() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false

        lock.lock()
        nativeSamples.removeAll(keepingCapacity: false)
        lock.unlock()

        onLevel?(0)
        Log.audio.info("capture cancelled")
    }

    private func handleConfigurationChange() {
        guard isRunning else { return }
        Log.audio.info("audio configuration changed while capturing")
        cancel()
        onConfigurationChange?()
    }

    // MARK: - Realtime tap

    private func append(_ buffer: AVAudioPCMBuffer) {
        guard let channel = buffer.floatChannelData else { return }
        let frames = Int(buffer.frameLength)
        // Downmix to mono by taking the first channel — laptop/USB mics are
        // effectively mono and this avoids per-frame averaging on the hot path.
        let ptr = channel[0]
        var chunk = [Float](repeating: 0, count: frames)
        for i in 0..<frames { chunk[i] = ptr[i] }

        // Cheap level meter off the same chunk.
        if let onLevel {
            var peak: Float = 0
            for v in chunk { let a = abs(v); if a > peak { peak = a } }
            onLevel(min(1, peak))
        }

        lock.lock()
        nativeSamples.append(contentsOf: chunk)
        lock.unlock()
    }

    // MARK: - Resampling

    /// Resample mono float samples to 16 kHz using AVAudioConverter for quality.
    /// Falls back to returning the input unchanged if conversion can't be set up.
    static func resampleToTarget(_ samples: [Float], from sourceRate: Double) -> [Float] {
        guard !samples.isEmpty else { return [] }
        if abs(sourceRate - targetSampleRate) < 1 { return samples }

        guard let srcFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                            sampleRate: sourceRate, channels: 1, interleaved: false),
              let dstFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                            sampleRate: targetSampleRate, channels: 1, interleaved: false),
              let converter = AVAudioConverter(from: srcFormat, to: dstFormat),
              let srcBuffer = AVAudioPCMBuffer(pcmFormat: srcFormat,
                                               frameCapacity: AVAudioFrameCount(samples.count)) else {
            return samples
        }

        srcBuffer.frameLength = AVAudioFrameCount(samples.count)
        if let dst = srcBuffer.floatChannelData {
            samples.withUnsafeBufferPointer { src in
                dst[0].update(from: src.baseAddress!, count: samples.count)
            }
        }

        let ratio = targetSampleRate / sourceRate
        let capacity = AVAudioFrameCount(Double(samples.count) * ratio) + 1024
        guard let dstBuffer = AVAudioPCMBuffer(pcmFormat: dstFormat, frameCapacity: capacity) else {
            return samples
        }

        var fed = false
        var error: NSError?
        let status = converter.convert(to: dstBuffer, error: &error) { _, outStatus in
            if fed {
                outStatus.pointee = .endOfStream
                return nil
            }
            fed = true
            outStatus.pointee = .haveData
            return srcBuffer
        }

        guard status != .error, let out = dstBuffer.floatChannelData else { return samples }
        let count = Int(dstBuffer.frameLength)
        return Array(UnsafeBufferPointer(start: out[0], count: count))
    }
}
