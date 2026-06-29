import SwiftUI
import AppKit
import VoiceTypeKit

/// VoiceType's settings. Shown both as the **Settings** sidebar page (in the Home
/// window) and as the standard ⌘, preferences window (the `Settings` scene sizes
/// it). Focused tabs bind straight to `coordinator.settings` (mutations
/// auto-persist via the coordinator's `didSet`). The design goal is a calm,
/// native macOS utility — everything runs on your Mac, no cloud path.
struct SettingsView: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        TabView {
            GeneralTab(coordinator: coordinator)
                .tabItem { Label("General", systemImage: "gearshape") }

            CleanupTab(coordinator: coordinator)
                .tabItem { Label("Cleanup", systemImage: "wand.and.stars") }
        }
    }
}

// MARK: - General

private struct GeneralTab: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        Form {
            Section {
                HotkeySelector(coordinator: coordinator)
                    .padding(.vertical, VT.Space.xs)
            }

            Section {
                Toggle("Play a sound when recording starts and stops",
                       isOn: $coordinator.settings.soundFeedback)
                Toggle("Keep an on-device history of recent dictations",
                       isOn: $coordinator.settings.keepHistory)
                Text("Stored locally and never leaves your Mac; audio is never saved. Turning this off just pauses new recordings — your existing transcripts are kept. Delete them anytime from Transcripts.")
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

// MARK: - Dictation key

/// The push-to-talk key picker: tappable key caps + a hold/tap mode toggle and a
/// live preview line. Lives here in Settings (it used to be the final step of
/// onboarding, but setup now hands off to this page instead).
struct HotkeySelector: View {
    @Bindable var coordinator: DictationCoordinator

    private var hotkey: Hotkey { coordinator.settings.hotkey }

    var body: some View {
        VStack(alignment: .leading, spacing: VT.Space.m) {
            SectionLabel("Dictation key")

            HStack(spacing: VT.Space.s) {
                ForEach(Hotkey.Trigger.allCases, id: \.self) { trigger in
                    keyCap(trigger)
                }
            }

            Picker("", selection: $coordinator.settings.hotkey.holdToTalk) {
                Text("Hold to talk").tag(true)
                Text("Tap to talk").tag(false)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .tint(VT.tintAmber)
            .fixedSize()
            .padding(.vertical, VT.Space.s)

            Text(previewLine)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func keyCap(_ trigger: Hotkey.Trigger) -> some View {
        let selected = hotkey.trigger == trigger
        return Button {
            coordinator.settings.hotkey.trigger = trigger
        } label: {
            VStack(spacing: 3) {
                Text(trigger.keyCap)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Text(trigger.shortName)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .padding(.horizontal, 4)
            .background(selected ? AnyShapeStyle(VT.tint) : AnyShapeStyle(.regularMaterial),
                        in: RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous))
            .foregroundStyle(selected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .overlay(RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous)
                .strokeBorder(selected ? Color.clear : VT.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: selected)
    }

    private var previewLine: String {
        let verb = hotkey.holdToTalk ? "Hold" : "Tap"
        let tail = hotkey.holdToTalk
            ? "anywhere and start talking — release to insert."
            : "anywhere to start, then tap again to insert."
        return "\(verb) \(hotkey.trigger.displayName) \(tail)"
    }
}
