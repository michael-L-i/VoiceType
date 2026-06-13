import AVFoundation
import AppKit
import Speech
import VoiceTypeKit

/// The three system grants VoiceType needs, and helpers to query/request them.
/// Privacy-first means we ask for the minimum, explain why in the onboarding
/// UI, and never proceed silently without consent.
enum Permission: String, CaseIterable, Sendable {
    case microphone
    case speech
    case accessibility

    var title: String {
        switch self {
        case .microphone: return "Microphone"
        case .speech: return "Speech Recognition"
        case .accessibility: return "Accessibility"
        }
    }

    var why: String {
        switch self {
        case .microphone: return "To hear you while you hold the dictation key. Audio stays on-device."
        case .speech: return "To turn your speech into text with Apple's on-device model."
        case .accessibility: return "To detect the global hotkey and type the result into the focused app."
        }
    }
}

enum PermissionStatus: Sendable, Equatable { case granted, denied, notDetermined }

enum Permissions {
    // MARK: - Microphone

    static func microphoneStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return .granted
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    static func requestMicrophone() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .audio)
    }

    // MARK: - Speech recognition

    static func speechStatus() -> PermissionStatus {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: return .granted
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    static func requestSpeech() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - Accessibility (hotkey + text injection)

    static func accessibilityStatus() -> PermissionStatus {
        AXIsProcessTrusted() ? .granted : .notDetermined
    }

    /// Prompt for Accessibility access. macOS shows its own system dialog and
    /// deep-links to System Settings; the grant takes effect without a relaunch.
    ///
    /// Reinstalling or rebuilding the app leaves a *stale* TCC record behind:
    /// System Settings still lists VoiceType with the Accessibility toggle green,
    /// but `AXIsProcessTrusted()` is false because the code signature changed
    /// (ad-hoc dev builds get a fresh signature every build; even a notarized
    /// update can drift). In that state macOS refuses to re-show the prompt and
    /// the green toggle is inert — the user clicks Grant, lands on an
    /// already-green row, and nothing registers. Clearing our own record first
    /// removes the dead entry so the prompt reappears and binds to the current
    /// signature. We only do this when not already trusted, so a live grant is
    /// never disturbed.
    @discardableResult
    static func requestAccessibility() -> Bool {
        if !AXIsProcessTrusted() {
            clearStaleAccessibilityRecord()
        }
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    /// Remove this app's own Accessibility TCC record via `tccutil` so a stale
    /// post-reinstall grant can't block a fresh prompt. Scoped to our bundle ID
    /// only — it never touches other apps — and needs no admin rights. A no-op
    /// when there's nothing to clear; failures are non-fatal (we fall through to
    /// the normal prompt). Safe because VoiceType is not sandboxed.
    static func clearStaleAccessibilityRecord() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        proc.arguments = ["reset", "Accessibility", bundleID]
        do {
            try proc.run()
            proc.waitUntilExit()
        } catch {
            Log.app.error("tccutil reset Accessibility failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func status(for permission: Permission) -> PermissionStatus {
        switch permission {
        case .microphone: return microphoneStatus()
        case .speech: return speechStatus()
        case .accessibility: return accessibilityStatus()
        }
    }

    /// True when everything required for core dictation is granted.
    static var allCoreGranted: Bool {
        microphoneStatus() == .granted &&
        speechStatus() == .granted &&
        accessibilityStatus() == .granted
    }
}
