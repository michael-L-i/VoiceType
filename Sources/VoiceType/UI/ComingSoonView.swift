import SwiftUI

/// A calm placeholder for sidebar destinations that aren't built yet (Insights,
/// Scratchpad). Keeps the navigation honest without pretending the page exists.
struct ComingSoonView: View {
    let title: String
    let symbol: String
    let blurb: String

    var body: some View {
        VStack(spacing: VT.Space.m) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title2.weight(.semibold))
            Text(blurb)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Coming soon")
                .font(.caption.weight(.semibold))
                .foregroundStyle(VT.tint)
                .padding(.horizontal, VT.Space.m)
                .padding(.vertical, VT.Space.xs)
                .background(VT.tint.opacity(0.12), in: Capsule())
        }
        .padding(VT.Space.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
