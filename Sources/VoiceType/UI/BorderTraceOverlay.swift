import SwiftUI

/// An indeterminate "comet" that travels continuously around a rounded-rect
/// border — used as a loading indicator riding the edge of a card while an
/// on-device generation runs (length is unknown, so it loops rather than fills).
///
/// Drawn with the same idioms as the rest of the app: a `TimelineView`-driven
/// animation (like `WaveformView`) stroking a trimmed rounded-rect path with the
/// brand gradient (like `RadialGauge`). Apply it as an `.overlay` on the card you
/// want it to hug, matching the card's `cornerRadius`.
struct BorderTraceOverlay: View {
    /// Match the host card's corner radius so the comet rides its rounded edge.
    var cornerRadius: CGFloat = VT.Radius.card
    var lineWidth: CGFloat = 2.5
    /// Seconds for one full lap of the border.
    var period: Double = 1.6
    /// Comet length as a fraction of the perimeter.
    var window: CGFloat = 0.22

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let progress = CGFloat(t.truncatingRemainder(dividingBy: period) / period)
            CometShape(cornerRadius: cornerRadius, progress: progress, window: window)
                .stroke(VT.brandGradient,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
        .allowsHitTesting(false)
    }
}

/// A short arc of a rounded-rect border starting at `progress` and spanning
/// `window` (both normalized to the perimeter). When the window crosses the
/// `1.0 → 0.0` seam it is drawn as two segments so the comet never blinks out at
/// the top edge. `trimmedPath` lets us assemble both pieces into one stroked path
/// with a continuous gradient and round caps.
private struct CometShape: Shape {
    var cornerRadius: CGFloat
    var progress: CGFloat
    var window: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let base = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).path(in: rect)
        let end = progress + window
        var p = Path()
        p.addPath(base.trimmedPath(from: progress, to: min(end, 1)))
        if end > 1 { p.addPath(base.trimmedPath(from: 0, to: end - 1)) }
        return p
    }
}
