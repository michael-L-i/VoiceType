import SwiftUI

/// The signature surface: a small frosted pill that floats above whatever you're
/// working in while you dictate. It shows a compact live waveform while work is
/// in flight, then disappears when dictation is complete. It never takes focus —
/// text still lands in the app underneath.
struct RecordingHUDView: View {
    @Bindable var coordinator: DictationCoordinator

    private var kind: DictationStateKind { DictationStateKind(coordinator.state) }

    var body: some View {
        HStack(spacing: VT.Space.m) {
            leading
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(VT.live)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .padding(.horizontal, VT.Space.l)
        .padding(.vertical, VT.Space.m)
        .frame(minWidth: kind == .error ? 132 : 44)
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
        case .recording, .working:
            WaveformView(level: waveformLevel, tint: VT.tint)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(VT.live)
                .font(.system(size: 15, weight: .semibold))
        case .idle, .done:
            Image(systemName: "mic.fill")
                .foregroundStyle(.secondary)
                .font(.system(size: 14, weight: .semibold))
        }
    }

    private var waveformLevel: Float {
        if case .recording = coordinator.state {
            return coordinator.inputLevel
        }
        return 0.45
    }

    private var errorMessage: String? {
        if case .error(let message) = coordinator.state {
            return message
        }
        return nil
    }
}
