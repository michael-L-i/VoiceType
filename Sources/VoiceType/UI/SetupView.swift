import SwiftUI
import VoiceTypeKit

/// Guided setup, shown as its own sidebar destination. One step at a time:
/// granted permissions collapse to slim "ready" rows, the first ungranted one is
/// the single focused card, and once all three are granted a short "you're ready"
/// card shows before the view hands off to the Settings page (where the dictation
/// key now lives). Privacy and window behavior are quiet footnotes. Status polls
/// live so System Settings changes reflect without a prompt.
struct SetupView: View {
    @Bindable var coordinator: DictationCoordinator
    /// Called once all permissions are granted — hands the user off to Settings.
    var onComplete: () -> Void

    /// Guards the one-shot auto-handoff so it fires only when the final grant lands.
    @State private var handedOff = false

    private var granted: [Permission] {
        Permission.allCases.filter { coordinator.status(for: $0) == .granted }
    }
    private var pending: [Permission] {
        Permission.allCases.filter { coordinator.status(for: $0) != .granted }
    }
    private var grantedCount: Int { granted.count }
    private var allGranted: Bool { pending.isEmpty }

    /// The one thing in focus: the first ungranted permission, else the done card.
    private enum Step: Hashable { case permission(Permission), done }
    private var currentStep: Step {
        if let next = pending.first { return .permission(next) }
        return .done
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VT.Space.l) {
                header

                ForEach(granted, id: \.self) { completedRow($0) }

                focusedCard
                    .id(currentStep)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity))

                if pending.count > 1 { upcomingHint }

                footnotes
            }
            .frame(maxWidth: 560, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(VT.Space.xl)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentStep)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: grantedCount)
        }
        .background {
            LinearGradient(colors: [VT.tint.opacity(0.12), .clear],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 240)
                .frame(maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
        }
        // Grants toggled in System Settings fire no callback, so poll while visible.
        .task {
            while !Task.isCancelled {
                coordinator.refreshPermissionStatuses()
                try? await Task.sleep(for: .seconds(1))
            }
        }
        // The moment the final grant lands, slide the user into Settings (once).
        // Bound to the always-mounted body so it fires on the false→true flip,
        // unlike the done card, which only appears after setup is already complete.
        .onChange(of: allGranted) { _, done in
            guard done, !handedOff else { return }
            handedOff = true
            Task {
                try? await Task.sleep(for: .milliseconds(700))
                onComplete()
            }
        }
    }

    // MARK: Header (slim)

    private var header: some View {
        VStack(alignment: .leading, spacing: VT.Space.m) {
            HStack(spacing: VT.Space.m) {
                BrandMark(color: .white)
                    .frame(width: 26, height: 13)
                    .frame(width: 44, height: 44)
                    .background(VT.brandGradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Set up VoiceType")
                        .font(.system(.title, design: .rounded).weight(.bold))
                    Text(allGranted
                         ? "You're all set!"
                         : "\(grantedCount) of \(Permission.allCases.count) ready")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Spacer(minLength: 0)
            }
            progressCapsule
        }
    }

    private var progressCapsule: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary.opacity(0.5))
                Capsule().fill(VT.tint)
                    .frame(width: max(6, geo.size.width * CGFloat(grantedCount) / CGFloat(Permission.allCases.count)))
            }
        }
        .frame(height: 6)
    }

    // MARK: Completed rows

    private func completedRow(_ permission: Permission) -> some View {
        HStack(spacing: VT.Space.s) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            Text(permission.title).font(.callout.weight(.medium))
            Spacer()
            Text("Ready").font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, VT.Space.m)
        .padding(.vertical, VT.Space.s)
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: Focused card

    @ViewBuilder
    private var focusedCard: some View {
        switch currentStep {
        case .permission(let permission):
            PermissionStepCard(permission: permission, coordinator: coordinator) {
                Task { await coordinator.request(permission) }
            }
        case .done:
            doneCard
        }
    }

    /// Shown for a beat once everything is granted, then we slide into Settings.
    private var doneCard: some View {
        VStack(alignment: .leading, spacing: VT.Space.m) {
            HStack(spacing: VT.Space.s) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(VT.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("VoiceType is ready")
                        .font(.system(.headline, design: .rounded))
                    Text("Opening Settings so you can pick your dictation key…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            Button("Open Settings", action: onComplete)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(VT.tint)
        }
        .padding(VT.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
            .strokeBorder(VT.hairline, lineWidth: 1))
    }

    // MARK: Upcoming + footnotes

    private var upcomingHint: some View {
        HStack(spacing: VT.Space.xs) {
            Image(systemName: "arrow.turn.down.right")
            Text("Next: \(pending[1].title)")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.leading, VT.Space.xs)
    }

    private var footnotes: some View {
        VStack(alignment: .leading, spacing: VT.Space.xs) {
            footnote("lock.shield.fill", .green,
                     "Your audio and transcripts stay on your Mac. Nothing ever leaves the device.")
            footnote("dock.rectangle", .secondary,
                     "Closing the window keeps VoiceType running — the key still works. Click its Dock icon to bring it back.")
        }
        .padding(.top, VT.Space.s)
    }

    private func footnote(_ symbol: String, _ tint: Color, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: VT.Space.s) {
            Image(systemName: symbol).foregroundStyle(tint).font(.caption)
            Text(text).font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Focused permission card

/// The single in-focus permission: a large glyph, its rationale, and the action
/// for its current state (grant / open settings / reset). Granted permissions
/// never render here — they collapse to a slim row in `SetupView`.
private struct PermissionStepCard: View {
    let permission: Permission
    @Bindable var coordinator: DictationCoordinator
    var onGrant: () -> Void

    private var status: PermissionStatus { coordinator.status(for: permission) }

    var body: some View {
        VStack(alignment: .leading, spacing: VT.Space.m) {
            HStack(spacing: VT.Space.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous)
                        .fill(VT.tint.opacity(0.14))
                    Image(systemName: symbol)
                        .font(.system(size: 24))
                        .foregroundStyle(VT.tint)
                }
                .frame(width: 56, height: 56)
                VStack(alignment: .leading, spacing: 3) {
                    Text(permission.title).font(.title3.weight(.semibold))
                    Text(permission.why).font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            statusControl
        }
        .padding(VT.Space.l)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
            .strokeBorder(VT.tint.opacity(0.25), lineWidth: 1))
    }

    @ViewBuilder
    private var statusControl: some View {
        switch status {
        case .notDetermined:
            HStack(spacing: VT.Space.m) {
                Button("Grant access", action: onGrant)
                    .buttonStyle(.borderedProminent).controlSize(.large).tint(VT.tint)
                Spacer(minLength: 0)
            }
        case .denied:
            HStack(spacing: VT.Space.m) {
                Button("Open System Settings") {
                    coordinator.openSystemSettings(for: permission)
                }
                .buttonStyle(.borderedProminent).controlSize(.large).tint(VT.tint)
                Text("Denied — enable it in System Settings.")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        case .granted:
            EmptyView()
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

