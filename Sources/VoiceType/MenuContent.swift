import SwiftUI
import VoiceTypeKit

/// The dropdown shown from the menu-bar icon: live status, the last result, the
/// hotkey reminder, and the doors to Settings and the setup walkthrough.
struct MenuContent: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        Text(coordinator.statusText)
            .font(.headline)

        if !coordinator.permissionsGranted {
            Divider()
            Text("⚠︎ Needs Microphone, Speech & Accessibility access")
            Button("Set Up VoiceType…") {
                coordinator.wantsOnboarding = true
            }
        }

        if let result = coordinator.lastResult, !result.finalText.isEmpty {
            Divider()
            Text("Last (\(Int(result.metrics.timeToText * 1000)) ms)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(result.finalText)
                .lineLimit(3)
            Button("Copy Last") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(result.finalText, forType: .string)
            }
        }

        Divider()
        Text("Hold \(coordinator.settings.hotkey.trigger.displayName) to dictate")
            .font(.caption)
            .foregroundStyle(.secondary)

        Divider()
        SettingsLink {
            Text("Settings…")
        }
        .keyboardShortcut(",")

        Button("Setup & Permissions…") {
            coordinator.wantsOnboarding = true
        }

        Divider()
        Button("Quit VoiceType") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
