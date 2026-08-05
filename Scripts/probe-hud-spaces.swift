#!/usr/bin/env swift
// Diagnose "the recording pill stopped appearing on this desktop".
//
// Asks the window server which Spaces VoiceType's HUD panel is actually a
// member of. This is the only way to tell a healthy panel from a wedged one:
// `NSWindow.collectionBehavior` reads back whatever we assigned, even when the
// server disagrees, so the app cannot diagnose itself.
//
// Runs against the LIVE running app, cross-process and read-only — no rebuild,
// no relaunch, no permission reset.
//
// Usage:  swift Scripts/probe-hud-spaces.swift
//
// Read it as: the panel should be a member of EVERY Space. One Space means it
// got pinned — that's the bug. The control panel this probe creates for itself
// is the yardstick: it uses the same configuration, so whatever it reports is
// what "healthy" looks like on this Mac right now.
import AppKit

typealias CGSConnectionID = Int32

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSGetActiveSpace")
func CGSGetActiveSpace(_ cid: CGSConnectionID) -> UInt64

@_silgen_name("CGSCopySpacesForWindows")
func CGSCopySpacesForWindows(
    _ cid: CGSConnectionID, _ mask: Int32, _ windows: CFArray) -> Unmanaged<CFArray>?

/// 7 = current | others | user, i.e. every Space the window could be on.
let kCGSSpaceAll: Int32 = 7

func spaces(for windowID: CGWindowID, _ cid: CGSConnectionID) -> [UInt64] {
    let ids = [NSNumber(value: windowID)] as CFArray
    guard let raw = CGSCopySpacesForWindows(cid, kCGSSpaceAll, ids) else { return [] }
    return (raw.takeRetainedValue() as? [NSNumber])?.map { $0.uint64Value } ?? []
}

let cid = CGSMainConnectionID()

// A control window with the panel's exact configuration. Absolute Space counts
// mean nothing on their own — this is what "all of them" looks like right here.
let control = NSPanel(
    contentRect: NSRect(x: -10_000, y: -10_000, width: 10, height: 10),
    styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
control.level = .statusBar
control.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
control.backgroundColor = .clear
control.isOpaque = false
control.ignoresMouseEvents = true
control.orderFrontRegardless()

// CGS applies membership changes asynchronously (~100 ms). Sample too early and
// every list comes back empty.
RunLoop.current.run(until: Date().addingTimeInterval(0.4))

let controlSpaces = spaces(for: CGWindowID(control.windowNumber), cid)
print("Active Space: \(CGSGetActiveSpace(cid))")
print("Control panel (known-good config): \(controlSpaces.count) Space(s) \(controlSpaces)")
print("")

guard let all = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]]
else {
    print("✗ could not read the window list"); exit(1)
}
let hud = all.filter {
    ($0[kCGWindowOwnerName as String] as? String) == "VoiceType"
        && ($0[kCGWindowLayer as String] as? Int) == 25
}

if hud.isEmpty {
    print("✗ No VoiceType HUD panel exists.")
    print("  The app either isn't running, or it is running a build that still")
    print("  orders the panel out at rest (pre-3.0.1). Check: pgrep -fl VoiceType")
    exit(1)
}

var wedged = false
for w in hud {
    let num = CGWindowID(w[kCGWindowNumber as String] as? Int ?? 0)
    let onScreen = (w[kCGWindowIsOnscreen as String] as? Bool) ?? false
    let mine = spaces(for: num, cid)
    print("HUD panel #\(num) onScreen=\(onScreen): \(mine.count) Space(s) \(mine)")

    if mine.count < controlSpaces.count {
        wedged = true
        print("  ✗ PINNED — the control sees \(controlSpaces.count) Space(s), this sees \(mine.count).")
        print("    This is the bug: the pill only appears on the Space(s) listed above.")
    } else {
        print("  ✓ healthy — member of every Space the control can reach.")
    }
    if !onScreen {
        wedged = true
        print("  ✗ OFF SCREEN — the panel exists but was ordered out; it cannot appear anywhere.")
    }
}
exit(wedged ? 1 : 0)
