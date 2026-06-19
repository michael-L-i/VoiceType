import SwiftUI

/// A 270° brand-gradient arc gauge with a big monospaced value in the center —
/// the Stats page's headline number (average words per minute). The arc fills to
/// `value / maxValue`; everything past it stays a faint track.
struct RadialGauge: View {
    let value: Double
    var maxValue: Double = 200          // wpm full-scale
    var label: String
    var valueText: String
    var gradient: Gradient = Gradient(colors: [VT.tintAmber, VT.tint])
    var lineWidth: CGFloat = 12

    /// Fraction of the 270° sweep the arc fills.
    private var fraction: CGFloat {
        guard maxValue > 0 else { return 0 }
        return min(1, max(0, CGFloat(value / maxValue)))
    }
    private let span: CGFloat = 0.75    // 270° of the circle

    var body: some View {
        ZStack {
            // Track + value arc, rotated so the 90° gap sits at the bottom.
            Group {
                Circle()
                    .trim(from: 0, to: span)
                    .stroke(Color.primary.opacity(0.08),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                Circle()
                    .trim(from: 0, to: span * fraction)
                    .stroke(
                        AngularGradient(gradient: gradient, center: .center,
                                        startAngle: .degrees(0), endAngle: .degrees(360 * Double(span))),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
            .rotationEffect(.degrees(135))

            VStack(spacing: 2) {
                Text(valueText)
                    .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(valueText) \(label)")
    }
}

#if DEBUG
#Preview("Radial gauge") {
    HStack(spacing: 32) {
        RadialGauge(value: 142, label: "WPM", valueText: "142").frame(width: 140, height: 140)
        RadialGauge(value: 38, label: "WPM", valueText: "38").frame(width: 140, height: 140)
    }
    .padding(40)
}
#endif
