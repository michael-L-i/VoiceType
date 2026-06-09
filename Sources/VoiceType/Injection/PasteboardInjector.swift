import AppKit
import Carbon.HIToolbox
import VoiceTypeKit

/// Inserts text into the focused app by writing to the pasteboard and
/// synthesizing ⌘V, then restoring the previous clipboard contents.
///
/// Paste is the most reliable cross-app insertion path (works in editors,
/// browsers, chat apps) and preserves Unicode. Synthesizing the keystroke
/// requires Accessibility consent.
struct PasteboardInjector: TextInjector {
    func inject(_ text: String) async throws {
        guard !text.isEmpty else { return }
        guard AXIsProcessTrusted() else { throw InjectionError.notTrusted }

        await MainActor.run {
            let pasteboard = NSPasteboard.general
            // Snapshot existing contents so we can restore them.
            let previous = pasteboard.string(forType: .string)

            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)

            Self.sendCommandV()

            // Restore the user's clipboard shortly after the paste lands.
            let saved = previous
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                pasteboard.clearContents()
                if let saved { pasteboard.setString(saved, forType: .string) }
            }
        }
    }

    /// Post a synthetic ⌘V to the focused application.
    private static func sendCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKey = CGKeyCode(kVK_ANSI_V)

        guard let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false) else {
            return
        }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cgAnnotatedSessionEventTap)
        up.post(tap: .cgAnnotatedSessionEventTap)
    }
}
