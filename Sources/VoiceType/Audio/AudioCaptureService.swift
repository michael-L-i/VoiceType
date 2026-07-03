import AVFoundation
import CoreMedia
import VoiceTypeKit

/// Captures microphone audio while push-to-talk is held, then hands back a
/// mono 16 kHz Float `PCMBuffer` — the format every transcription engine wants.
///
/// Built on **AVCaptureSession + AVCaptureAudioDataOutput**, not AVAudioEngine.
/// The distinction matters: AVAudioEngine compiles a DSP graph against one
/// device's exact hardware format, and any route change (AirPods connecting,
/// the A2DP→HFP profile flip that *starting the mic itself* triggers on
/// Bluetooth headsets) invalidates the graph and kills the recording. A capture
/// session instead owns device management and format conversion internally —
/// we declare the output format we want and buffers keep flowing across route
/// churn.
///
/// `start()` is asynchronous and never blocks the caller: hardware spin-up
/// (seconds on Bluetooth) happens on a private session queue, so the hotkey
/// event-tap callback and the UI stay responsive. `stop()`/`cancel()` return
/// immediately as well. Audio never leaves this object except as the in-memory
/// buffer the pipeline consumes; nothing is written to disk.
final class AudioCaptureService: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    /// Target sample rate for speech models.
    static let targetSampleRate: Double = 16_000

    private let session = AVCaptureSession()
    private let output = AVCaptureAudioDataOutput()
    /// Serializes all session mutations (configure/start/stop) off the caller.
    private let sessionQueue = DispatchQueue(label: "com.voicetype.app.capture.session")
    /// Delivery queue for sample buffers.
    private let sampleQueue = DispatchQueue(label: "com.voicetype.app.capture.samples")

    private let lock = NSLock()
    private var samples: [Float] = []
    /// Lock-guarded gate: the delegate appends only while true, so buffers that
    /// straggle in after stop()/cancel() can't leak into the next recording.
    private var accumulating = false

    /// Main-thread view of "a capture is in flight" (set in start, cleared in
    /// stop/cancel). All public methods are called from the main actor.
    private(set) var isRunning = false

    private var runtimeErrorObserver: NSObjectProtocol?

    /// Watchdog state: `bufferTick` (lock-guarded) advances on every captured
    /// buffer; the watchdog fires if it hasn't moved since the last check.
    /// Covers every "recording but no audio is arriving" state — missing
    /// device, session failure, dead input — with one detector.
    private var watchdog: Timer?
    private var bufferTick = 0
    private var watchdogBaseline = 0
    private static let watchdogInterval: TimeInterval = 2.5

    /// Live input level (0...1), published on the main actor for the UI meter.
    var onLevel: (@Sendable (Float) -> Void)?
    /// Capture died mid-flight (device vanished, session error, no buffers).
    /// Fired on the main queue after the capture has already been cancelled.
    var onConfigurationChange: (@Sendable () -> Void)?
    /// Capture could not start at all (no input device / setup failure).
    /// Fired on the main queue; the capture is already torn down.
    var onStartFailure: (@Sendable () -> Void)?

    override init() {
        super.init()

        // Ask the output for exactly the format the pipeline wants; the session
        // converts from whatever the hardware produces, on every device. This
        // replaces a hand-rolled accumulate-native-then-resample pass — and is
        // what makes mid-capture format changes a non-event.
        output.audioSettings = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: Self.targetSampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ]
        output.setSampleBufferDelegate(self, queue: sampleQueue)
        if session.canAddOutput(output) { session.addOutput(output) }

        runtimeErrorObserver = NotificationCenter.default.addObserver(
            forName: AVCaptureSession.runtimeErrorNotification,
            object: session,
            queue: .main) { [weak self] note in
                guard let self, self.isRunning else { return }
                let error = note.userInfo?[AVCaptureSessionErrorKey] as? NSError
                Log.audio.error("capture session runtime error: \(error?.localizedDescription ?? "unknown", privacy: .public)")
                self.cancel()
                self.onConfigurationChange?()
            }
    }

    deinit {
        if let runtimeErrorObserver {
            NotificationCenter.default.removeObserver(runtimeErrorObserver)
        }
    }

    /// Begin capturing. Returns immediately; hardware spin-up happens on the
    /// session queue. If the session can't start, `onStartFailure` fires (and
    /// the buffer watchdog backstops anything that fails silently).
    func start() {
        guard !isRunning else { return }
        lock.lock()
        samples.removeAll(keepingCapacity: true)
        accumulating = true
        lock.unlock()
        isRunning = true
        startWatchdog()

        sessionQueue.async { [weak self] in
            guard let self else { return }
            do {
                try self.configureInput()
                if !self.session.isRunning { self.session.startRunning() }
                Log.audio.info("capture session started")
            } catch {
                Log.audio.error("capture start failed: \(error.localizedDescription, privacy: .public)")
                DispatchQueue.main.async {
                    guard self.isRunning else { return }
                    self.cancel()
                    self.onStartFailure?()
                }
            }
        }
    }

    /// Point the session at the current default input. Re-resolved on every
    /// start so we follow the device the user expects; once capturing, the
    /// session keeps its device regardless of later default-input changes.
    private func configureInput() throws {
        enum SetupError: Error { case noInputAvailable }

        let current = session.inputs.compactMap { $0 as? AVCaptureDeviceInput }
        guard let device = AVCaptureDevice.default(for: .audio) else {
            throw SetupError.noInputAvailable
        }
        if current.count == 1, current[0].device.uniqueID == device.uniqueID { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }
        current.forEach { session.removeInput($0) }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw SetupError.noInputAvailable }
        session.addInput(input)
    }

    /// Stop capture and return the accumulated mono 16 kHz buffer. Returns
    /// immediately — session teardown happens on the session queue.
    func stop() -> PCMBuffer {
        guard isRunning else { return PCMBuffer(samples: [], sampleRate: Self.targetSampleRate) }
        stopWatchdog()
        isRunning = false

        lock.lock()
        accumulating = false
        let captured = samples
        samples.removeAll(keepingCapacity: false)
        lock.unlock()

        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }

        Log.audio.info("capture stopped: \(captured.count, privacy: .public) samples")
        return PCMBuffer(samples: captured, sampleRate: Self.targetSampleRate)
    }

    /// Abort the current recording without returning audio.
    func cancel() {
        guard isRunning else { return }
        stopWatchdog()
        isRunning = false

        lock.lock()
        accumulating = false
        samples.removeAll(keepingCapacity: false)
        lock.unlock()

        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }

        onLevel?(0)
        Log.audio.info("capture cancelled")
    }

    // MARK: - Watchdog

    /// Catch a "recording but no audio is arriving" state — a dead input that
    /// would otherwise leave the HUD spinning forever. If no buffers land within
    /// `watchdogInterval`, abort and surface it through the same recovery path
    /// as a runtime error (resets the UI to idle).
    private func startWatchdog() {
        lock.lock(); watchdogBaseline = bufferTick; lock.unlock()
        watchdog?.invalidate()
        watchdog = Timer.scheduledTimer(withTimeInterval: Self.watchdogInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.lock.lock()
            let current = self.bufferTick
            let baseline = self.watchdogBaseline
            self.watchdogBaseline = current
            self.lock.unlock()
            guard self.isRunning, current == baseline else { return }
            Log.audio.error("no audio buffers received; aborting capture")
            self.cancel()
            self.onConfigurationChange?()
        }
    }

    private func stopWatchdog() {
        watchdog?.invalidate()
        watchdog = nil
    }

    // MARK: - Sample delivery

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        var bufferList = AudioBufferList()
        var blockBuffer: CMBlockBuffer?
        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &bufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer)
        guard status == noErr, blockBuffer != nil,
              let data = bufferList.mBuffers.mData else { return }

        // Mono float32 per `audioSettings` — one buffer, 4 bytes per frame.
        let frames = Int(bufferList.mBuffers.mDataByteSize) / MemoryLayout<Float>.size
        guard frames > 0 else { return }
        let ptr = data.assumingMemoryBound(to: Float.self)
        let chunk = Array(UnsafeBufferPointer(start: ptr, count: frames))

        // Cheap level meter off the same chunk.
        if let onLevel {
            var peak: Float = 0
            for v in chunk { let a = abs(v); if a > peak { peak = a } }
            onLevel(min(1, peak))
        }

        lock.lock()
        if accumulating { samples.append(contentsOf: chunk) }
        bufferTick &+= 1
        lock.unlock()
    }

    // MARK: - Resampling

    /// Resample mono float samples to 16 kHz using AVAudioConverter for quality.
    /// Falls back to returning the input unchanged if conversion can't be set up.
    /// (Live capture no longer needs this — the session converts — but the file
    /// import decoder still does.)
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
