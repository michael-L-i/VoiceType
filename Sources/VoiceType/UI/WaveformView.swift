import SwiftUI

/// A tiny live equalizer for the recording HUD. Bars react to the current mic
/// `level` with a gentle per-bar shimmer so the pill feels alive even during
/// quiet moments. Purely decorative — no audio is stored or analyzed here.
struct WaveformView: View {
    /// Current input level, 0...1.
    var level: Float
    var tint: Color
    var barCount: Int = 5

    private let maxHeight: CGFloat = 24
    private let minHeight: CGFloat = 4
    private let barWidth: CGFloat = 3

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<barCount, id: \.self) { i in
                    Capsule(style: .continuous)
                        .fill(tint)
                        .frame(width: barWidth, height: height(for: i, t: t))
                }
            }
            .frame(height: maxHeight)
            .animation(.easeOut(duration: 0.08), value: level)
        }
    }

    private func height(for index: Int, t: TimeInterval) -> CGFloat {
        // Center bars swing more than the edges, like a real meter.
        let center = Double(barCount - 1) / 2
        let distance = abs(Double(index) - center)
        let weight = 1.0 - (distance / Double(barCount)) * 0.6

        // A slow per-bar phase keeps things shimmering without an audio FFT.
        let phase = Double(index) * 0.9
        let shimmer = 0.65 + 0.35 * sin(t * 6.0 + phase)

        let lvl = Double(max(0, min(1, level)))
        // Light compression so soft speech still moves the bars.
        let shaped = pow(lvl, 0.6)
        let dynamic = shaped * weight * shimmer
        let h = Double(minHeight) + dynamic * Double(maxHeight - minHeight)
        return CGFloat(min(Double(maxHeight), max(Double(minHeight), h)))
    }
}
