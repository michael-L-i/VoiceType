import SwiftUI
import AppKit

/// Copies `text` to the pasteboard and confirms it with a little animation, then
/// settles back after a beat. Two looks:
///
/// - `.icon` — a bare glyph for dense rows (transcript history). The clipboard
///   icon smoothly morphs into a green checkmark.
/// - `.labeled` — an icon + word for result cards (audio transcription). On
///   click the whole control pops into a filled coral pill reading "Copied!".
///
/// Rapid re-clicks are handled: each press bumps a generation token, so an older
/// press's reset can't cut a newer confirmation short.
struct CopyButton: View {
    enum Style { case icon, labeled }

    let text: String
    var style: Style = .labeled
    /// Resting accent (and the labeled style's flash color).
    var tint: Color = VT.tint

    @State private var copied = false
    @State private var generation = 0

    var body: some View {
        Button(action: trigger) { label }
            .buttonStyle(.borderless)
            .help("Copy")
            .animation(.spring(response: 0.34, dampingFraction: 0.6), value: copied)
    }

    private func trigger() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        generation += 1
        let mine = generation
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if mine == generation { copied = false }
        }
    }

    @ViewBuilder private var label: some View {
        switch style {
        case .icon:
            Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(copied ? Color.green : Color.secondary)
                .scaleEffect(copied ? 1.22 : 1)

        case .labeled:
            HStack(spacing: VT.Space.xs) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .contentTransition(.symbolEffect(.replace))
                Text(copied ? "Copied!" : "Copy")
            }
            .font(.callout.weight(copied ? .semibold : .regular))
            .foregroundStyle(copied ? Color.white : tint)
            .padding(.horizontal, VT.Space.s)
            .padding(.vertical, VT.Space.xs)
            .background(Capsule(style: .continuous).fill(copied ? tint : .clear))
            .scaleEffect(copied ? 1.06 : 1)
        }
    }
}
