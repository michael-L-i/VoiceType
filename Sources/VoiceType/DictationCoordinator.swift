import Foundation
import Observation
import AppKit
import VoiceTypeKit

/// The app-side brain: owns settings + services, drives the push-to-talk →
/// capture → transcribe → cleanup → inject loop, and publishes state for the
/// Home window and HUD. All UI-affecting state lives here on the main actor.
@Observable
@MainActor
final class DictationCoordinator {
    // Published state
    private(set) var state: DictationState = .idle
    private(set) var lastResult: PipelineResult?
    private(set) var inputLevel: Float = 0
    private(set) var history = HistoryStore.shared.load()
    private(set) var stats = StatsStore.shared.load()
    private(set) var dailyStats = DailyStatsStore.shared.load()
    private(set) var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    private(set) var launchAtLoginRequiresApproval = LaunchAtLogin.requiresApproval

    /// Live system-permission status mirrored into observable state so the
    /// onboarding UI re-renders the instant a grant flips — including grants
    /// toggled directly in System Settings, which fire no callback. Updated only
    /// by `refreshPermissionStatuses()`; never write these elsewhere.
    private(set) var microphonePermission: PermissionStatus = .notDetermined
    private(set) var speechPermission: PermissionStatus = .notDetermined
    private(set) var accessibilityPermission: PermissionStatus = .notDetermined
    /// Permissions with a system request currently in flight, so rapid re-taps on
    /// a Grant button can't stack duplicate prompts.
    private var requestsInFlight: Set<Permission> = []

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

    /// Installed by the AppDelegate to open the Settings scene. The home window is
    /// hosted via AppKit, where SwiftUI's `\.openSettings` environment action
    /// isn't wired up, so we route the request through the app layer instead.
    var onOpenSettings: (@MainActor () -> Void)?
    func openSettings() { onOpenSettings?() }

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
        capture.onConfigurationChange = { [weak self] in
            Task { @MainActor in self?.handleAudioConfigurationChange() }
        }
        hotkey.onPress = { [weak self] in self?.handlePress() }
        hotkey.onRelease = { [weak self] in self?.handleRelease() }

        refreshPermissionStatuses()
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
        refreshPermissionStatuses()
        Task { await refreshAvailability() }
    }

    /// Re-establish the global hotkey monitor if Accessibility has become trusted
    /// since we last armed it — otherwise the hotkey stays dead in other apps
    /// until a relaunch. Idempotent and cheap (a guarded `AXIsProcessTrusted`
    /// check); safe to call on a timer or on `applicationDidBecomeActive`.
    private func syncHotkeyWithPermissions() {
        guard !hotkeyArmedWithTrust,
              Permissions.accessibilityStatus() == .granted else { return }
        hotkey.start()
        hotkeyArmedWithTrust = true
        Log.hotkey.info("re-armed global monitor after Accessibility grant")
    }

    func refreshSystemIntegrationStatus() {
        launchAtLoginEnabled = LaunchAtLogin.isEnabled
        launchAtLoginRequiresApproval = LaunchAtLogin.requiresApproval
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLogin.setEnabled(enabled)
        } catch {
            Log.app.error("launch-at-login change failed: \(error.localizedDescription, privacy: .public)")
            setError("Couldn't update Open at Login.")
        }
        refreshSystemIntegrationStatus()
        if launchAtLoginRequiresApproval {
            LaunchAtLogin.openSystemSettings()
        }
    }

    func openLoginItemsSettings() {
        LaunchAtLogin.openSystemSettings()
    }

    // MARK: - Permissions

    var permissionsGranted: Bool {
        microphonePermission == .granted
            && speechPermission == .granted
            && accessibilityPermission == .granted
    }

    func status(for permission: Permission) -> PermissionStatus {
        switch permission {
        case .microphone: return microphonePermission
        case .speech: return speechPermission
        case .accessibility: return accessibilityPermission
        }
    }

    /// Re-read live system permission status into observable state and re-arm the
    /// hotkey if Accessibility just flipped. Cheap (pure status queries, no
    /// prompts); safe to call on a timer or on app activation. Assigns only on an
    /// actual change so a 1 s poll doesn't churn the UI every tick.
    func refreshPermissionStatuses() {
        let mic = Permissions.microphoneStatus()
        let speech = Permissions.speechStatus()
        let ax = Permissions.accessibilityStatus()
        if mic != microphonePermission { microphonePermission = mic }
        if speech != speechPermission { speechPermission = speech }
        if ax != accessibilityPermission { accessibilityPermission = ax }
        syncHotkeyWithPermissions()
    }

    func requestAllPermissions() async {
        for permission in Permission.allCases { await request(permission) }
    }

    /// Request a single permission (used by the onboarding flow's per-row Grant
    /// buttons). Guarded against re-entrancy so a flurry of taps can't stack
    /// duplicate system prompts; refreshes observable status + engine
    /// availability afterwards.
    func request(_ permission: Permission) async {
        guard !requestsInFlight.contains(permission) else { return }
        requestsInFlight.insert(permission)
        defer { requestsInFlight.remove(permission) }

        switch permission {
        case .microphone: _ = await Permissions.requestMicrophone()
        case .speech: _ = await Permissions.requestSpeech()
        case .accessibility: Permissions.requestAccessibility()
        }
        refreshPermissionStatuses()
        await refreshAvailability()
    }

    /// Recovery for a stale Accessibility grant (System Settings shows VoiceType
    /// enabled but the app isn't trusted — common after a rebuild changes the
    /// signature). Clears our own record, then re-prompts for a clean grant. Only
    /// invoked by an explicit user tap in onboarding.
    func resetAccessibilityGrant() async {
        guard !requestsInFlight.contains(.accessibility) else { return }
        requestsInFlight.insert(.accessibility)
        defer { requestsInFlight.remove(.accessibility) }

        await Permissions.resetAccessibilityGrant()
        Permissions.requestAccessibility()
        refreshPermissionStatuses()
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

    func clearHistory() {
        history.clear()
        HistoryStore.shared.clearAll()
    }

    /// Delete a single transcript (from the Transcripts page).
    func deleteRecord(id: UUID) {
        history.remove(id: id)
        HistoryStore.shared.save(history)
    }

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
        guard !isProcessing else { return }
        if !settings.hotkey.holdToTalk, state == .recording {
            finishRecording()
            return
        }
        guard state == .idle || isDone(state) else { return }
        beginRecording()
    }

    private func handleRelease() {
        guard settings.hotkey.holdToTalk, state == .recording else { return }
        finishRecording()
    }

    private func beginRecording() {
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

    private func finishRecording() {
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

    private func handleAudioConfigurationChange() {
        guard state == .recording else { return }
        SoundFeedback(enabled: settings.soundFeedback).stop()
        inputLevel = 0
        state = .idle
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
                    // Read the target app while it's still frontmost (before we
                    // touch state or inject) so the usage breakdown is accurate.
                    let app = self.currentForegroundApp()
                    self.state = .injecting
                    try await self.injector.inject(result.finalText)
                    self.record(result, speakingTime: audio.duration, app: app)
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

    /// The app the user is dictating into, read at inject time while it's still
    /// frontmost. On-device only, to power the usage breakdown; nil when the
    /// foreground app has no bundle id. VoiceType's own window is never frontmost
    /// during hotkey dictation, so this reports the real target app.
    private func currentForegroundApp() -> AppUsageKey? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier else { return nil }
        return AppUsageKey(bundleID: bundleID, name: app.localizedName ?? bundleID)
    }

    private func record(_ result: PipelineResult, speakingTime: TimeInterval,
                        app: AppUsageKey?, source: DictationSource = .microphone,
                        filename: String? = nil) {
        lastResult = result
        Log.metrics(result)

        let words = DictationStats.wordCount(result.finalText)

        // Aggregate stats are counts only (no text/audio), so they update even
        // when history is off.
        stats.record(words: words, speakingTime: speakingTime, on: Date())
        StatsStore.shared.save(stats)

        // Per-day + per-app rollups for the heatmap and usage insights.
        dailyStats.record(words: words, speakingTime: speakingTime,
                          app: app, source: source, on: Date())
        DailyStatsStore.shared.save(dailyStats)

        if settings.keepHistory {
            history.add(DictationRecord(
                date: Date(), text: result.finalText,
                transcriptionEngine: result.transcriptionEngine,
                cleanupEngine: result.cleanupEngine,
                timeToText: result.metrics.timeToText,
                source: source,
                sourceFilename: filename,
                appName: app?.name,
                appBundleID: app?.bundleID,
                speakingTime: speakingTime))
            HistoryStore.shared.save(history)
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
}
