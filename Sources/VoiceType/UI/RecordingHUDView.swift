import SwiftUI

/// The signature surface: a small dark-gray pill that floats above whatever
/// you're working in. It is always present — a small resting oval that expands
/// into a compact live waveform while you dictate, then settles back to rest. It
/// never takes focus — text still lands in the app underneath.
struct RecordingHUDView: View {
    @Bindable var coordinator: DictationCoordinator

    private var kind: DictationStateKind { DictationStateKind(coordinator.state) }

    var body: some View {
        pill
            // Bottom-center the pill inside the fixed canvas so it grows *upward*
            // from the screen edge instead of the window resizing under it.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            // Quick but smooth: one spring drives the size and padding so there's
            // no bad intermediate frame entering record.
            .animation(.spring(response: 0.22, dampingFraction: 0.85), value: kind)
    }

    private var pill: some View {
        HStack(spacing: VT.Space.m) {
            leading
                .transition(contentTransition)
            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(VT.live)
                    .lineLimit(1)
                    .fixedSize()
                    .transition(contentTransition)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(minWidth: minWidth)
        .background(
            Capsule(style: .continuous)
                .fill(VT.hudFill)
                .overlay(
                    Capsule(style: .continuous).strokeBorder(.white.opacity(0.35), lineWidth: 1)
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
            // The resting state holds nothing at all: an empty thin sliver,
            // unmistakably "not recording" while signalling the app is alive.
            EmptyView()
        }
    }

    /// The content (waveform / error glyph) fades in slightly *after* the oval
    /// has grown so it never pops in early, and clears immediately on the way
    /// back to rest so it vanishes as the oval shrinks.
    private var contentTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.animation(.easeOut(duration: 0.14).delay(0.06)),
            removal: .opacity.animation(.easeOut(duration: 0.08))
        )
    }

    // MARK: Sizing

    /// The resting pill is deliberately small; active states are roomier and the
    /// error state widest to fit its message.
    private var minWidth: CGFloat {
        switch kind {
        case .error: return 132
        case .idle, .done: return 40
        case .recording, .working: return 52
        }
    }

    private var horizontalPadding: CGFloat {
        switch kind {
        case .idle, .done: return VT.Space.s
        case .recording, .working: return VT.Space.l
        case .error: return VT.Space.xl
        }
    }

    /// Resting is a thin sliver; active/error states stand taller so the
    /// waveform and message have room to breathe.
    private var verticalPadding: CGFloat {
        switch kind {
        case .idle, .done: return 3
        default: return VT.Space.s
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
