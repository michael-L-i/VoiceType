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

    /// Request microphone access — but only present the system prompt when the
    /// status is genuinely undecided. Once the user has granted or denied, the OS
    /// won't re-prompt anyway, and calling it again on every Grant tap is how the
    /// flow ended up firing a stack of duplicate dialogs. Denied → route the user
    /// to System Settings instead (see `openSystemSettings`).
    static func requestMicrophone() async -> Bool {
        switch microphoneStatus() {
        case .granted: return true
        case .denied: return false
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .audio)
        }
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

    /// Request speech-recognition access — prompt only when undecided, for the
    /// same anti-duplicate-prompt reason as `requestMicrophone`.
    static func requestSpeech() async -> Bool {
        guard speechStatus() == .notDetermined else { return speechStatus() == .granted }
        return await withCheckedContinuation { cont in
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
    @discardableResult
    static func requestAccessibility() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

}
