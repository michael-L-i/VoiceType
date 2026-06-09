import SwiftUI
import VoiceTypeKit

/// The dropdown shown from the menu-bar icon. The settings/onboarding milestone
/// (task #6) expands this with full preferences and a guided permissions flow.
struct MenuContent: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        Text(coordinator.statusText)
            .font(.headline)

        if !coordinator.permissionsGranted {
            Divider()
            Text("⚠︎ Needs Microphone, Speech & Accessibility access")
            Button("Grant Access…") {
                Task { await coordinator.requestAllPermissions() }
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
        Button("Quit VoiceType") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
