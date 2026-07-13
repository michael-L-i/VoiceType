import SwiftUI
import AppKit
import VoiceTypeKit

/// VoiceType's settings. Shown both as the **Settings** sidebar page (in the Home
/// window) and as the standard ⌘, preferences window (the `Settings` scene sizes
/// it). One scrolling page — General and Cleanup sections together, not separate
/// tabs. Everything binds straight to `coordinator.settings` (mutations
/// auto-persist via the coordinator's `didSet`). Everything runs on your Mac.
/// Word replacements live on the dedicated Dictionary page, not here.
struct SettingsView: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        Form {
            GeneralSections(coordinator: coordinator)
            CleanupSections(coordinator: coordinator)
        }
        .formStyle(.grouped)
    }
}

// MARK: - General

private struct GeneralSections: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        Group {
            Section {
                HotkeySelector(coordinator: coordinator)
                    .padding(.vertical, VT.Space.xs)
            }

            Section {
                Toggle(L("Play a sound when recording starts and stops"),
                       isOn: $coordinator.settings.soundFeedback)
                Toggle(L("Keep an on-device history of recent dictations"),
                       isOn: $coordinator.settings.keepHistory)
                Text(L("Stored locally and never leaves your Mac; audio is never saved. Turning this off just pauses new recordings — your existing transcripts are kept. Delete them anytime from Transcripts."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(L("Feedback"))
            }

            Section {
                Toggle(L("Show a resting indicator when idle"),
                       isOn: $coordinator.settings.showRestingIndicator)
                Text(L("The oval still appears normally whenever you dictate — this only hides the small sliver shown at rest."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(L("Indicator"))
            }

            Section {
                Toggle(L("Open VoiceType at login"), isOn: Binding(
                    get: { coordinator.launchAtLoginEnabled },
                    set: { coordinator.setLaunchAtLogin($0) }))

                if coordinator.launchAtLoginRequiresApproval {
                    HStack {
                        Label(L("Needs approval in Login Items"), systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Spacer()
                        Button(L("Open Settings")) {
                            coordinator.openLoginItemsSettings()
                        }
                    }
                }
            } header: {
                Text(L("Startup"))
            }

            Section {
                Picker(L("Language"), selection: $coordinator.settings.locale) {
                    ForEach(DictationLanguage.sortedForDisplay) { language in
                        Text(language.localizedName).tag(language.code)
                    }
                }
                if let notice = coordinator.languageSwitchNotice {
                    // Informational: the app already fixed the mismatch.
                    Label {
                        Text(notice)
                    } icon: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else if let notice = coordinator.languageFallbackNotice {
                    Label {
                        Text(notice)
                    } icon: {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } header: {
                Text(L("Language"))
            }
        }
    }
}

// MARK: - Cleanup

private struct CleanupSections: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        Group {
            Section {
                Picker(L("Engine"), selection: $coordinator.settings.cleanupEngine) {
                    ForEach(CleanupEngineKind.allCases, id: \.self) { kind in
                        Text(L(dynamic: kind.displayName)).tag(kind)
                    }
                }
                .pickerStyle(.radioGroup)

                cleanupStatusNote(for: coordinator.settings.cleanupEngine)
            } header: {
                Text(L("Cleanup"))
            } footer: {
                Text(L("Cleanup only changes delivery — punctuation, casing, fillers — never your meaning. It falls back to raw text if it can't run."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(L("Remove filler words (um, uh, like)"),
                       isOn: $coordinator.settings.cleanupOptions.removeFillers)
                Toggle(L("Add punctuation"),
                       isOn: $coordinator.settings.cleanupOptions.addPunctuation)
                Toggle(L("Fix capitalization"),
                       isOn: $coordinator.settings.cleanupOptions.fixCapitalization)
            } header: {
                Text(L("What to clean up"))
            }
            .disabled(coordinator.settings.cleanupEngine == .none)

        }
    }

    @ViewBuilder
    private func cleanupStatusNote(for kind: CleanupEngineKind) -> some View {
        switch kind {
        case .foundationModels:
            EngineStatusRow(
                ready: coordinator.availableCleanup.contains(.foundationModels),
                readyText: L("Ready. Runs on-device with Apple Intelligence."),
                pendingText: L("Needs Apple Intelligence; falls back to built-in rules if unavailable."))
        case .ruleBased:
            EngineStatusRow(
                ready: true,
                readyText: L("Always available. Deterministic, on-device."),
                pendingText: "")
        case .none:
            EngineStatusRow(
                ready: true,
                readyText: L("Inserts the raw transcript verbatim."),
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
            SectionLabel(L("Dictation key"))

            HStack(spacing: VT.Space.s) {
                ForEach(Hotkey.Trigger.allCases, id: \.self) { trigger in
                    keyCap(trigger)
                }
            }

            Picker("", selection: $coordinator.settings.hotkey.holdToTalk) {
                Text(L("Hold to talk")).tag(true)
                Text(L("Tap to talk")).tag(false)
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
                Text(L(dynamic: trigger.shortName))
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
        let key = L(dynamic: hotkey.trigger.displayName)
        return hotkey.holdToTalk
            ? L("Hold \(key) anywhere and start talking — release to insert.")
            : L("Tap \(key) anywhere to start, then tap again to insert.")
    }
}
