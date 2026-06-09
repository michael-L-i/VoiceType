import SwiftUI
import VoiceTypeKit

/// The dropdown shown from the menu-bar icon. Minimal for now; the settings and
/// onboarding milestone enriches it.
struct MenuContent: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        Text(coordinator.statusText)
            .font(.headline)

        if let result = coordinator.lastResult, !result.finalText.isEmpty {
            Divider()
            Text("Last: \(result.finalText)")
                .lineLimit(2)
        }

        Divider()

        Text("Hold \(coordinator.settings.hotkey.trigger.displayName) to dictate")

        Divider()

        Button("Quit VoiceType") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
