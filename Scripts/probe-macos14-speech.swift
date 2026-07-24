// CI-only diagnostic. Not part of the app.
//
// On macOS 14–15 `AppleSpeechEngine` is gated entirely on
// `SFSpeechRecognizer.supportsOnDeviceRecognition`. If no locale reports true,
// `isAvailable()` is false, and on a fresh install no downloadable model exists
// either — so the app has no working transcriber out of the box. That is a
// product-breaking difference between "compiles for macOS 14" and "works on
// macOS 14", and it cannot be observed from a macOS 26 machine.
//
// These are capability queries, not recognition requests, so they need no
// Speech TCC grant and run fine on a headless runner. This script reports; it
// does not assert, because a CI image is not necessarily representative of a
// real user's Mac. Read the output, don't trust it blindly.

import Foundation
import Speech

let probeStart = Date()
let all = SFSpeechRecognizer.supportedLocales().sorted { $0.identifier < $1.identifier }
let listElapsed = Date().timeIntervalSince(probeStart)

let onDeviceStart = Date()
let onDevice = all.filter { SFSpeechRecognizer(locale: $0)?.supportsOnDeviceRecognition == true }
let onDeviceElapsed = Date().timeIntervalSince(onDeviceStart)

print("=== macOS 14 speech capability probe ===")
print("OS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
print("Speech authorization: \(SFSpeechRecognizer.authorizationStatus().rawValue) (3 == authorized)")
print("")
print("supportedLocales(): \(all.count) locales in \(String(format: "%.2f", listElapsed))s")
print("of those, on-device capable: \(onDevice.count) — probed in \(String(format: "%.2f", onDeviceElapsed))s")
print("on-device locales: \(onDevice.map(\.identifier).joined(separator: ", "))")
print("")

// The probe cost matters: `EngineFactory.languageSupport()` runs this same
// per-locale loop, and it is awaited on the coordinator before the UI settles.
if onDeviceElapsed > 1.0 {
    print("WARNING: the per-locale on-device probe took \(String(format: "%.2f", onDeviceElapsed))s.")
    print("         EngineFactory.languageSupport() runs this same loop — that is a")
    print("         visible startup stall on macOS 14. Consider probing lazily or")
    print("         only for the selected locale.")
}

let english = onDevice.contains { $0.identifier.hasPrefix("en") }
print("VERDICT:")
if onDevice.isEmpty {
    print("  AppleSpeechEngine.isAvailable() would be FALSE on this machine.")
    print("  A fresh macOS 14 user has no Apple engine and no downloaded model,")
    print("  so DictationCoordinator line ~840 force-selects .appleOnDevice and the")
    print("  first dictation fails with 'doesn't support <locale> on this Mac'.")
    print("  The recovery path is the Models page (download Parakeet/Whisper).")
} else if !english {
    print("  On-device recognition exists but NOT for any English locale.")
    print("  Default-language users would fall through to the same dead end.")
} else {
    print("  AppleSpeechEngine.isAvailable() would be TRUE — English on-device")
    print("  recognition is present, so the default engine works out of the box.")
}
