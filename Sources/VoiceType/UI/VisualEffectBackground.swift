import SwiftUI
import AppKit

/// A frosted background that never dims. SwiftUI's `.regularMaterial` falls back
/// to its darker *inactive* appearance when its window is not key — and the HUD
/// lives in a non-activating panel that never becomes key, so it would otherwise
/// look noticeably darker when you swipe between Spaces or windows. Wrapping
/// `NSVisualEffectView` lets us pin `state = .active` so the frost stays one
/// consistent gray everywhere.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        apply(to: view)
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        apply(to: view)
    }

    private func apply(to view: NSVisualEffectView) {
        view.material = material
        view.blendingMode = blendingMode
        // The whole point: never drop to the darker inactive look.
        view.state = .active
        view.isEmphasized = false
    }
}
