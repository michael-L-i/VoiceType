import SwiftUI
import VoiceTypeKit

/// Menu-bar entry point. VoiceType has no dock icon and no main window — it is a
/// background agent you summon with a hotkey. The real wiring (hotkey, audio,
/// engines, injection) is attached to `DictationCoordinator` and grows in the
/// walking-skeleton milestone.
@main
struct VoiceTypeApp: App {
    @State private var coordinator = DictationCoordinator()

    var body: some Scene {
        MenuBarExtra {
            MenuContent(coordinator: coordinator)
        } label: {
            Image(systemName: coordinator.menuBarSymbol)
        }
        .menuBarExtraStyle(.menu)
    }
}
