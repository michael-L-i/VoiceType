import SwiftUI
import AppKit
import VoiceTypeKit

/// The preferences window, opened with ⌘, or from the Home window. Five focused tabs that bind
/// straight to `coordinator.settings` (mutations auto-persist via the
/// coordinator's `didSet`). The design goal is a calm, native macOS utility:
/// `Form` + `GroupBox` idioms, SF Symbols, and copy that makes the privacy
/// default obvious rather than buried in a setting.
struct SettingsView: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        TabView {
            GeneralTab(coordinator: coordinator)
                .tabItem { Label("General", systemImage: "gearshape") }

            TranscriptionTab(coordinator: coordinator)
                .tabItem { Label("Transcription", systemImage: "waveform") }

            CleanupTab(coordinator: coordinator)
                .tabItem { Label("Cleanup", systemImage: "wand.and.stars") }

            PrivacyTab(coordinator: coordinator)
                .tabItem { Label("Privacy & Cloud", systemImage: "lock.shield") }
        }
        .frame(width: 520, height: 460)
    }
}

// MARK: - General

private struct GeneralTab: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        Form {
            Section {
                Picker("Push-to-talk key", selection: $coordinator.settings.hotkey.trigger) {
                    ForEach(Hotkey.Trigger.allCases, id: \.self) { trigger in
                        Text(trigger.displayName).tag(trigger)
                    }
                }

                Toggle("Hold to talk", isOn: $coordinator.settings.hotkey.holdToTalk)
                Text(coordinator.settings.hotkey.holdToTalk
                     ? "Hold the key while speaking; release to insert."
                     : "Tap once to start, tap again to stop and insert.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Dictation key")
            }

            Section {
                Toggle("Play a sound when recording starts and stops",
                       isOn: $coordinator.settings.soundFeedback)
                Toggle("Keep an on-device history of recent dictations",
                       isOn: $coordinator.settings.keepHistory)
                Text("History is stored locally and never leaves your Mac. Audio is never saved.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Feedback")
            }

            Section {
                Toggle("Open VoiceType at login", isOn: Binding(
                    get: { coordinator.launchAtLoginEnabled },
                    set: { coordinator.setLaunchAtLogin($0) }))

                if coordinator.launchAtLoginRequiresApproval {
                    HStack {
                        Label("Needs approval in Login Items", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Spacer()
                        Button("Open Settings") {
                            coordinator.openLoginItemsSettings()
                        }
                    }
                }
            } header: {
                Text("Startup")
            }

            Section {
                TextField("Language", text: $coordinator.settings.locale,
                          prompt: Text("en-US"))
                    .frame(maxWidth: 160)
                Text("BCP-47 code for the spoken language, e.g. en-US, en-GB, es-ES.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Language")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Transcription

private struct TranscriptionTab: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        Form {
            Section {
                Picker("Engine", selection: $coordinator.settings.transcriptionEngine) {
                    ForEach(TranscriptionEngineKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.radioGroup)

                statusNote(for: coordinator.settings.transcriptionEngine)
            } header: {
                Text("Speech-to-text")
            } footer: {
                Text("VoiceType picks the best available engine automatically if your choice can't run right now.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func statusNote(for kind: TranscriptionEngineKind) -> some View {
        switch kind {
        case .appleOnDevice:
            EngineStatusRow(
                ready: coordinator.availableTranscription.contains(.appleOnDevice),
                readyText: "Ready. Runs entirely on-device.",
                pendingText: "Needs Speech Recognition permission to run.")
        case .whisperCpp:
            EngineStatusRow(
                ready: coordinator.availableTranscription.contains(.whisperCpp),
                readyText: "Ready. Runs entirely on-device.",
                pendingText: "Requires a one-time model download before first use.")
            if !coordinator.whisperModelDownloaded {
                if let progress = coordinator.whisperDownloadProgress {
                    ProgressView(value: progress) {
                        Text("Downloading model… \(Int(progress * 100))%").font(.caption)
                    }
                } else {
                    Button("Download Whisper model (~150 MB)") {
                        coordinator.downloadWhisperModel()
                    }
                }
            }
        case .groqCloud:
            CloudEngineStatusRow(
                cloudEnabled: coordinator.settings.cloudEnabled,
                hasKey: coordinator.hasGroqKey,
                ready: coordinator.availableTranscription.contains(.groqCloud))
        }
    }
}

// MARK: - Cleanup

private struct CleanupTab: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        Form {
            Section {
                Picker("Engine", selection: $coordinator.settings.cleanupEngine) {
                    ForEach(CleanupEngineKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.radioGroup)

                cleanupStatusNote(for: coordinator.settings.cleanupEngine)
            } header: {
                Text("Tidy-up engine")
            } footer: {
                Text("Cleanup only changes delivery — punctuation, casing, fillers — never your meaning. It falls back to raw text if it can't run.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Remove filler words (um, uh, like)",
                       isOn: $coordinator.settings.cleanupOptions.removeFillers)
                Toggle("Add punctuation",
                       isOn: $coordinator.settings.cleanupOptions.addPunctuation)
                Toggle("Fix capitalization",
                       isOn: $coordinator.settings.cleanupOptions.fixCapitalization)
            } header: {
                Text("What to clean up")
            }
            .disabled(coordinator.settings.cleanupEngine == .none)
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func cleanupStatusNote(for kind: CleanupEngineKind) -> some View {
        switch kind {
        case .foundationModels:
            EngineStatusRow(
                ready: coordinator.availableCleanup.contains(.foundationModels),
                readyText: "Ready. Runs on-device with Apple Intelligence.",
                pendingText: "Needs Apple Intelligence; falls back to built-in rules if unavailable.")
        case .ruleBased:
            EngineStatusRow(
                ready: true,
                readyText: "Always available. Deterministic, on-device.",
                pendingText: "")
        case .groqCloud:
            CloudEngineStatusRow(
                cloudEnabled: coordinator.settings.cloudEnabled,
                hasKey: coordinator.hasGroqKey,
                ready: coordinator.availableCleanup.contains(.groqCloud))
        case .none:
            EngineStatusRow(
                ready: true,
                readyText: "Inserts the raw transcript verbatim.",
                pendingText: "")
        }
    }
}

// MARK: - Privacy & Cloud

private struct PrivacyTab: View {
    @Bindable var coordinator: DictationCoordinator
    @State private var groqKeyDraft: String = ""
    @State private var savedConfirmation = false

    var body: some View {
        Form {
            Section {
                Toggle("Enable cloud features", isOn: $coordinator.settings.cloudEnabled)
                    .font(.body.weight(.medium))
                Text("Off by default. When on, selecting a cloud engine lets VoiceType send your audio and text to Groq to be transcribed or cleaned up. With this off, everything stays on your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Cloud")
            }

            Section {
                SecureField("Groq API key", text: $groqKeyDraft,
                            prompt: Text(coordinator.hasGroqKey ? "•••••• (saved)" : "gsk_…"))
                    .disabled(!coordinator.settings.cloudEnabled)

                HStack {
                    Button("Save Key") {
                        coordinator.saveGroqKey(groqKeyDraft)
                        groqKeyDraft = ""
                        savedConfirmation = true
                    }
                    .disabled(!coordinator.settings.cloudEnabled || groqKeyDraft.isEmpty)

                    if coordinator.hasGroqKey {
                        Button("Remove Key", role: .destructive) {
                            coordinator.saveGroqKey("")
                            groqKeyDraft = ""
                            savedConfirmation = false
                        }
                        .disabled(!coordinator.settings.cloudEnabled)
                    }

                    Spacer()

                    if savedConfirmation {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .labelStyle(.titleAndIcon)
                    }
                }

                Text("Stored securely in your macOS Keychain — never in plain text, never synced by VoiceType.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Groq API key")
            }
            .opacity(coordinator.settings.cloudEnabled ? 1 : 0.5)

            if !coordinator.settings.cloudEnabled {
                Section {
                    Label("Cloud engines stay disabled until you turn on cloud features above.",
                          systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: groqKeyDraft) { _, _ in savedConfirmation = false }
    }
}

// MARK: - Shared status rows

/// A small ready/needs-setup line shown under an engine picker.
private struct EngineStatusRow: View {
    let ready: Bool
    let readyText: String
    let pendingText: String

    var body: some View {
        Label {
            Text(ready ? readyText : pendingText)
        } icon: {
            Image(systemName: ready ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(ready ? .green : .orange)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

/// Status line for a cloud engine: it can be blocked on consent, a missing key,
/// or simply not reachable. Keeps the privacy gating legible.
private struct CloudEngineStatusRow: View {
    let cloudEnabled: Bool
    let hasKey: Bool
    let ready: Bool

    var body: some View {
        if !cloudEnabled {
            EngineStatusRow(ready: false, readyText: "",
                            pendingText: "Turn on cloud features in Privacy & Cloud to use this.")
        } else if !hasKey {
            EngineStatusRow(ready: false, readyText: "",
                            pendingText: "Add your Groq API key in Privacy & Cloud.")
        } else {
            EngineStatusRow(ready: ready,
                            readyText: "Ready. Sends audio/text to Groq when selected.",
                            pendingText: "Key saved, but the service isn't reachable right now.")
        }
    }
}
