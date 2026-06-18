import SwiftUI
import VoiceTypeKit

/// The calm-native design language: quiet, premium, system-first. We lean on
/// macOS materials and the system accent, add a restrained brand tint, and keep
/// a consistent spacing/radius scale so every surface feels of a piece.
enum VT {
    // MARK: Brand

    /// A calm indigo used for active/affirmative accents (waveform, focus rings).
    static let tint = Color(red: 0.36, green: 0.46, blue: 0.92)
    /// The familiar "live" red, used only for the recording dot.
    static let live = Color(red: 0.94, green: 0.33, blue: 0.36)
    /// The dictation HUD pill fill: one fixed, opaque, relatively dark gray so the
    /// pill reads identically over any background (no adaptive material).
    static let hudFill = Color(red: 0.15, green: 0.15, blue: 0.17)

    // MARK: Geometry

    enum Radius {
        static let pill: CGFloat = 999
        static let card: CGFloat = 16
        static let control: CGFloat = 10
    }

    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 20
        static let xl: CGFloat = 32
    }

    // MARK: Tint for a dictation state

    /// The accent color that represents a given pipeline state.
    static func tint(for state: DictationStateKind) -> Color {
        switch state {
        case .recording: return live
        case .working: return tint
        case .done: return .secondary
        case .error: return live
        case .idle: return .secondary
        }
    }
}

/// A coarse grouping of `DictationState` for presentation (keeps the HUD/menu
/// from switching over every fine-grained case).
enum DictationStateKind {
    case idle, recording, working, done, error

    init(_ state: DictationState) {
        switch state {
        case .idle: self = .idle
        case .recording: self = .recording
        case .transcribing, .cleaning, .injecting: self = .working
        case .done: self = .done
        case .error: self = .error
        }
    }
}

// MARK: - Reusable surfaces

/// A frosted rounded card used across onboarding and settings detail surfaces.
struct FrostedCard<Content: View>: View {
    var padding: CGFloat = VT.Space.l
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            )
    }
}

/// A single headline statistic: a large monospaced-digit value beside its
/// label, with an optional leading glyph. Used for the Home stats card
/// (total words / WPM / streak).
struct StatRow: View {
    let value: String
    let label: String
    var symbol: String? = nil

    var body: some View {
        HStack(spacing: VT.Space.m) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.body)
                    .foregroundStyle(VT.tint)
                    .frame(width: 22)
            }
            Text(value)
                .font(.system(.title, design: .rounded).weight(.semibold).monospacedDigit())
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }
}
