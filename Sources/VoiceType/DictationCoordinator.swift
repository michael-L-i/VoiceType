import Foundation
import Observation
import VoiceTypeKit

/// The app-side brain: owns settings, drives the capture → transcribe → cleanup
/// → inject loop, and publishes state for the menu bar. The walking-skeleton
/// milestone fills in the hotkey/audio/engine wiring; this scaffold defines the
/// surface the UI binds to so the rest can land incrementally.
@Observable
@MainActor
final class DictationCoordinator {
    private(set) var state: DictationState = .idle
    private(set) var lastResult: PipelineResult?
    var settings: AppSettings = SettingsStore.shared.load()

    /// SF Symbol shown in the menu bar, reflecting current state.
    var menuBarSymbol: String {
        switch state {
        case .idle, .done: return "mic"
        case .recording: return "mic.fill"
        case .transcribing, .cleaning, .injecting: return "waveform"
        case .error: return "exclamationmark.triangle"
        }
    }

    var statusText: String {
        switch state {
        case .idle: return "Ready"
        case .recording: return "Listening…"
        case .transcribing: return "Transcribing…"
        case .cleaning: return "Cleaning up…"
        case .injecting: return "Inserting…"
        case .done: return "Done"
        case .error(let message): return "Error: \(message)"
        }
    }

    func saveSettings() {
        SettingsStore.shared.save(settings)
    }
}
