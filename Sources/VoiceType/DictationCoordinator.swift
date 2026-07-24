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

    /// Deterministic usage insights for the Stats page — recomputed cheaply from
    /// the daily log + lifetime totals. Always populated.
    private(set) var insights = UsageInsights(headline: "", bullets: [], topApps: [],
                                              busiestDay: nil, weekOverWeekWordDelta: 0)
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

    /// Whether Sparkle found an update the user hasn't installed yet. Drives
    /// the sidebar's "Update available" row, which reopens the update dialog —
    /// the way back in after dismissing it.
    var updateAvailable = false

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
    private let sounds = SoundFeedback()

    // Resolved availability, refreshed on launch and when settings change.
    // Exposed read-only so the Settings UI can show which engines are ready vs.
    // need setup, without being able to mutate the resolver's view of the world.
    private(set) var availableTranscription: Set<TranscriptionEngineKind> = [.appleOnDevice]
    private(set) var availableCleanup: Set<CleanupEngineKind> = [.ruleBased, .none]
    // Which languages each engine can transcribe. Starts empty ("assume yes")
    // until the first refresh fills in the static model facts + Apple's
    // runtime-queried locale list.
    private(set) var languageSupport = EngineLanguageSupport()
    private var isProcessing = false
    private var dictationTask: Task<Void, Never>?
    private var activeDictationID: UUID?
    private var resetTask: Task<Void, Never>?
    // The frontmost app when recording began — the dictation's intended
    // destination. Feeds the cleanup context and usage stats; never persisted.
    private var dictationTargetApp: AppUsageKey?

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
        capture.onStartFailure = { [weak self] in
            Task { @MainActor in self?.handleCaptureStartFailure() }
        }
        hotkey.onPress = { [weak self] in self?.handlePress() }
        hotkey.onRelease = { [weak self] in self?.handleRelease() }
        hotkey.onCancel = { [weak self] in self?.cancelDictation() }

        refreshPermissionStatuses()
        refreshInsights()
    }

    // MARK: - Insights

    /// Recompute the deterministic usage insights from current stats. Cheap and
    /// synchronous; safe to call after every dictation.
    func refreshInsights() {
        insights = InsightsGenerator.generate(from: dailyStats, lifetime: stats)
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
            setError(L("Couldn't update Open at Login."))
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

    // MARK: - Transcription models

    /// Download/availability state per transcription engine, driving the engine
    /// list in Settings. Apple is always `builtIn`; downloadable engines move
    /// through `notDownloaded → downloading → ready`.
    private(set) var modelStates: [TranscriptionEngineKind: ModelAvailability] = [:]

    /// State for one engine, with sensible defaults before the first refresh.
    func modelState(for kind: TranscriptionEngineKind) -> ModelAvailability {
        if !kind.requiresDownload { return .builtIn }
        return modelStates[kind] ?? .notDownloaded
    }

    /// Recompute model states from current availability, preserving any download
    /// that's still in flight.
    private func refreshModelStates() {
        for kind in TranscriptionEngineKind.allCases {
            if modelStates[kind]?.isDownloading == true { continue }
            if !kind.requiresDownload { modelStates[kind] = .builtIn }
            else if availableTranscription.contains(kind) { modelStates[kind] = .ready }
            else { modelStates[kind] = .notDownloaded }
        }
    }

    /// Fetch a downloadable engine's weights, streaming progress into
    /// `modelStates`, then re-resolve availability so it becomes selectable.
    func downloadModel(_ kind: TranscriptionEngineKind) {
        guard kind.requiresDownload, let manager = EngineFactory.modelManager(for: kind) else { return }
        guard modelStates[kind]?.isDownloading != true else { return }
        modelStates[kind] = .downloading(nil)

        // Strong self: the coordinator is app-lifetime, and the Task ends when the
        // download does — no retain cycle, and it sidesteps weak-capture churn.
        Task {
            let onProgress: @Sendable (Double?) -> Void = { fraction in
                Task { @MainActor in
                    guard self.modelStates[kind]?.isDownloading == true else { return }
                    // Cap below 1.0: the model isn't usable until download() returns
                    // (it also compiles the CoreML model). We only show "done" once
                    // it's genuinely ready, so the bar never sits at a fake 100%.
                    self.modelStates[kind] = .downloading(fraction.map { min($0, 0.99) })
                }
            }
            do {
                // `manager.download` fetches the weights AND compiles/warms the
                // model, so when it returns the engine is ready to use right now.
                try await manager.download(progress: onProgress)
                // Clear the in-flight state explicitly: `refreshModelStates()`
                // deliberately skips engines still marked `.downloading`, so without
                // this the row would stay stuck at the last progress value.
                modelStates[kind] = .ready
                await self.refreshAvailability()
            } catch {
                Log.engine.error("model download failed for \(kind.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
                self.modelStates[kind] = .failed(L("Download failed. Check your connection and try again."))
            }
        }
    }

    /// Remove a downloaded engine's weights. If it was the active engine, fall
    /// back to Apple so dictation keeps working.
    func deleteModel(_ kind: TranscriptionEngineKind) {
        guard kind.requiresDownload, let manager = EngineFactory.modelManager(for: kind) else { return }
        Task {
            try? await manager.delete()
            if self.settings.transcriptionEngine == kind {
                self.settings.transcriptionEngine = .appleOnDevice
            }
            await self.refreshAvailability()
        }
    }

    // MARK: - Push-to-talk

    private func handlePress() {
        // Never start live dictation on top of an in-flight engine test (both
        // share the one capture).
        guard !isProcessing, activeTestKind == nil else { return }
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

    /// Escape quietly abandons the current utterance. The event tap is
    /// listen-only, so Escape still reaches the app the user is working in.
    private func cancelDictation() {
        switch state {
        case .recording:
            sounds.stop(enabled: settings.soundFeedback)
            capture.cancel()
        case .transcribing, .cleaning, .injecting:
            activeDictationID = nil
            dictationTask?.cancel()
            dictationTask = nil
        case .idle, .done, .error:
            return
        }

        resetTask?.cancel()
        inputLevel = 0
        dictationTargetApp = nil
        isProcessing = false
        state = .idle
    }

    private func beginRecording() {
        resetTask?.cancel()
        guard microphonePermission != .denied else {
            setError(L("Allow microphone access in System Settings."))
            return
        }
        // Cue before the mic grabs the audio route: on Bluetooth headphones,
        // starting capture flips the output from A2DP to HFP, and a cue played
        // mid-flip is swallowed. play() is async, so this costs no latency.
        sounds.start(enabled: settings.soundFeedback)
        // Read the target app now, while the user's intended destination is
        // frontmost: it feeds the cleanup context (terminal vs. prose) and the
        // usage stats, and stays correct even if focus shifts during the
        // async transcription.
        dictationTargetApp = currentForegroundApp()
        // Non-blocking: hardware spin-up happens on the capture's own queue, so
        // this returns instantly and the hotkey event tap is never stalled
        // (a blocked tap callback is how macOS decides to disable the tap).
        capture.start()
        state = .recording
    }

    private func finishRecording() {
        guard state == .recording else { return }
        sounds.stop(enabled: settings.soundFeedback)
        let audio = capture.stop()
        inputLevel = 0

        // Ignore accidental taps with essentially no speech.
        guard audio.duration >= 0.25, audio.rms > 0.002 else {
            state = .idle
            return
        }
        runPipeline(on: audio)
    }

    /// Capture died mid-flight (device vanished, session error, buffer
    /// watchdog). Route changes no longer land here — the capture session
    /// absorbs those — so this is a genuine failure, not AirPods connecting.
    private func handleAudioConfigurationChange() {
        // A test recording owns the capture too; the capture cancels itself, so
        // just sync our state and bail.
        if let kind = activeTestKind {
            activeTestKind = nil
            inputLevel = 0
            testStates[kind] = .failed(L("Audio device changed. Try again."))
            return
        }
        guard state == .recording else { return }
        sounds.stop(enabled: settings.soundFeedback)
        inputLevel = 0
        state = .idle
    }

    /// The capture session couldn't start at all (no input device / setup
    /// failure). The capture has already torn itself down.
    private func handleCaptureStartFailure() {
        if let kind = activeTestKind {
            activeTestKind = nil
            inputLevel = 0
            testStates[kind] = .failed(L("Couldn't access the microphone."))
            return
        }
        guard state == .recording else { return }
        sounds.stop(enabled: settings.soundFeedback)
        inputLevel = 0
        setError(L("Couldn't access the microphone."))
    }

    // MARK: - Pipeline

    /// Resolve the transcription + cleanup engines for the current settings,
    /// honoring availability fallback. Shared by the live mic path and file
    /// import. Returns nil only when no transcriber can run at all.
    private func resolveEngines() -> (transcriber: TranscriptionEngine, cleaner: CleanupEngine)? {
        let tKind = EngineResolver.resolveTranscription(
            preferred: settings.transcriptionEngine,
            available: availableTranscription,
            locale: settings.locale,
            support: languageSupport)
        let cKind = EngineResolver.resolveCleanup(
            preferred: settings.cleanupEngine,
            available: availableCleanup)
        guard let transcriber = EngineFactory.makeTranscriber(tKind) else {
            return nil
        }
        return (transcriber, EngineFactory.makeCleaner(cKind))
    }

    private func makePipeline() -> DictationPipeline? {
        guard let engines = resolveEngines() else { return nil }
        return DictationPipeline(transcriber: engines.transcriber, cleaner: engines.cleaner)
    }

    private func runPipeline(on audio: PCMBuffer) {
        isProcessing = true
        let dictationID = UUID()
        activeDictationID = dictationID
        let settings = self.settings
        // The app captured when recording began — cleanup biases toward its
        // register (shell commands in a terminal, prose elsewhere) and the
        // usage stats attribute the dictation to it.
        let app = dictationTargetApp
        dictationTargetApp = nil
        let context = CleanupContext(
            appBundleID: app?.bundleID,
            appName: app?.name,
            category: AppCategorizer.category(forBundleID: app?.bundleID))

        guard let pipeline = makePipeline() else {
            activeDictationID = nil
            isProcessing = false
            setError(L("No transcription engine available."))
            return
        }

        dictationTask = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await pipeline.run(
                    audio, locale: settings.locale, options: settings.cleanupOptions,
                    context: context,
                    replacements: settings.wordReplacements,
                    onState: { st in
                        Task { @MainActor in
                            guard self.activeDictationID == dictationID else { return }
                            self.state = st
                        }
                    })

                try Task.checkCancellation()
                guard self.activeDictationID == dictationID else { return }

                if result.finalText.isEmpty {
                    self.finish(state: .idle)
                } else {
                    self.state = .injecting
                    // Trailing space so consecutive dictations don't run together.
                    // Appended only at inject time; recorded history stays clean.
                    try await self.injector.inject(result.finalText + " ")
                    self.record(result, speakingTime: audio.duration, app: app)
                    self.finish(state: .done)
                }
            } catch is CancellationError {
                // Escape already returned the coordinator to idle.
            } catch let error as InjectionError {
                if self.activeDictationID == dictationID { self.handleInjectionError(error) }
            } catch let error as TranscriptionError {
                if self.activeDictationID == dictationID { self.setError(Self.describe(error)) }
            } catch {
                if self.activeDictationID == dictationID { self.setError(error.localizedDescription) }
            }
            if self.activeDictationID == dictationID {
                self.activeDictationID = nil
                self.dictationTask = nil
                self.isProcessing = false
            }
        }
    }

    /// The app the user is dictating into, read when recording begins. Powers
    /// the cleanup context and the usage breakdown, on-device only; nil when
    /// the foreground app has no bundle id. VoiceType's own window is never
    /// frontmost during hotkey dictation, so this reports the real target app.
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

        // Refresh the deterministic insights so they describe the latest numbers.
        refreshInsights()

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

    // MARK: - File import

    /// Progress of an audio/video file transcription.
    enum ImportState: Equatable {
        case idle
        case decoding(Double)        // 0...1
        case transcribing(Double)    // 0...1
        case done(text: String)
        case failed(String)

        var isRunning: Bool {
            switch self {
            case .decoding, .transcribing: return true
            default: return false
            }
        }
    }

    private(set) var importState: ImportState = .idle
    private var importTask: Task<Void, Never>?

    /// Transcribe an imported audio/video file: decode → chunk → transcribe each
    /// chunk → one cleanup pass → save to transcripts. Unlike mic dictation the
    /// text is NOT injected (there's no target app) — the UI shows it to copy.
    func transcribeFile(at url: URL) {
        guard !importState.isRunning else { return }
        importTask?.cancel()
        importState = .decoding(0)

        importTask = Task { [weak self] in
            guard let self else { return }
            do {
                let buffer = try await AudioFileDecoder.decode(url) { fraction in
                    Task { @MainActor in
                        if case .decoding = self.importState { self.importState = .decoding(fraction) }
                    }
                }
                if Task.isCancelled { return }

                guard let engines = self.resolveEngines() else {
                    self.importState = .failed(L("No transcription engine available."))
                    return
                }

                let chunks = AudioChunker.chunk(buffer)
                self.importState = .transcribing(0)

                var parts: [String] = []
                for (index, chunk) in chunks.enumerated() {
                    if Task.isCancelled { return }
                    let result = try await engines.transcriber.transcribe(chunk, locale: self.settings.locale)
                    let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !text.isEmpty { parts.append(text) }
                    self.importState = .transcribing(Double(index + 1) / Double(chunks.count))
                }

                let raw = parts.joined(separator: " ")
                guard !raw.isEmpty else {
                    self.importState = .failed(L("Couldn't find any speech in this file."))
                    return
                }

                // One cleanup pass over the joined transcript (coherent over the
                // whole file), degrading to raw if cleanup is unavailable.
                var cleaned = raw
                var usedCleanup: CleanupEngineKind = .none
                do {
                    // File imports have no target app; clean as general prose.
                    let c = try await engines.cleaner.cleanup(raw, options: self.settings.cleanupOptions, context: .general, locale: self.settings.locale)
                    if !c.isEmpty { cleaned = c; usedCleanup = engines.cleaner.kind }
                } catch { /* keep raw */ }
                cleaned = WordReplacements.apply(self.settings.wordReplacements, to: cleaned)

                if Task.isCancelled { return }

                var metrics = LatencyMetrics()
                metrics.audioDuration = buffer.duration
                let result = PipelineResult(
                    rawText: raw, cleanedText: cleaned,
                    transcriptionEngine: engines.transcriber.kind,
                    cleanupEngine: usedCleanup, metrics: metrics)

                self.record(result, speakingTime: buffer.duration,
                            app: nil, source: .importedFile, filename: url.lastPathComponent)
                self.importState = .done(text: result.finalText)
            } catch let error as AudioFileDecoder.DecodeError {
                self.importState = .failed(error.message)
            } catch let error as TranscriptionError {
                self.importState = .failed(Self.describe(error))
            } catch {
                self.importState = .failed(error.localizedDescription)
            }
        }
    }

    /// Cancel an in-flight import and reset to idle.
    func cancelImport() {
        importTask?.cancel()
        importState = .idle
    }

    /// Dismiss a finished/failed import result.
    func clearImport() {
        guard !importState.isRunning else { return }
        importState = .idle
    }

    // MARK: - Engine test

    /// Progress of an inline "test this engine" recording on the Models page.
    /// Like file import, it transcribes without injecting anywhere — it just
    /// shows the engine's raw output so the user can hear how it does.
    enum TestState: Equatable {
        case idle
        case recording
        case transcribing
        case done(text: String)
        case failed(String)

        var isBusy: Bool {
            switch self {
            case .recording, .transcribing: return true
            default: return false
            }
        }
    }

    private(set) var testStates: [TranscriptionEngineKind: TestState] = [:]
    func testState(for kind: TranscriptionEngineKind) -> TestState { testStates[kind] ?? .idle }

    /// The engine whose test currently owns the shared mic capture, if any. Acts
    /// as the single-flight guard so a test can't overlap live dictation or
    /// another test (there is one `capture`).
    private var activeTestKind: TranscriptionEngineKind?
    private var testTask: Task<Void, Never>?

    /// Begin recording a short clip to test `kind`. No-ops if dictation, a test,
    /// or processing is already in flight, or the model isn't ready.
    func startTest(_ kind: TranscriptionEngineKind) {
        guard state != .recording, !isProcessing, activeTestKind == nil else { return }
        guard modelState(for: kind).isReady else { return }

        guard microphonePermission == .granted else {
            testStates[kind] = .failed(L("Allow microphone access to test an engine."))
            Task { await request(.microphone) }
            return
        }
        capture.start()
        activeTestKind = kind
        testStates[kind] = .recording
    }

    /// Stop the test recording and transcribe it with `kind`'s exact engine
    /// (bypassing the resolver), raw — no cleanup, no injection, no history.
    func stopTest(_ kind: TranscriptionEngineKind) {
        guard activeTestKind == kind, testStates[kind] == .recording else { return }
        let audio = capture.stop()
        inputLevel = 0
        activeTestKind = nil

        guard audio.duration >= 0.25, audio.rms > 0.002 else {
            testStates[kind] = .failed(L("Didn't catch any speech. Try again."))
            return
        }
        guard let transcriber = EngineFactory.makeTranscriber(kind) else {
            testStates[kind] = .failed(L("This engine isn't available."))
            return
        }
        testStates[kind] = .transcribing
        let locale = settings.locale
        testTask = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await transcriber.transcribe(audio, locale: locale)
                let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
                self.testStates[kind] = text.isEmpty
                    ? .failed(L("Didn't catch any speech. Try again."))
                    : .done(text: text)
            } catch let error as TranscriptionError {
                self.testStates[kind] = .failed(Self.describe(error))
            } catch {
                self.testStates[kind] = .failed(error.localizedDescription)
            }
        }
    }

    /// Abort a test (panel closed mid-recording) without transcribing.
    func cancelTest(_ kind: TranscriptionEngineKind) {
        if activeTestKind == kind {
            capture.cancel()
            inputLevel = 0
            activeTestKind = nil
        }
        testTask?.cancel()
        testStates[kind] = .idle
    }

    /// Reset a finished/failed test back to idle (for "Record again").
    func clearTest(_ kind: TranscriptionEngineKind) {
        guard !testState(for: kind).isBusy else { return }
        testStates[kind] = .idle
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
            setError(L("Grant Accessibility access to insert text."))
        case .failed(let m):
            setError(m)
        }
    }

    private static func describe(_ error: TranscriptionError) -> String {
        switch error {
        case .unavailable(let reason): return reason
        case .noSpeechDetected: return L("Didn't catch that.")
        case .failed(let m): return m
        }
    }

    // MARK: - Settings

    private func applySettingsChange(from old: AppSettings) {
        SettingsStore.shared.save(settings)
        if old.hotkey.trigger != settings.hotkey.trigger {
            hotkey.updateTrigger(settings.hotkey.trigger)
        }
        if old.transcriptionEngine != settings.transcriptionEngine {
            // A manual engine change retires the "switched for you" note. The
            // auto-switch below re-sets it AFTER assigning, so its own
            // assignment (which re-enters here) can't clear it.
            languageSwitchNotice = nil
        }
        if old.locale != settings.locale {
            switchEngineForLanguageIfNeeded()
        }
        if old.transcriptionEngine != settings.transcriptionEngine
            || old.cleanupEngine != settings.cleanupEngine {
            Task { await refreshAvailability() }
        }
    }

    func refreshAvailability() async {
        availableTranscription = await EngineFactory.availableTranscription()
        availableCleanup = await EngineFactory.availableCleanup()
        languageSupport = await EngineFactory.languageSupport()
        if availableTranscription.isEmpty { availableTranscription = [.appleOnDevice] }
        refreshModelStates()
        // A persisted engine/language pair can be incompatible (set before this
        // rule existed, or support facts changed) — repair it once facts arrive.
        switchEngineForLanguageIfNeeded()
    }

    // MARK: - Language compatibility

    /// One-shot explanation after the app switched engines for the language
    /// ("Switched to Apple Speech — Parakeet doesn't support Chinese."). Shown
    /// under the Language picker; cleared on the next manual engine change or
    /// when the language becomes compatible again.
    private(set) var languageSwitchNotice: String?

    /// Incompatible engines are not selectable (Models page grays them out),
    /// so the active engine always supports the language: when the user picks
    /// a language the current engine can't transcribe, switch to the best
    /// engine that can and say so, instead of warning and dictating garbage.
    private func switchEngineForLanguageIfNeeded() {
        let current = settings.transcriptionEngine
        guard !languageSupport.supports(current, locale: settings.locale) else {
            languageSwitchNotice = nil
            return
        }
        let resolved = EngineResolver.resolveTranscription(
            preferred: current,
            available: availableTranscription,
            locale: settings.locale,
            support: languageSupport)
        guard resolved != current,
              languageSupport.supports(resolved, locale: settings.locale) else {
            // Nothing installed can transcribe this language;
            // languageFallbackNotice warns instead.
            return
        }
        settings.transcriptionEngine = resolved
        languageSwitchNotice = L("Switched to \(resolved.displayName) — \(current.displayName) doesn't support \(languageName).")
    }

    /// Non-nil only when NOTHING installed can transcribe the selected
    /// language (the auto-switch above handles every other case). Shown as a
    /// warning under the Language picker.
    var languageFallbackNotice: String? {
        guard !languageSupport.supports(settings.transcriptionEngine, locale: settings.locale) else {
            return nil
        }
        return L("\(settings.transcriptionEngine.displayName) doesn't support \(languageName) — dictation may come out empty or wrong.")
    }

    /// The dictation language's name in the UI language.
    var languageName: String {
        Locale.current.localizedString(
            forLanguageCode: LanguageTag.code(for: settings.locale)) ?? settings.locale
    }
}
