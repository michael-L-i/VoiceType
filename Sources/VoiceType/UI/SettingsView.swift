import SwiftUI
import AppKit
import VoiceTypeKit

/// The preferences window, opened with ⌘, or from the Home window. Focused tabs
/// that bind straight to `coordinator.settings` (mutations auto-persist via the
/// coordinator's `didSet`). The design goal is a calm, native macOS utility:
/// `Form` + `GroupBox` idioms, SF Symbols, and copy that makes the on-device
/// default obvious. Everything runs on your Mac — there is no cloud path.
struct SettingsView: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        TabView {
            GeneralTab(coordinator: coordinator)
                .tabItem { Label("General", systemImage: "gearshape") }

            CleanupTab(coordinator: coordinator)
                .tabItem { Label("Cleanup", systemImage: "wand.and.stars") }
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
        case .none:
            EngineStatusRow(
                ready: true,
                readyText: "Inserts the raw transcript verbatim.",
                pendingText: "")
        }
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
