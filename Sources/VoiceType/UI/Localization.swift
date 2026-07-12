import Foundation

/// UI-string lookup against the package resource bundle.
///
/// SwiftUI's bare string literals resolve against `Bundle.main`, which for a
/// SwiftPM-built app is the executable shell — our `Localizable.strings` live
/// in `Bundle.module`. So every user-facing literal goes through `L(...)`,
/// which also keeps the localizable surface greppable. English text is the
/// key; missing translations fall back to English.
@inline(__always)
func L(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: .module)
}

/// For runtime-valued keys — copy that arrives as a `String` from the Kit
/// (engine summaries, feature chips). Unknown keys render as themselves.
func L(dynamic key: String) -> String {
    Bundle.module.localizedString(forKey: key, value: key, table: nil)
}
