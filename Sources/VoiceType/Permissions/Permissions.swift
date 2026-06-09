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

enum PermissionStatus: Sendable { case granted, denied, notDetermined }

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
    @discardableResult
    static func requestAccessibility() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
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
