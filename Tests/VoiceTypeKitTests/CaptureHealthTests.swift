import XCTest
@testable import VoiceTypeKit

final class CaptureHealthTests: XCTestCase {
    private let policy = CaptureHealthPolicy(startupGrace: 4.0,
                                             stallTimeout: 1.0,
                                             recoveryGrace: 2.5,
                                             maxRecoveries: 3)

    // MARK: - Cold start

    func testSlowBluetoothStartIsNotAFailure() {
        let monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        // AirPods routinely take a second or two to hand over the first buffer.
        XCTAssertEqual(monitor.verdict(at: 1.0), .healthy)
        XCTAssertEqual(monitor.verdict(at: 2.5), .healthy)
        XCTAssertEqual(monitor.verdict(at: 3.9), .healthy)
    }

    func testFirstBufferNeverArrivingTriggersRecovery() {
        let monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        XCTAssertEqual(monitor.verdict(at: 4.5), .recover)
    }

    func testFirstBufferEndsTheStartupGrace() {
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        monitor.noteBuffer(at: 2.0)
        // The generous startup window is gone: from here a one-second gap is a
        // stall, even though we are still inside the original 4s grace.
        XCTAssertEqual(monitor.verdict(at: 2.5), .healthy)
        XCTAssertEqual(monitor.verdict(at: 3.5), .recover)
    }

    // MARK: - Mid-stream stall

    func testSteadyBuffersStayHealthy() {
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        for tick in stride(from: 0.1, through: 5.0, by: 0.1) {
            monitor.noteBuffer(at: tick)
            XCTAssertEqual(monitor.verdict(at: tick + 0.05), .healthy)
        }
        XCTAssertEqual(monitor.recoveryCount, 0)
    }

    func testStallMidStreamTriggersRecovery() {
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        monitor.noteBuffer(at: 1.0)
        XCTAssertEqual(monitor.verdict(at: 1.9), .healthy)
        XCTAssertEqual(monitor.verdict(at: 2.1), .recover)
    }

    func testVerdictIsIdempotentUntilRecoveryIsNoted() {
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        monitor.noteBuffer(at: 1.0)
        XCTAssertEqual(monitor.verdict(at: 2.1), .recover)
        XCTAssertEqual(monitor.verdict(at: 2.2), .recover)
        XCTAssertEqual(monitor.recoveryCount, 0, "asking should never spend budget")
    }

    func testZeroFilledBuffersCannotKeepADeadMicrophoneHealthy() {
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        monitor.noteBuffer(at: 0.1)
        for tick in stride(from: 0.2, through: 5.3, by: 0.1) {
            monitor.noteBuffer(at: tick, hasSignal: false)
        }
        XCTAssertEqual(monitor.verdict(at: 5.3), .recover)
    }

    func testBriefDigitalSilenceAndQuietSignalDoNotTriggerRecovery() {
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        for tick in stride(from: 0.1, through: 4.9, by: 0.1) {
            monitor.noteBuffer(at: tick, hasSignal: false)
            XCTAssertEqual(monitor.verdict(at: tick), .healthy)
        }
        monitor.noteBuffer(at: 5.0, hasSignal: true)
        monitor.noteBuffer(at: 5.1, hasSignal: false)
        XCTAssertEqual(monitor.verdict(at: 5.2), .healthy)
    }

    func testZeroFilledRecoveryIsBounded() {
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        for attempt in 0...3 {
            let start = Double(attempt) * 6
            monitor.noteBuffer(at: start, hasSignal: false)
            monitor.noteBuffer(at: start + 5.1, hasSignal: false)
            XCTAssertEqual(monitor.verdict(at: start + 5.1), attempt == 3 ? .fail : .recover)
            if attempt < 3 { monitor.noteRecoveryStarted(at: start + 5.1) }
        }
    }

    func testReadinessRequiresSustainedSignalAndResetsAfterRecovery() {
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        monitor.noteBuffer(at: 0.1, hasSignal: false)
        XCTAssertFalse(monitor.isReady)
        monitor.noteBuffer(at: 1.0)
        XCTAssertFalse(monitor.isReady)
        monitor.noteBuffer(at: 1.3)
        XCTAssertTrue(monitor.isReady)
        monitor.noteRecoveryStarted(at: 2.5)
        XCTAssertFalse(monitor.isReady)
        monitor.noteBuffer(at: 3.0)
        XCTAssertFalse(monitor.isReady)
        monitor.noteBuffer(at: 3.3)
        XCTAssertTrue(monitor.isReady)
    }

    // MARK: - Recovery

    func testRecoveryGetsAFreshGraceAndBuffersResumeHealthy() {
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        monitor.noteBuffer(at: 1.0)
        XCTAssertEqual(monitor.verdict(at: 2.1), .recover)

        monitor.noteRecoveryStarted(at: 2.1)
        XCTAssertEqual(monitor.recoveryCount, 1)
        // Rebuilt input gets the shorter post-recovery grace, not the stall
        // timeout — it has to re-open hardware too.
        XCTAssertEqual(monitor.verdict(at: 3.5), .healthy)
        monitor.noteBuffer(at: 3.6)
        XCTAssertEqual(monitor.verdict(at: 4.0), .healthy)
    }

    func testRecoveryGraceExpiringTriggersAnotherRecovery() {
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        monitor.noteRecoveryStarted(at: 0)
        XCTAssertEqual(monitor.verdict(at: 2.4), .healthy)
        XCTAssertEqual(monitor.verdict(at: 2.6), .recover)
    }

    func testRecoveryBudgetIsBoundedThenTheCaptureFails() {
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        var now: TimeInterval = 0
        for attempt in 1...policy.maxRecoveries {
            // The first wait is the cold-start grace; every later one is the
            // shorter grace a rebuilt input gets.
            now += (attempt == 1 ? policy.startupGrace : policy.recoveryGrace) + 0.1
            XCTAssertEqual(monitor.verdict(at: now), .recover, "attempt \(attempt) should still retry")
            monitor.noteRecoveryStarted(at: now)
        }
        now += policy.recoveryGrace + 0.1
        XCTAssertEqual(monitor.verdict(at: now), .fail)
        XCTAssertEqual(monitor.recoveryCount, policy.maxRecoveries)
    }

    func testBudgetIsPerRecordingNotPerStall() {
        // Buffers flowing again does not refill the budget: a mic that dies
        // three times in one utterance is broken, not merely slow.
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        var now: TimeInterval = 0
        for _ in 1...policy.maxRecoveries {
            now += 0.1
            monitor.noteBuffer(at: now)
            now += policy.stallTimeout + 0.1
            XCTAssertEqual(monitor.verdict(at: now), .recover)
            monitor.noteRecoveryStarted(at: now)
        }
        now += 0.1
        monitor.noteBuffer(at: now)
        now += policy.stallTimeout + 0.1
        XCTAssertEqual(monitor.verdict(at: now), .fail)
    }

    // MARK: - Interruptions

    func testResumeAfterInterruptionDoesNotSpendBudget() {
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        monitor.noteBuffer(at: 1.0)
        monitor.noteInputOpened(at: 5.0)
        XCTAssertEqual(monitor.recoveryCount, 0)
        // The system told us why the gap happened; only the wait after the
        // resume is ours to judge.
        XCTAssertEqual(monitor.verdict(at: 7.0), .healthy)
        XCTAssertEqual(monitor.verdict(at: 7.6), .recover)
    }

    func testOpeningTheDeviceKeepsTheColdStartGrace() {
        // startRunning() blocked for 3s opening a headset. The first buffer is
        // still a first buffer: it gets the full cold-start grace from here,
        // not the shorter one a rebuild would get.
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        monitor.noteInputOpened(at: 3.0)
        XCTAssertEqual(monitor.verdict(at: 6.0), .healthy)
        XCTAssertEqual(monitor.verdict(at: 7.1), .recover)
    }

    func testOpeningARebuiltInputKeepsTheShorterGrace() {
        var monitor = CaptureHealthMonitor(policy: policy, startedAt: 0)
        monitor.noteRecoveryStarted(at: 0)
        monitor.noteInputOpened(at: 1.0)
        XCTAssertEqual(monitor.verdict(at: 3.4), .healthy)
        XCTAssertEqual(monitor.verdict(at: 3.6), .recover)
    }

    func testDefaultPolicyToleratesARealisticBluetoothColdStart() {
        let monitor = CaptureHealthMonitor(startedAt: 0)
        XCTAssertEqual(monitor.verdict(at: 3.0), .healthy,
                       "a 3s AirPods cold start must not kill the recording")
    }
}
