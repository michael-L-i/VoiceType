import SwiftUI
import VoiceTypeKit

/// Full-screen guided setup, shown as its own sidebar destination. States the
/// privacy promise up front, tracks progress through the three required grants,
/// and offers a per-permission action with live status — no silent prompting.
/// When everything's granted it flips to an "all set" state that sends you to
/// Home. (This replaces the old first-run onboarding window.)
struct SetupView: View {
    @Bindable var coordinator: DictationCoordinator
    /// Jump to Home once setup is complete.
    var goHome: () -> Void

    private var grantedCount: Int {
        Permission.allCases.filter { coordinator.status(for: $0) == .granted }.count
    }
    private var allGranted: Bool { grantedCount == Permission.allCases.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VT.Space.xl) {
                header
                if allGranted { allSet } else { progress }
                permissionList
                hotkeyHint
            }
            .frame(maxWidth: 560, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, VT.Space.xl)
            .padding(.vertical, 44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            LinearGradient(colors: [VT.tint.opacity(0.14), .clear],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 260)
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
        }
        // Grants toggled in System Settings fire no callback, so poll while the
        // tab is visible. Rows read observable status and re-render on real
        // changes only.
        .task {
            while !Task.isCancelled {
                coordinator.refreshPermissionStatuses()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: VT.Space.m) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(VT.tint)
            VStack(alignment: .leading, spacing: VT.Space.xs) {
                Text("Set up VoiceType")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text("Three quick grants and you're dictating anywhere.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            privacyPromise
        }
    }

    private var privacyPromise: some View {
        HStack(spacing: VT.Space.s) {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.green)
            Text("Your audio and transcripts stay on your Mac. Nothing leaves unless you turn on cloud.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(VT.Space.m)
        .background(.green.opacity(0.10), in: RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous))
        .padding(.top, VT.Space.xs)
    }

    // MARK: Progress (signature)

    private var progress: some View {
        VStack(alignment: .leading, spacing: VT.Space.s) {
            HStack {
                Text("\(grantedCount) of \(Permission.allCases.count) ready")
                    .font(.headline.monospacedDigit())
                Spacer()
                Text("Grant the rest below")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary.opacity(0.6))
                    Capsule()
                        .fill(VT.tint)
                        .frame(width: geo.size.width * progressFraction)
                }
            }
            .frame(height: 8)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: grantedCount)
        }
    }

    private var progressFraction: CGFloat {
        CGFloat(grantedCount) / CGFloat(Permission.allCases.count)
    }

    private var allSet: some View {
        HStack(spacing: VT.Space.m) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 30))
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("You're all set")
                    .font(.headline)
                Text("Everything VoiceType needs is granted.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Go to Home", action: goHome)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(VT.Space.l)
        .background(.green.opacity(0.10), in: RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                .strokeBorder(.green.opacity(0.30), lineWidth: 1))
    }

    // MARK: Permissions

    private var permissionList: some View {
        VStack(spacing: VT.Space.m) {
            ForEach(Permission.allCases, id: \.self) { permission in
                PermissionCard(permission: permission, coordinator: coordinator) {
                    Task { await coordinator.request(permission) }
                }
            }
        }
    }

    private var hotkeyHint: some View {
        VStack(alignment: .leading, spacing: VT.Space.s) {
            Label {
                Text("Hold **\(coordinator.settings.hotkey.trigger.displayName)** anywhere and start talking. Release to insert the text.")
            } icon: {
                Image(systemName: "keyboard").foregroundStyle(VT.tint)
            }
            Label {
                Text("Closing the window keeps VoiceType running — the hotkey still works. Click its Dock icon to bring it back.")
            } icon: {
                Image(systemName: "dock.rectangle").foregroundStyle(VT.tint)
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.top, VT.Space.s)
    }
}

/// One permission as a full-width card: a tinted glyph, its rationale, and a
/// status-aware action. Turns green and quiet once granted.
private struct PermissionCard: View {
    let permission: Permission
    @Bindable var coordinator: DictationCoordinator
    var onGrant: () -> Void

    private var status: PermissionStatus { coordinator.status(for: permission) }
    private var isGranted: Bool { status == .granted }

    var body: some View {
        HStack(alignment: .center, spacing: VT.Space.m) {
            ZStack {
                RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous)
                    .fill((isGranted ? Color.green : VT.tint).opacity(0.14))
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundStyle(isGranted ? .green : VT.tint)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(permission.title)
                    .font(.headline)
                Text(permission.why)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: VT.Space.s)

            statusControl
        }
        .padding(VT.Space.m)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                .strokeBorder((isGranted ? Color.green : .white).opacity(isGranted ? 0.30 : 0.08), lineWidth: 1))
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isGranted)
    }

    @ViewBuilder
    private var statusControl: some View {
        switch status {
        case .granted:
            Label("Granted", systemImage: "checkmark.circle.fill")
                .labelStyle(.titleAndIcon)
                .font(.callout.weight(.medium))
                .foregroundStyle(.green)
        case .notDetermined:
            VStack(alignment: .trailing, spacing: VT.Space.xs) {
                Button("Grant", action: onGrant)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                // Accessibility can get stuck "on but not working" after a
                // reinstall — a reset clears the stale record so a fresh grant
                // binds.
                if permission == .accessibility {
                    Button("Already on? Reset") {
                        Task { await coordinator.resetAccessibilityGrant() }
                    }
                    .buttonStyle(.link)
                    .controlSize(.small)
                    .font(.caption)
                    .help("If System Settings shows VoiceType enabled but it isn't working, reset and re-grant.")
                }
            }
        case .denied:
            Button("Open Settings") {
                coordinator.openSystemSettings(for: permission)
            }
            .controlSize(.large)
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
