import AVFoundation
import CoreAudio
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
/// That gets us most of the way, but not all of it, because a Bluetooth headset
/// is not one stable device:
///
/// - **It takes its time.** Opening the mic on AirPods makes macOS renegotiate
///   the link from the music profile to the call profile; the first sample
///   buffer can be a second or two behind `startRunning()`. So the session is
///   configured for the current input *ahead of time* (`prewarm()`, re-run
///   whenever the default input changes) — no hardware is started, but the
///   expensive setup is already done when the hotkey lands.
/// - **It can die mid-sentence, silently.** That same renegotiation can
///   invalidate the device object the session opened. Buffers just stop; no
///   error is posted. So capture is watched (`CaptureHealthMonitor`) and a
///   stall **rebuilds the input in place, keeping the audio recorded so far** —
///   the user loses a gap, not the utterance. Only a mic that fails repeatedly
///   gives up.
///
/// `start()` is asynchronous and never blocks the caller: hardware spin-up
/// happens on a private session queue, so the hotkey event-tap callback and the
/// UI stay responsive. `stop()`/`cancel()` return immediately as well. Audio
/// never leaves this object except as the in-memory buffer the pipeline
/// consumes; nothing is written to disk.
final class AudioCaptureService: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    /// Target sample rate for speech models.
    static let targetSampleRate: Double = 16_000

    /// How long the mic keeps running after the user ends a dictation.
    ///
    /// Ending capture the instant the key is hit throws away real speech, from
    /// two directions at once:
    ///
    /// 1. **Delivery latency.** A capture session hands us audio in packets,
    ///    behind the hardware. Audio the mic had already digitized at the moment
    ///    of the keystroke has not reached our delegate yet — tens of ms on the
    ///    built-in mic, considerably more over Bluetooth — and a snapshot taken
    ///    right then simply doesn't contain it.
    /// 2. **Human timing.** People start reaching for the key while finishing
    ///    the last word, so the end of the final phrase lands *after* the press.
    ///
    /// Either way the tail arrives clipped, and a clipped final word is worse
    /// than a missing one: the recognizer usually drops the whole trailing
    /// clause rather than emitting a fragment. The grace costs this much added
    /// time-to-text and buys back words the user actually said.
    static let tailGrace: TimeInterval = 0.3

    /// How often capture health is evaluated. Well under the shortest threshold
    /// in `CaptureHealthPolicy`, so detection latency is the policy's, not the
    /// timer's.
    private static let healthTick: TimeInterval = 0.25

    /// How long the system may hold the mic away from us before we call the
    /// recording lost. An interruption is someone else taking the device; it
    /// usually ends in well under a second, and a recording nobody is speaking
    /// into is worse than an honest error.
    private static let maxInterruption: TimeInterval = 5.0

    private let session = AVCaptureSession()
    private let output = AVCaptureAudioDataOutput()
    /// Serializes all session mutations (configure/start/stop) off the caller.
    private let sessionQueue = DispatchQueue(label: "com.voicetype.app.capture.session")
    /// Delivery queue for sample buffers.
    private let sampleQueue = DispatchQueue(label: "com.voicetype.app.capture.samples")
    /// Health ticks live on their own queue so they keep firing while the
    /// session queue is blocked inside a multi-second Bluetooth `startRunning()`
    /// — which is exactly when we most need to be watching.
    private let healthQueue = DispatchQueue(label: "com.voicetype.app.capture.health")

    private let lock = NSLock()
    private var samples: [Float] = []
    /// Lock-guarded gate: the delegate appends only while true, so buffers that
    /// straggle in after stop()/cancel() can't leak into the next recording.
    private var accumulating = false
    /// Lock-guarded mirror of `isRunning`, readable from the health timer and
    /// the sample queue.
    private var active = false
    /// Lock-guarded health state; nil while no capture is in flight.
    private var health: CaptureHealthMonitor?
    /// Lock-guarded: set while a rebuild is queued or running, so a burst of
    /// ticks can't stack up several rebuilds for one stall.
    private var recoveryInFlight = false
    /// Lock-guarded start of the current capture-session interruption, if any.
    private var interruptedSince: TimeInterval?
    /// Lock-guarded unique ID of the device the session is currently built on.
    private var configuredDeviceUID: String?

    /// Main-thread view of "a capture is in flight" (set in start, cleared in
    /// stop/cancel). All public methods are called from the main actor.
    private(set) var isRunning = false

    private var notificationObservers: [NSObjectProtocol] = []
    private var healthTimer: DispatchSourceTimer?
    /// Registered against the CoreAudio system object; see `observeDefaultInput`.
    private var defaultInputListener: AudioObjectPropertyListenerBlock?

    /// Live input level (0...1), published on the main actor for the UI meter.
    var onLevel: (@Sendable (Float) -> Void)?
    /// Capture died mid-flight and could not be rebuilt. Fired on the main
    /// queue after the capture has already been cancelled.
    var onConfigurationChange: (@Sendable () -> Void)?
    /// Capture could not start at all (no input device / setup failure).
    /// Fired on the main queue; the capture is already torn down.
    var onStartFailure: (@Sendable () -> Void)?

    /// The monotonic clock the health monitor is measured on. `systemUptime`
    /// excludes time the machine spent asleep, which is what we want: a lid
    /// closed mid-recording shouldn't read as a stalled mic.
    private var now: TimeInterval { ProcessInfo.processInfo.systemUptime }

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

        observeSession()
        observeDevices()
        observeDefaultInput()
        prewarm()
    }

    deinit {
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        healthTimer?.cancel()
        removeDefaultInputListener()
    }

    // MARK: - Observation

    private func observeSession() {
        let center = NotificationCenter.default

        notificationObservers.append(center.addObserver(
            forName: AVCaptureSession.runtimeErrorNotification,
            object: session,
            queue: .main) { [weak self] note in
                guard let self, self.isRunning else { return }
                let error = note.userInfo?[AVCaptureSessionErrorKey] as? NSError
                Log.audio.error("capture session runtime error: \(error?.localizedDescription ?? "unknown", privacy: .public)")
                // A runtime error is recoverable often enough to be worth one
                // rebuild — a Bluetooth mic vanishing mid-flip lands here.
                self.requestRecovery(reason: "runtime error")
            })

        // Someone else took the audio device (a call, another capture client).
        // The session stops itself; the health monitor must not read that as a
        // dead mic, and we restart when the system hands it back.
        notificationObservers.append(center.addObserver(
            forName: AVCaptureSession.wasInterruptedNotification,
            object: session,
            queue: .main) { [weak self] _ in
                guard let self else { return }
                self.lock.withLock { if self.interruptedSince == nil { self.interruptedSince = self.now } }
                Log.audio.info("capture session interrupted")
            })

        notificationObservers.append(center.addObserver(
            forName: AVCaptureSession.interruptionEndedNotification,
            object: session,
            queue: .main) { [weak self] _ in
                guard let self else { return }
                let wasRunning: Bool = self.lock.withLock {
                    self.interruptedSince = nil
                    self.health?.noteResumed(at: self.now)
                    return self.active
                }
                Log.audio.info("capture session interruption ended")
                guard wasRunning else { return }
                self.sessionQueue.async { [weak self] in
                    guard let self, self.lock.withLock({ self.active }), !self.session.isRunning else { return }
                    self.session.startRunning()
                }
            })
    }

    private func observeDevices() {
        let center = NotificationCenter.default

        // The device we are recording from went away. Don't wait for the stall
        // timeout — rebuild onto whatever the system now considers the input.
        notificationObservers.append(center.addObserver(
            forName: AVCaptureDevice.wasDisconnectedNotification,
            object: nil,
            queue: .main) { [weak self] note in
                guard let self, let device = note.object as? AVCaptureDevice else { return }
                guard self.lock.withLock({ self.configuredDeviceUID }) == device.uniqueID else { return }
                Log.audio.info("active input device disconnected")
                if self.isRunning {
                    self.requestRecovery(reason: "device disconnected")
                } else {
                    self.prewarm()
                }
            })

        // A headset paired: get the session configured for it now, so the first
        // dictation afterwards doesn't pay the setup cost mid-utterance.
        notificationObservers.append(center.addObserver(
            forName: AVCaptureDevice.wasConnectedNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.prewarm()
            })
    }

    /// Follow the *default input*, which is the device we actually resolve at
    /// `start()`. Connecting AirPods flips it a moment after the device itself
    /// appears, so the connect notification alone would prewarm the wrong mic.
    private func observeDefaultInput() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            guard let self else { return }
            // Mid-capture we deliberately stay on the device we opened: the user
            // is speaking into it, and following a default change would swap
            // mics mid-sentence. A dead device is the disconnect/stall path.
            guard !self.lock.withLock({ self.active }) else { return }
            self.prewarm()
        }
        let status = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &address, sessionQueue, listener)
        if status == noErr {
            defaultInputListener = listener
        } else {
            Log.audio.error("default-input listener failed: \(status, privacy: .public)")
        }
    }

    private func removeDefaultInputListener() {
        guard let defaultInputListener else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &address, sessionQueue, defaultInputListener)
        self.defaultInputListener = nil
    }

    // MARK: - Lifecycle

    /// Configure the session for the current default input **without starting
    /// any hardware**, so `start()` has little left to do.
    ///
    /// Resolving the device and building an `AVCaptureDeviceInput` for it is
    /// work that has to happen before a single sample can arrive; doing it when
    /// the headset appears instead of when the user starts talking takes it off
    /// the critical path. It is not the whole Bluetooth delay — the link
    /// negotiation inside `startRunning()` can't be paid in advance without
    /// holding the mic open, which we won't do — but it is the part we can
    /// remove for free.
    ///
    /// Nothing is started and nothing is captured: no recording indicator
    /// appears, and the session stays idle until `start()`.
    ///
    /// Cheap and idempotent — safe to call on every device notification.
    func prewarm() {
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else { return }
        sessionQueue.async { [weak self] in
            guard let self, !self.lock.withLock({ self.active }) else { return }
            do {
                try self.configureInput()
            } catch {
                // Nothing to report: this is speculative work, and `start()`
                // surfaces a real failure if the device is still unusable then.
                Log.audio.debug("prewarm skipped: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Begin capturing. Returns immediately; hardware spin-up happens on the
    /// session queue. If the session can't start, `onStartFailure` fires (and
    /// the health monitor backstops anything that fails silently).
    func start() {
        guard !isRunning else { return }
        lock.withLock {
            samples.removeAll(keepingCapacity: true)
            accumulating = true
            active = true
            recoveryInFlight = false
            interruptedSince = nil
            health = CaptureHealthMonitor(startedAt: now)
        }
        isRunning = true
        startHealthTimer()

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

    enum SetupError: Error { case noInputAvailable }

    /// Point the session at the current default input. Re-resolved on every
    /// start so we follow the device the user expects; once capturing, the
    /// session keeps its device regardless of later default-input changes.
    ///
    /// - Parameter force: rebuild even if the resolved device looks like the one
    ///   already installed. A Bluetooth headset changing profile is re-created
    ///   underneath the same unique ID, so after a stall "same ID" says nothing
    ///   about whether the input we hold is still alive.
    ///
    /// Must be called on `sessionQueue`.
    private func configureInput(force: Bool = false) throws {
        let current = session.inputs.compactMap { $0 as? AVCaptureDeviceInput }
        guard let device = AVCaptureDevice.default(for: .audio) else {
            throw SetupError.noInputAvailable
        }
        if !force, current.count == 1, current[0].device.uniqueID == device.uniqueID { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }
        current.forEach { session.removeInput($0) }
        lock.withLock { configuredDeviceUID = nil }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw SetupError.noInputAvailable }
        session.addInput(input)
        lock.withLock { configuredDeviceUID = device.uniqueID }
        Log.audio.info("capture input configured\(force ? " (rebuilt)" : "", privacy: .public)")
    }

    /// Stop capture and return the accumulated mono 16 kHz buffer.
    ///
    /// Suspends for `tailGrace` first so the end of the utterance actually makes
    /// it into the buffer (see the constant). The capture stays live and
    /// cancellable across that window; session teardown then happens on the
    /// session queue, so this still never blocks on hardware.
    func stop() async -> PCMBuffer {
        guard isRunning else { return PCMBuffer(samples: [], sampleRate: Self.targetSampleRate) }
        // The health monitor has done its job: silence it before the grace
        // window so a recording that ends on a quiet tail can't be read as a
        // dead input and rebuilt out from under us.
        stopHealthTimer()

        // Deliberately still `isRunning`: capture really is live here, and
        // Escape must be able to abort it out from under us.
        try? await Task.sleep(nanoseconds: UInt64(Self.tailGrace * 1_000_000_000))
        guard isRunning else {
            // cancel() won the race and already tore the capture down.
            return PCMBuffer(samples: [], sampleRate: Self.targetSampleRate)
        }
        isRunning = false

        // Barrier on the delivery queue: every buffer the session has already
        // handed off is appended before we read `samples`. Without it, audio
        // in flight on that queue is lost to scheduling luck alone.
        sampleQueue.sync {}

        // Scoped locking: `lock()`/`unlock()` are unavailable from an async
        // context (a suspension between them would be a deadlock waiting to
        // happen), and this method now has one.
        let captured: [Float] = lock.withLock {
            accumulating = false
            active = false
            health = nil
            defer { samples.removeAll(keepingCapacity: false) }
            return samples
        }

        tearDownSession()
        onLevel?(0)
        Log.audio.info("capture stopped: \(captured.count, privacy: .public) samples")
        return PCMBuffer(samples: captured, sampleRate: Self.targetSampleRate)
    }

    /// Abort the current recording without returning audio.
    func cancel() {
        guard isRunning else { return }
        stopHealthTimer()
        isRunning = false

        lock.withLock {
            accumulating = false
            active = false
            health = nil
            samples.removeAll(keepingCapacity: false)
        }

        tearDownSession()
        onLevel?(0)
        Log.audio.info("capture cancelled")
    }

    /// Hand session teardown to the session queue. Kept out of `stop()` so the
    /// escaping closure is formed in a synchronous context — from an async one
    /// it captures a non-Sendable `self` and trips concurrency checking.
    private func tearDownSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
            // Leave the input installed: it is exactly the prewarmed state the
            // next dictation wants, and re-resolving happens at `start()`.
        }
    }

    // MARK: - Health

    /// Watch for "recording, but no audio is arriving" — the failure mode a
    /// Bluetooth mic produces most, and the one that used to leave the HUD
    /// listening to nothing. Verdicts come from `CaptureHealthMonitor`; this
    /// just supplies the clock and carries them out.
    private func startHealthTimer() {
        healthTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: healthQueue)
        timer.schedule(deadline: .now() + Self.healthTick, repeating: Self.healthTick)
        timer.setEventHandler { [weak self] in self?.checkHealth() }
        timer.resume()
        healthTimer = timer
    }

    private func stopHealthTimer() {
        healthTimer?.cancel()
        healthTimer = nil
    }

    private func checkHealth() {
        let now = self.now

        enum Action { case none, recover, fail }
        let action: Action = lock.withLock {
            guard active, !recoveryInFlight, let health else { return .none }
            if let interruptedSince {
                // Someone else holds the device. Fail only if they never give it
                // back; otherwise interruptionEnded restarts us.
                return now - interruptedSince > Self.maxInterruption ? .fail : .none
            }
            switch health.verdict(at: now) {
            case .healthy: return .none
            case .recover:
                self.health?.noteRecoveryStarted(at: now)
                recoveryInFlight = true
                return .recover
            case .fail: return .fail
            }
        }

        switch action {
        case .none:
            return
        case .recover:
            let attempt = lock.withLock { health?.recoveryCount ?? 1 }
            Log.audio.error("no audio arriving; rebuilding input (attempt \(attempt, privacy: .public))")
            // The meter would otherwise freeze at the last level it saw, which
            // reads as "still listening" while we are not.
            onLevel?(0)
            rebuildInput(attempt: attempt)
        case .fail:
            Log.audio.error("capture could not be recovered; aborting")
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isRunning else { return }
                self.cancel()
                self.onConfigurationChange?()
            }
        }
    }

    /// Force a stall to be treated as such right now, without waiting out the
    /// timeout — for signals that already prove the input is gone.
    private func requestRecovery(reason: String) {
        let attempt: Int? = lock.withLock {
            guard active, !recoveryInFlight, health != nil else { return nil }
            health?.noteRecoveryStarted(at: now)
            recoveryInFlight = true
            return health?.recoveryCount
        }
        guard let attempt else { return }
        Log.audio.info("rebuilding input: \(reason, privacy: .public) (attempt \(attempt, privacy: .public))")
        onLevel?(0)
        rebuildInput(attempt: attempt)
    }

    /// Rebuild the session's input, keeping everything recorded so far.
    ///
    /// Escalates: the first attempt swaps the input on the live session, which
    /// is quick and usually enough for a headset that changed profile. Later
    /// attempts stop and restart the session outright — slower, and it re-opens
    /// the hardware from scratch, which is what a genuinely wedged device needs.
    private func rebuildInput(attempt: Int) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            defer { self.lock.withLock { self.recoveryInFlight = false } }
            guard self.lock.withLock({ self.active }) else { return }

            do {
                if attempt > 1, self.session.isRunning { self.session.stopRunning() }
                try self.configureInput(force: true)
                if !self.session.isRunning { self.session.startRunning() }
                Log.audio.info("capture input rebuilt")
            } catch {
                // Leave it to the health monitor: the grace it just started will
                // expire and either try again or fail for good. A device that is
                // mid-reconnect is often unresolvable for a moment and fine
                // shortly after.
                Log.audio.error("input rebuild failed: \(error.localizedDescription, privacy: .public)")
            }
        }
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

        let arrivedAt = now
        lock.withLock {
            if accumulating { samples.append(contentsOf: chunk) }
            health?.noteBuffer(at: arrivedAt)
        }
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
