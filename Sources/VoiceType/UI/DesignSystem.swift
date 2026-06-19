import SwiftUI
import VoiceTypeKit

/// The warm-distinctive design language: premium and system-first, but with a
/// warm coral/amber brand instead of the sea-of-blue default. We lean on macOS
/// materials, add a restrained coral tint, and keep a consistent spacing/radius
/// scale so every surface feels of a piece.
enum VT {
    // MARK: Brand

    /// The brand coral used for active/affirmative accents (mark, focus rings).
    static let tint = Color(red: 0.95, green: 0.45, blue: 0.28)
    /// A lighter amber, paired with `tint` for warm gradients.
    static let tintAmber = Color(red: 1.0, green: 0.66, blue: 0.40)
    /// The familiar "live" red, used only for the recording dot. Kept distinct
    /// (pink-red) from the brand coral (orange) so the two never read alike.
    static let live = Color(red: 0.94, green: 0.33, blue: 0.36)

    /// The signature warm gradient: amber → coral, top-leading to bottom-trailing.
    static let brandGradient = LinearGradient(
        colors: [tintAmber, tint],
        startPoint: .topLeading, endPoint: .bottomTrailing)
    /// The dictation HUD pill fill: one fixed, opaque, relatively dark gray so the
    /// pill reads identically over any background (no adaptive material).
    static let hudFill = Color(red: 0.15, green: 0.15, blue: 0.17)

    /// A faint divider/empty-cell ink, used for hairlines and zero-state fills.
    static let hairline = Color.primary.opacity(0.08)

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

/// The VoiceType brand mark: the "utterance wave" — vertical rounded bars whose
/// envelope traces a horizontal pointed oval (a lens), tall in the centre and
/// tapering to point-dots at each end. Matches the app icon's glyph exactly, so
/// the sidebar, hero, and Dock all speak with one voice. Draws to fill its
/// frame; give it a ~2:1 (width:height) box for the intended proportions.
struct BrandMark: View {
    /// Fill colour for the bars (e.g. `VT.tint` on light surfaces, `.white` on
    /// the coloured hero).
    var color: Color = VT.tint
    /// Odd counts keep a true centre bar. 9 matches the app icon.
    var barCount: Int = 9

    var body: some View {
        Canvas { ctx, size in
            let n = barCount
            let pitch = size.width / Double(n)
            let barW = pitch * 0.52
            let midY = size.height / 2
            let maxHalf = size.height / 2
            let minHalf = barW / 2

            for i in 0..<n {
                let t = Double(i) / Double(n - 1) * 2.0 - 1.0   // -1 … 1
                let f = 1.0 - t * t                             // pointed-oval envelope
                let half = max(minHalf, maxHalf * f)
                let x = pitch * (Double(i) + 0.5)
                let rect = CGRect(x: x - barW / 2, y: midY - half, width: barW, height: half * 2)
                ctx.fill(Path(roundedRect: rect, cornerRadius: barW / 2), with: .color(color))
            }
        }
        .aspectRatio(2.0, contentMode: .fit)
        .accessibilityLabel("VoiceType")
    }
}

/// A page title + optional subtitle, used at the top of each main surface so
/// every page opens the same calm way.
struct PageHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: VT.Space.xs) {
            Text(title)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
            if let subtitle {
                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// A small uppercase section label (the quiet caption above grouped content).
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
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
