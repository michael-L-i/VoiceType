import SwiftUI
import VoiceTypeKit

/// The menu-bar dropdown, rendered as a designed frosted panel (`.window`
/// style): a compact status card with the hotkey reminder, the last result, and
/// quick actions. Calm-native: materials, SF Symbols, a restrained accent.
struct MenuContent: View {
    @Bindable var coordinator: DictationCoordinator
    @Environment(\.openSettings) private var openSettings

    private var stateKind: DictationStateKind { DictationStateKind(coordinator.state) }

    var body: some View {
        VStack(alignment: .leading, spacing: VT.Space.m) {
            header

            if !coordinator.permissionsGranted {
                setupCallout
            }

            hotkeyHint

            if let result = coordinator.lastResult, !result.finalText.isEmpty {
                lastResultCard(result)
            }

            Divider().padding(.horizontal, -VT.Space.m)

            Button {
                coordinator.checkForUpdates()
            } label: {
                Label("Check for Updates…", systemImage: "arrow.triangle.2.circlepath")
                    .font(.callout)
            }
            .buttonStyle(.borderless)

            footer
        }
        .padding(VT.Space.m)
        .frame(width: 308)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: VT.Space.s) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(VT.tint)
            Text("VoiceType")
                .font(.headline)
            Spacer()
            statusPill
        }
    }

    private var statusPill: some View {
        HStack(spacing: 5) {
            if stateKind == .recording {
                WaveformView(level: coordinator.inputLevel, tint: VT.tint, barCount: 4)
            } else {
                Circle()
                    .fill(VT.tint(for: stateKind))
                    .frame(width: 7, height: 7)
                Text(shortStatus)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, VT.Space.s)
        .padding(.vertical, 3)
        .background(.quaternary.opacity(0.5), in: Capsule())
    }

    private var shortStatus: String {
        switch coordinator.state {
        case .idle: return "Ready"
        case .recording: return "Listening"
        case .transcribing: return "Transcribing"
        case .cleaning: return "Polishing"
        case .injecting: return "Inserting"
        case .done: return "Done"
        case .error: return "Error"
        }
    }

    // MARK: Setup callout

    private var setupCallout: some View {
        Button {
            coordinator.wantsOnboarding = true
        } label: {
            HStack(spacing: VT.Space.s) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Finish setup to start dictating")
                    .font(.callout)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding(VT.Space.s)
            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Hotkey hint

    private var hotkeyHint: some View {
        HStack(spacing: VT.Space.s) {
            Image(systemName: "keyboard")
                .foregroundStyle(.secondary)
            Text("\(hotkeyVerb) \(Text(coordinator.settings.hotkey.trigger.displayName).bold().foregroundColor(.primary)) to dictate")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .font(.callout)
    }

    private var hotkeyVerb: String {
        coordinator.settings.hotkey.holdToTalk ? "Hold" : "Tap"
    }

    // MARK: Last result

    private func lastResultCard(_ result: PipelineResult) -> some View {
        VStack(alignment: .leading, spacing: VT.Space.s) {
            HStack {
                Text("Last dictation")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(result.metrics.timeToText * 1000)) ms")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(result.finalText)
                .font(.callout)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(result.finalText, forType: .string)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
        .padding(VT.Space.m)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous))
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: VT.Space.m) {
            Button {
                openSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            Button {
                coordinator.wantsOnboarding = true
            } label: {
                Label("Setup", systemImage: "person.badge.shield.checkmark")
            }
            Spacer()
            Button(role: .destructive) {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .keyboardShortcut("q")
        }
        .buttonStyle(.borderless)
        .labelStyle(.titleAndIcon)
        .font(.callout)
    }
}
