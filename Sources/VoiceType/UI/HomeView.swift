import SwiftUI
import AppKit
import VoiceTypeKit

/// The main window: VoiceType's home. A calm status dashboard showing whether
/// the app is listening, the hotkey to dictate with, your last result, and a
/// scrollable history of recent dictations. This is the primary surface now that
/// VoiceType is a regular Dock app rather than a faceless menu-bar agent — the
/// floating HUD pill still does the in-the-moment feedback while you dictate.
struct HomeView: View {
    @Bindable var coordinator: DictationCoordinator

    private var stateKind: DictationStateKind { DictationStateKind(coordinator.state) }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: VT.Space.l) {
                    if !coordinator.permissionsGranted {
                        setupCallout
                    }
                    hero
                    if let result = coordinator.lastResult, !result.finalText.isEmpty {
                        lastResultSection(result)
                    }
                    historySection
                }
                .padding(VT.Space.l)
            }
            Divider()
            footer
        }
        .frame(minWidth: 440, idealWidth: 460, minHeight: 540, idealHeight: 620)
        .background(.background)
    }

    // MARK: Hero — the live status card

    private var hero: some View {
        FrostedCard {
            VStack(spacing: VT.Space.l) {
                statusIndicator
                VStack(spacing: VT.Space.xs) {
                    Text(statusTitle)
                        .font(.title2.weight(.semibold))
                    Text(statusSubtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                hotkeyBadge
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// A large circular state glyph: a live waveform while recording/working, a
    /// resting mic otherwise. Mirrors the HUD's vocabulary at window scale.
    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(VT.tint(for: stateKind).opacity(0.12))
                .frame(width: 92, height: 92)
            switch stateKind {
            case .recording, .working:
                WaveformView(level: waveformLevel, tint: VT.tint(for: stateKind), barCount: 5)
                    .frame(width: 44, height: 36)
            case .error:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(VT.live)
            case .idle, .done:
                Image(systemName: "mic.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(VT.tint)
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: stateKind)
    }

    private var waveformLevel: Float {
        stateKind == .recording ? coordinator.inputLevel : 0.45
    }

    private var statusTitle: String {
        switch stateKind {
        case .idle, .done: return coordinator.permissionsGranted ? "Ready to dictate" : "Almost ready"
        case .recording: return "Listening…"
        case .working: return "Transcribing…"
        case .error: return "Something went wrong"
        }
    }

    private var statusSubtitle: String {
        if case .error(let message) = coordinator.state { return message }
        if !coordinator.permissionsGranted { return "Finish setup to start dictating." }
        let verb = coordinator.settings.hotkey.holdToTalk ? "Hold" : "Tap"
        return "\(verb) your hotkey anywhere and start speaking — your words land in the focused app."
    }

    private var hotkeyBadge: some View {
        HStack(spacing: VT.Space.s) {
            Image(systemName: "keyboard")
            Text(coordinator.settings.hotkey.holdToTalk ? "Hold" : "Tap")
                .foregroundStyle(.secondary)
            Text(coordinator.settings.hotkey.trigger.displayName)
                .font(.callout.weight(.semibold).monospaced())
        }
        .font(.callout)
        .padding(.horizontal, VT.Space.m)
        .padding(.vertical, VT.Space.s)
        .background(.quaternary.opacity(0.5), in: Capsule())
    }

    // MARK: Setup callout

    private var setupCallout: some View {
        Button {
            coordinator.wantsOnboarding = true
        } label: {
            HStack(spacing: VT.Space.s) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Finish setup to start dictating")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                    Text("VoiceType needs microphone, speech, and accessibility access.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding(VT.Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Last result

    private func lastResultSection(_ result: PipelineResult) -> some View {
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
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                copy(result.finalText)
            } label: {
                Label("Copy", systemImage: "doc.on.doc").font(.caption)
            }
            .buttonStyle(.borderless)
        }
        .padding(VT.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous))
    }

    // MARK: History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: VT.Space.s) {
            HStack {
                Text("Recent")
                    .font(.headline)
                Spacer()
                if !coordinator.history.records.isEmpty {
                    Button("Clear") { coordinator.clearHistory() }
                        .buttonStyle(.borderless)
                        .font(.caption)
                }
            }

            if coordinator.history.records.isEmpty {
                Text(coordinator.settings.keepHistory
                     ? "Your recent dictations will appear here."
                     : "History is off — turn it on in Settings to keep recent dictations.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, VT.Space.s)
            } else {
                VStack(spacing: VT.Space.xs) {
                    ForEach(coordinator.history.records) { record in
                        historyRow(record)
                    }
                }
            }
        }
    }

    private func historyRow(_ record: DictationRecord) -> some View {
        HStack(alignment: .top, spacing: VT.Space.s) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.text)
                    .font(.callout)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(record.date.formatted(.relative(presentation: .numeric)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Button {
                copy(record.text)
            } label: {
                Image(systemName: "doc.on.doc").font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Copy")
        }
        .padding(VT.Space.s)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous))
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: VT.Space.m) {
            Button { coordinator.openSettings() } label: {
                Label("Settings", systemImage: "gearshape")
            }
            Button { coordinator.wantsOnboarding = true } label: {
                Label("Setup", systemImage: "person.badge.shield.checkmark")
            }
            Button { coordinator.checkForUpdates() } label: {
                Label("Check for Updates", systemImage: "arrow.triangle.2.circlepath")
            }
            Spacer()
        }
        .buttonStyle(.borderless)
        .labelStyle(.titleAndIcon)
        .font(.callout)
        .padding(VT.Space.m)
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
