import Foundation

/// Timing thresholds for deciding whether a live capture is healthy, needs to
/// be rebuilt, or is beyond saving.
///
/// The numbers exist because Bluetooth microphones behave nothing like the
/// built-in one:
///
/// - **Cold start is slow.** Opening the mic on AirPods makes macOS renegotiate
///   the link from the music profile to the call profile. The first sample
///   buffer routinely lands a second or two after `startRunning()`, and on a
///   headset that just paired it can be slower still. Anything that calls a
///   capture dead before that has simply not waited long enough.
/// - **Mid-stream death is fast and silent.** That same renegotiation can
///   invalidate the device object the capture session opened. Buffers stop, no
///   error is posted, and the recording sits there looking live while hearing
///   nothing. A gap that would be unremarkable on a file is already pathological
///   on a live mic, so a stall is worth acting on within about a second.
public struct CaptureHealthPolicy: Sendable, Equatable {
    /// How long the first buffer may take to arrive before we intervene.
    public var startupGrace: TimeInterval
    /// How long a live stream may go without a buffer before we intervene.
    public var stallTimeout: TimeInterval
    /// Startup grace applied to a rebuilt input (the route is already warm, so
    /// this is shorter than a cold start).
    public var recoveryGrace: TimeInterval
    /// How many rebuilds one recording gets before we give up on it.
    public var maxRecoveries: Int

    public init(startupGrace: TimeInterval = 4.0,
                stallTimeout: TimeInterval = 1.0,
                recoveryGrace: TimeInterval = 2.5,
                maxRecoveries: Int = 3) {
        self.startupGrace = startupGrace
        self.stallTimeout = stallTimeout
        self.recoveryGrace = recoveryGrace
        self.maxRecoveries = maxRecoveries
    }

    public static let `default` = CaptureHealthPolicy()
}

/// Decides, from nothing but a clock and a "a buffer arrived" signal, whether a
/// recording is fine, should be rebuilt, or should be abandoned.
///
/// Deliberately pure: the capture layer it serves is all AVFoundation and
/// hardware, which cannot be unit-tested, but this — the part that actually
/// decides to throw a user's sentence away — can be.
///
/// All timestamps are seconds on a caller-supplied monotonic clock; the monitor
/// never reads a clock itself.
public struct CaptureHealthMonitor: Sendable, Equatable {
    /// What the caller should do about the capture right now.
    public enum Verdict: Sendable, Equatable {
        /// Audio is flowing, or hasn't had long enough to start.
        case healthy
        /// Nothing is arriving: rebuild the input and keep the recording.
        case recover
        /// Rebuilding has already been tried enough. Abandon the recording.
        case fail
    }

    private enum Phase: Equatable {
        /// Waiting on the first buffer since (re)starting, with its own grace.
        case awaitingFirstBuffer(since: TimeInterval, grace: TimeInterval)
        /// Buffers have been arriving; this is when the last one landed.
        case streaming(lastBufferAt: TimeInterval)
    }

    private let policy: CaptureHealthPolicy
    private var phase: Phase
    private var recoveries = 0
    private var emptySignalSince: TimeInterval?
    private var firstSignalAt: TimeInterval?
    /// True after 200 ms of signal, avoiding a cue on a transient startup packet.
    public private(set) var isReady = false

    /// Exact digital silence is different from quiet speech or room noise.
    /// Give muted/noise-gated devices five seconds before attempting recovery.
    private let emptySignalTimeout: TimeInterval = 5

    /// - Parameter startedAt: when `start()` was issued, on the caller's clock.
    public init(policy: CaptureHealthPolicy = .default, startedAt: TimeInterval) {
        self.policy = policy
        self.phase = .awaitingFirstBuffer(since: startedAt, grace: policy.startupGrace)
    }

    /// How many rebuilds this recording has consumed.
    public var recoveryCount: Int { recoveries }

    /// Record that a sample buffer arrived. Cheap enough to call per buffer.
    public mutating func noteBuffer(at now: TimeInterval, hasSignal: Bool = true) {
        if hasSignal {
            if case let .streaming(lastBufferAt) = phase,
               now - lastBufferAt > policy.stallTimeout {
                firstSignalAt = nil
            }
            if firstSignalAt == nil { firstSignalAt = now }
            isReady = now - (firstSignalAt ?? now) >= 0.2
            emptySignalSince = nil
        } else {
            firstSignalAt = nil
            isReady = false
            if emptySignalSince == nil { emptySignalSince = now }
        }
        phase = .streaming(lastBufferAt: now)
    }

    /// Record that a rebuild has just been kicked off, restarting the clock with
    /// the shorter post-recovery grace and spending one of the budget.
    public mutating func noteRecoveryStarted(at now: TimeInterval) {
        recoveries += 1
        firstSignalAt = nil
        isReady = false
        emptySignalSince = nil
        phase = .awaitingFirstBuffer(since: now, grace: policy.recoveryGrace)
    }

    /// The input has just been opened — the session started, a rebuilt input
    /// came up, or an interruption ended. Restarts the clock without spending
    /// recovery budget.
    ///
    /// This is what keeps a slow device from being blamed for its own slowness:
    /// opening a Bluetooth mic can take seconds, and if that time were counted
    /// against the wait for the first buffer, the grace would already be spent
    /// by the moment audio could first arrive.
    ///
    /// The wait keeps whatever grace it was already entitled to — a cold start
    /// stays a cold start after the device finishes opening, and only a stream
    /// that was already flowing (so: an interruption) drops to the shorter one.
    public mutating func noteInputOpened(at now: TimeInterval) {
        switch phase {
        case let .awaitingFirstBuffer(_, grace):
            phase = .awaitingFirstBuffer(since: now, grace: grace)
        case .streaming:
            phase = .awaitingFirstBuffer(since: now, grace: policy.recoveryGrace)
        }
    }

    /// The verdict at `now`. Non-mutating in effect — call it as often as you
    /// like; only `noteRecoveryStarted` advances the recovery budget.
    public func verdict(at now: TimeInterval) -> Verdict {
        let overdue: Bool
        switch phase {
        case let .awaitingFirstBuffer(since, grace):
            overdue = now - since > grace
        case let .streaming(lastBufferAt):
            overdue = now - lastBufferAt > policy.stallTimeout
        }
        let emptySignalOverdue = emptySignalSince.map { now - $0 > emptySignalTimeout } ?? false
        guard overdue || emptySignalOverdue else { return .healthy }
        return recoveries >= policy.maxRecoveries ? .fail : .recover
    }
}
