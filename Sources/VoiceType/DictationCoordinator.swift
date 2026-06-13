import Foundation
import Observation
import AppKit
import VoiceTypeKit

/// The app-side brain: owns settings + services, drives the push-to-talk →
/// capture → transcribe → cleanup → inject loop, and publishes state for the
/// menu bar. All UI-affecting state lives here on the main actor.
@Observable
@MainActor
final class DictationCoordinator {
    // Published state
    private(set) var state: DictationState = .idle
    private(set) var lastResult: PipelineResult?
    private(set) var inputLevel: Float = 0
    private(set) var history = DictationHistory()

    /// Set true to request the onboarding window (first launch, or the menu's
    /// "Set Up VoiceType…"). The AppDelegate installs `onRequestOnboarding` to
    /// actually present it via AppKit, which works regardless of what SwiftUI
    /// scenes are currently mounted.
    var wantsOnboarding = false {
        didSet { if wantsOnboarding { onRequestOnboarding?() } }
    }

    /// Installed by the AppDelegate to present the onboarding window on demand.
    var onRequestOnboarding: (@MainActor () -> Void)?

    /// Installed by the AppDelegate to trigger a Sparkle update check.
    var onCheckForUpdates: (@MainActor () -> Void)?
    func checkForUpdates() { onCheckForUpdates?() }

    var settings: AppSettings {
        didSet { applySettingsChange(from: oldValue) }
    }

    // Services
    private let capture = AudioCaptureService()
    private let hotkey: HotkeyMonitor
    private let injector: TextInjector = PasteboardInjector()

    // Resolved availability, refreshed on launch and when settings change.
    // Exposed read-only so the Settings UI can show which engines are ready vs.
    // need setup, without being able to mutate the resolver's view of the world.
    private(set) var availableTranscription: Set<TranscriptionEngineKind> = [.appleOnDevice]
    private(set) var availableCleanup: Set<CleanupEngineKind> = [.ruleBased, .none]
    private var isProcessing = false
    private var resetTask: Task<Void, Never>?

    init() {
        let loaded = SettingsStore.shared.load()
        self.settings = loaded
        self.hotkey = HotkeyMonitor(trigger: loaded.hotkey.trigger)

        capture.onLevel = { [weak self] level in
            Task { @MainActor in self?.inputLevel = level }
        }
        hotkey.onPress = { [weak self] in self?.handlePress() }
        hotkey.onRelease = { [weak self] in self?.handleRelease() }
    }

    /// Tracks whether the live global hotkey monitor was established while the
    /// process was Accessibility-trusted. A `NSEvent` global monitor binds its
    /// input-monitoring trust at creation time, so one created before the grant
    /// silently receives no global key events — even after the user grants. We
    /// remember the arm-time trust state so we can re-create the monitor exactly
    /// once when Accessibility flips to granted.
    private var hotkeyArmedWithTrust = false

    /// Begin operating: start the hotkey monitor and learn what engines exist.
    func start() {
        hotkey.start()
        hotkeyArmedWithTrust = Permissions.accessibilityStatus() == .granted
        Task { await refreshAvailability() }
    }

    /// Re-establish the global hotkey monitor if Accessibility has become trusted
    /// since we last armed it — otherwise the hotkey stays dead in other apps
    /// until a relaunch. Idempotent and cheap (a guarded `AXIsProcessTrusted`
    /// check); safe to call on a timer or on `applicationDidBecomeActive`.
    func syncHotkeyWithPermissions() {
        guard !hotkeyArmedWithTrust,
              Permissions.accessibilityStatus() == .granted else { return }
        hotkey.start()
        hotkeyArmedWithTrust = true
        Log.hotkey.info("re-armed global monitor after Accessibility grant")
    }

    // MARK: - Permissions

    var permissionsGranted: Bool { Permissions.allCoreGranted }

    func requestAllPermissions() async {
        _ = await Permissions.requestMicrophone()
        _ = await Permissions.requestSpeech()
        Permissions.requestAccessibility()
        await refreshAvailability()
    }

    /// Request a single permission (used by the onboarding flow's per-row Grant
    /// buttons) and refresh engine availability afterwards.
    func request(_ permission: Permission) async {
        switch permission {
        case .microphone: _ = await Permissions.requestMicrophone()
        case .speech: _ = await Permissions.requestSpeech()
        case .accessibility: Permissions.requestAccessibility()
        }
        await refreshAvailability()
    }

    /// Deep-link to the relevant System Settings privacy pane when a grant was
    /// denied (the system won't re-prompt, so we send the user there).
    func openSystemSettings(for permission: Permission) {
        let anchor: String
        switch permission {
        case .microphone: anchor = "Privacy_Microphone"
        case .speech: anchor = "Privacy_SpeechRecognition"
        case .accessibility: anchor = "Privacy_Accessibility"
        }
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Secrets

    /// Whether a Groq API key is present in the Keychain. Read-only; the key
    /// itself never leaves the Keychain through this surface.
    var hasGroqKey: Bool {
        guard let key = KeychainStore.shared.groqAPIKey else { return false }
        return !key.isEmpty
    }

    /// Save (or clear, when empty) the Groq API key in the Keychain, then
    /// re-resolve which engines are usable so the UI updates immediately.
    func saveGroqKey(_ key: String) {
        KeychainStore.shared.groqAPIKey = key
        Task { await refreshAvailability() }
    }

    // MARK: - History

    func clearHistory() { history.clear() }

    // MARK: - Whisper model

    /// Whether the local Whisper model is present on disk.
    var whisperModelDownloaded: Bool { WhisperModelManager().isModelDownloaded() }

    /// Download progress in 0...1 while a download is in flight; nil otherwise.
    private(set) var whisperDownloadProgress: Double?

    /// Fetch the local Whisper model (one-time). Safe to call repeatedly; it
    /// no-ops if already downloading or present, and refreshes availability so
    /// the Whisper engine becomes selectable as soon as it lands.
    func downloadWhisperModel() {
        guard whisperDownloadProgress == nil else { return }
        whisperDownloadProgress = 0
        Task { [weak self] in
            do {
                try await WhisperModelManager().downloadModelIfNeeded(progress: { fraction in
                    Task { @MainActor in self?.whisperDownloadProgress = fraction }
                })
                await self?.refreshAvailability()
            } catch {
                Log.engine.error("whisper model download failed: \(error.localizedDescription, privacy: .public)")
            }
            self?.whisperDownloadProgress = nil
        }
    }

    // MARK: - Push-to-talk

    private func handlePress() {
        guard !isProcessing, state == .idle || isDone(state) else { return }
        resetTask?.cancel()
        do {
            try capture.start()
            SoundFeedback(enabled: settings.soundFeedback).start()
            state = .recording
        } catch {
            Log.audio.error("capture start failed: \(error.localizedDescription, privacy: .public)")
            setError("Couldn't access the microphone.")
        }
    }

    private func handleRelease() {
        guard state == .recording else { return }
        SoundFeedback(enabled: settings.soundFeedback).stop()
        let audio = capture.stop()
        inputLevel = 0

        // Ignore accidental taps with essentially no speech.
        guard audio.duration >= 0.25, audio.rms > 0.002 else {
            state = .idle
            return
        }
        runPipeline(on: audio)
    }

    // MARK: - Pipeline

    private func runPipeline(on audio: PCMBuffer) {
        isProcessing = true
        let settings = self.settings
        let secrets = EngineFactory.Secrets(groqAPIKey: KeychainStore.shared.groqAPIKey)

        let tKind = EngineResolver.resolveTranscription(
            preferred: settings.transcriptionEngine,
            cloudEnabled: settings.cloudEnabled,
            available: availableTranscription)
        let cKind = EngineResolver.resolveCleanup(
            preferred: settings.cleanupEngine,
            cloudEnabled: settings.cloudEnabled,
            available: availableCleanup)

        guard let transcriber = EngineFactory.makeTranscriber(tKind, secrets: secrets) else {
            isProcessing = false
            setError("No transcription engine available.")
            return
        }
        let cleaner = EngineFactory.makeCleaner(cKind, secrets: secrets)
        let pipeline = DictationPipeline(transcriber: transcriber, cleaner: cleaner)

        Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await pipeline.run(
                    audio, locale: settings.locale, options: settings.cleanupOptions,
                    onState: { st in Task { @MainActor in self.state = st } })

                if result.finalText.isEmpty {
                    self.finish(state: .idle)
                } else {
                    self.state = .injecting
                    try await self.injector.inject(result.finalText)
                    self.record(result)
                    self.finish(state: .done)
                }
            } catch let error as InjectionError {
                self.handleInjectionError(error)
            } catch let error as TranscriptionError {
                self.setError(Self.describe(error))
            } catch {
                self.setError(error.localizedDescription)
            }
            self.isProcessing = false
        }
    }

    private func record(_ result: PipelineResult) {
        lastResult = result
        Log.metrics(result)
        if settings.keepHistory {
            history.add(DictationRecord(
                date: Date(), text: result.finalText,
                transcriptionEngine: result.transcriptionEngine,
                cleanupEngine: result.cleanupEngine,
                timeToText: result.metrics.timeToText))
        }
    }

    // MARK: - State helpers

    private func finish(state: DictationState) {
        self.state = state
        scheduleReset()
    }

    private func setError(_ message: String) {
        state = .error(message)
        isProcessing = false
        scheduleReset()
    }

    private func scheduleReset() {
        resetTask?.cancel()
        resetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let self, !Task.isCancelled else { return }
            if self.isDone(self.state) || self.isError(self.state) { self.state = .idle }
        }
    }

    private func isDone(_ s: DictationState) -> Bool { if case .done = s { return true }; return false }
    private func isError(_ s: DictationState) -> Bool { if case .error = s { return true }; return false }

    private func handleInjectionError(_ error: InjectionError) {
        switch error {
        case .notTrusted:
            setError("Grant Accessibility access to insert text.")
        case .failed(let m):
            setError(m)
        }
    }

    private static func describe(_ error: TranscriptionError) -> String {
        switch error {
        case .unavailable(let reason): return reason
        case .noSpeechDetected: return "Didn't catch that."
        case .network(let m): return "Network: \(m)"
        case .failed(let m): return m
        }
    }

    // MARK: - Settings

    private func applySettingsChange(from old: AppSettings) {
        SettingsStore.shared.save(settings)
        if old.hotkey.trigger != settings.hotkey.trigger {
            hotkey.updateTrigger(settings.hotkey.trigger)
        }
        if old.cloudEnabled != settings.cloudEnabled
            || old.transcriptionEngine != settings.transcriptionEngine
            || old.cleanupEngine != settings.cleanupEngine {
            Task { await refreshAvailability() }
        }
    }

    func refreshAvailability() async {
        let secrets = EngineFactory.Secrets(groqAPIKey: KeychainStore.shared.groqAPIKey)
        availableTranscription = await EngineFactory.availableTranscription(secrets: secrets)
        availableCleanup = await EngineFactory.availableCleanup(secrets: secrets)
        if availableTranscription.isEmpty { availableTranscription = [.appleOnDevice] }
    }

    // MARK: - Menu bar presentation

    var menuBarSymbol: String {
        switch state {
        case .idle: return "mic"
        case .recording: return "mic.fill"
        case .transcribing, .cleaning, .injecting: return "waveform"
        case .done: return "checkmark.circle"
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
        case .error(let message): return message
        }
    }
}
