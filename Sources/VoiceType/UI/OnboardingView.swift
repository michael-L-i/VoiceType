import SwiftUI
import VoiceTypeKit

/// First-run welcome + guided permissions. Shown automatically on launch when
/// core grants are missing, and reopenable from the menu. It states the privacy
/// promise up front and walks the three permissions with live status and a
/// per-row Grant button — no silent prompting.
struct OnboardingView: View {
    @Bindable var coordinator: DictationCoordinator
    /// Called when the user dismisses the window (Done / Start dictating).
    var onClose: () -> Void

    /// Bumped to force a status re-read after the system grant dialogs return.
    @State private var refreshTick = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            Divider()

            VStack(spacing: 12) {
                ForEach(Permission.allCases, id: \.self) { permission in
                    PermissionRow(permission: permission, coordinator: coordinator) {
                        Task {
                            await coordinator.request(permission)
                            refreshTick += 1
                        }
                    }
                }
            }
            .id(refreshTick)

            Divider()

            footer
        }
        .padding(28)
        .frame(width: 460)
        .background(alignment: .top) {
            LinearGradient(colors: [VT.tint.opacity(0.16), .clear],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 160)
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(VT.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome to VoiceType")
                        .font(.title2.weight(.semibold))
                    Text("Speak anywhere, get clean text instantly.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Label {
                Text("Your audio and transcripts stay on your Mac. Nothing is sent to the cloud unless you turn it on.")
            } icon: {
                Image(systemName: "lock.shield.fill").foregroundStyle(.green)
            }
            .font(.callout)
            .padding(.top, 4)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                Text("Hold **\(coordinator.settings.hotkey.trigger.displayName)** anywhere and start talking. Release to insert the text.")
            } icon: {
                Image(systemName: "keyboard")
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            Label {
                Text("VoiceType has no Dock icon — it lives in your menu bar. Look for the \(Image(systemName: "mic")) up top.")
            } icon: {
                Image(systemName: "menubar.arrow.up.rectangle")
            }
            .font(.callout)
            .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button(coordinator.permissionsGranted ? "Start Dictating" : "Continue") {
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            }
        }
    }
}

/// One permission with its rationale, live status badge, and a Grant button that
/// disappears once granted.
private struct PermissionRow: View {
    let permission: Permission
    @Bindable var coordinator: DictationCoordinator
    var onGrant: () -> Void

    private var status: PermissionStatus { Permissions.status(for: permission) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18))
                .frame(width: 26)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(permission.title)
                    .font(.headline)
                Text(permission.why)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            statusControl
        }
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var statusControl: some View {
        switch status {
        case .granted:
            Label("Granted", systemImage: "checkmark.circle.fill")
                .labelStyle(.titleAndIcon)
                .font(.caption.weight(.medium))
                .foregroundStyle(.green)
        case .notDetermined:
            Button("Grant", action: onGrant)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        case .denied:
            Button("Open Settings") {
                coordinator.openSystemSettings(for: permission)
            }
            .controlSize(.small)
            .help("Permission was denied. Enable it in System Settings.")
        }
    }

    private var symbol: String {
        switch permission {
        case .microphone: return "mic.fill"
        case .speech: return "text.bubble.fill"
        case .accessibility: return "accessibility"
        }
    }
}
