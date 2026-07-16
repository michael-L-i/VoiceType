import Foundation

/// Resolves the package-generated localization bundle from its standard macOS
/// app location. SwiftPM's generated `Bundle.module` accessor assumes its
/// executable is still in `.build` and traps when a manually assembled `.app`
/// stores resources under `Contents/Resources`, so the app shell must resolve
/// that packaged location explicitly.
enum AppLocalization {
    static let resourceBundleName = "VoiceType_VoiceType.bundle"

    static let bundle = resolve(in: .main)

    static func resolve(in mainBundle: Bundle) -> Bundle {
        guard let resources = mainBundle.resourceURL,
              let bundle = Bundle(url: resources.appendingPathComponent(resourceBundleName)) else {
            // English source text is also the localization key, so a damaged
            // bundle remains usable instead of crashing during app launch.
            return mainBundle
        }
        return bundle
    }

    /// Used by the assembled-app smoke test. Runtime lookup remains fail-soft,
    /// while release packaging fails loudly before a broken artifact ships.
    static func packageVerificationFailures(in mainBundle: Bundle = .main) -> [String] {
        let resolved = resolve(in: mainBundle)
        guard resolved.bundleURL.standardizedFileURL != mainBundle.bundleURL.standardizedFileURL else {
            return ["Missing or invalid Contents/Resources/\(resourceBundleName)"]
        }

        var failures: [String] = []
        if !resolved.localizations.contains(where: { $0.caseInsensitiveCompare("en") == .orderedSame }) {
            failures.append("Localization bundle does not declare English")
        }
        if resolved.path(forResource: "Localizable", ofType: "strings",
                         inDirectory: nil, forLocalization: "en") == nil {
            failures.append("Localization bundle has no English Localizable.strings")
        }
        return failures
    }
}

/// Every user-facing literal goes through `L(...)`, which keeps the localizable
/// surface greppable. English text is the key; missing translations fall back
/// to English without making resource packaging a launch-time fatal error.
@inline(__always)
func L(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: AppLocalization.bundle)
}

/// For runtime-valued keys — copy that arrives as a `String` from the Kit
/// (engine summaries, feature chips). Unknown keys render as themselves.
func L(dynamic key: String) -> String {
    AppLocalization.bundle.localizedString(forKey: key, value: key, table: nil)
}
