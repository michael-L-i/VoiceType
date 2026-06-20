import SwiftUI
import VoiceTypeKit

/// Guided setup, shown as its own sidebar destination. One step at a time:
/// granted permissions collapse to slim "ready" rows, the first ungranted one is
/// the single focused card, and once all three are granted the focus becomes the
/// push-to-talk key picker — the last step before Home. Privacy and window
/// behavior are quiet footnotes. Status polls live so System Settings changes
/// reflect without a prompt.
struct SetupView: View {
    @Bindable var coordinator: DictationCoordinator
    /// Jump to Home once setup is complete.
    var goHome: () -> Void

    private var granted: [Permission] {
        Permission.allCases.filter { coordinator.status(for: $0) == .granted }
    }
    private var pending: [Permission] {
        Permission.allCases.filter { coordinator.status(for: $0) != .granted }
    }
    private var grantedCount: Int { granted.count }
    private var allGranted: Bool { pending.isEmpty }

    /// The one thing in focus: the first ungranted permission, else the key step.
    private enum Step: Hashable { case permission(Permission), hotkey }
    private var currentStep: Step {
        if let next = pending.first { return .permission(next) }
        return .hotkey
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
                         ? "You're all set — pick your key below."
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
        case .hotkey:
            VStack(alignment: .leading, spacing: VT.Space.l) {
                HotkeySelector(coordinator: coordinator)
                Button("Go to Home", action: goHome)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(VT.tint)
            }
            .padding(VT.Space.l)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                .strokeBorder(VT.hairline, lineWidth: 1))
        }
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
                     "Your audio and transcripts stay on your Mac. Nothing leaves unless you turn on cloud.")
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
                if permission == .accessibility {
                    Button("Already on? Reset") {
                        Task { await coordinator.resetAccessibilityGrant() }
                    }
                    .buttonStyle(.link).controlSize(.small).font(.caption)
                    .help("If System Settings shows VoiceType enabled but it isn't working, reset and re-grant.")
                }
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

// MARK: - Hotkey selector

/// Pick the push-to-talk key and hold-vs-tap, right here on Setup. Bound straight
/// to `coordinator.settings.hotkey` — the coordinator's `didSet` re-arms the
/// global monitor, so a change takes effect immediately.
private struct HotkeySelector: View {
    @Bindable var coordinator: DictationCoordinator

    private var hotkey: Hotkey { coordinator.settings.hotkey }

    var body: some View {
        VStack(alignment: .leading, spacing: VT.Space.m) {
            SectionLabel("Dictation key")

            HStack(spacing: VT.Space.s) {
                ForEach(Hotkey.Trigger.allCases, id: \.self) { trigger in
                    keyCap(trigger)
                }
            }

            Picker("", selection: $coordinator.settings.hotkey.holdToTalk) {
                Text("Hold to talk").tag(true)
                Text("Tap to toggle").tag(false)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 300, alignment: .leading)
            .padding(.top, VT.Space.xs)

            Text(previewLine)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func keyCap(_ trigger: Hotkey.Trigger) -> some View {
        let selected = hotkey.trigger == trigger
        return Button {
            coordinator.settings.hotkey.trigger = trigger
        } label: {
            VStack(spacing: 3) {
                Text(trigger.keyCap)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                Text(trigger.shortName)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .padding(.horizontal, 4)
            .background(selected ? AnyShapeStyle(VT.tint) : AnyShapeStyle(.regularMaterial),
                        in: RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous))
            .foregroundStyle(selected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .overlay(RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous)
                .strokeBorder(selected ? Color.clear : VT.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: selected)
    }

    private var previewLine: String {
        let verb = hotkey.holdToTalk ? "Hold" : "Tap"
        let tail = hotkey.holdToTalk
            ? "anywhere and start talking — release to insert."
            : "anywhere to start, then tap again to insert."
        return "\(verb) \(hotkey.trigger.displayName) \(tail)"
    }
}
