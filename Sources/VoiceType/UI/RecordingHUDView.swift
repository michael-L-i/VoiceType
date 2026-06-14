import SwiftUI

/// The signature surface: a small frosted pill that floats above whatever you're
/// working in. It is always present — a small resting oval that expands into a
/// compact live waveform while you dictate, then settles back to rest. It never
/// takes focus — text still lands in the app underneath.
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
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, VT.Space.s)
        .frame(minWidth: minWidth)
        .background(
            Capsule(style: .continuous)
                .fill(.regularMaterial)
                .overlay(
                    Capsule(style: .continuous).strokeBorder(.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
        )
        .fixedSize()
        // Transparent breathing room so the capsule's soft drop shadow fades
        // out naturally instead of being hard-clipped to the panel bounds —
        // which is what showed up as a faint rectangle around the oval.
        .padding(VT.Space.l)
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
            // The resting state: a tiny, dim set of dots — unmistakably "not
            // recording" (no waveform, no tint, no mic) while signalling the app
            // is alive and ready.
            RestingIndicator()
        }
    }

    // MARK: Sizing

    /// The resting pill is deliberately small; active states are roomier and the
    /// error state widest to fit its message.
    private var minWidth: CGFloat {
        switch kind {
        case .error: return 132
        case .idle, .done: return 16
        case .recording, .working: return 64
        }
    }

    private var horizontalPadding: CGFloat {
        switch kind {
        case .idle, .done: return VT.Space.l
        default: return VT.Space.xl
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

/// The resting-state glyph: three small, dim dots. Calm and static — no
/// animation, no tint — so the always-present pill never reads as "recording".
private struct RestingIndicator: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(.secondary)
                    .frame(width: 3, height: 3)
            }
        }
        .opacity(0.55)
        .frame(height: 4)
    }
}
