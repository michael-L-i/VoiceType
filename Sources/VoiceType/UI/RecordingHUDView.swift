import SwiftUI

/// The signature surface: a small frosted pill that floats above whatever you're
/// working in while you dictate. It shows you're being heard (live waveform),
/// then the hand-off states (transcribing → cleaning → inserting), and a brief
/// confirmation. It never takes focus — text still lands in the app underneath.
struct RecordingHUDView: View {
    @Bindable var coordinator: DictationCoordinator

    private var kind: DictationStateKind { DictationStateKind(coordinator.state) }

    var body: some View {
        HStack(spacing: VT.Space.m) {
            leading
            label
        }
        .padding(.horizontal, VT.Space.l)
        .padding(.vertical, VT.Space.m)
        .frame(minWidth: 132)
        .background(
            Capsule(style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    Capsule(style: .continuous).strokeBorder(.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: coordinator.state)
        .fixedSize()
    }

    // MARK: Leading indicator

    @ViewBuilder
    private var leading: some View {
        switch kind {
        case .recording:
            WaveformView(level: coordinator.inputLevel, tint: VT.tint)
        case .working:
            ProgressView()
                .controlSize(.small)
                .tint(VT.tint)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(VT.success)
                .font(.system(size: 16, weight: .semibold))
                .transition(.scale.combined(with: .opacity))
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(VT.live)
                .font(.system(size: 15, weight: .semibold))
        case .idle:
            Image(systemName: "mic.fill")
                .foregroundStyle(.secondary)
                .font(.system(size: 14, weight: .semibold))
        }
    }

    // MARK: Label

    private var label: some View {
        Text(labelText)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(kind == .error ? AnyShapeStyle(VT.live) : AnyShapeStyle(.primary))
            .lineLimit(1)
            .fixedSize()
    }

    private var labelText: String {
        switch coordinator.state {
        case .recording: return "Listening"
        case .transcribing: return "Transcribing"
        case .cleaning: return "Polishing"
        case .injecting: return "Inserting"
        case .done: return "Done"
        case .error(let message): return message
        case .idle: return "Ready"
        }
    }
}
