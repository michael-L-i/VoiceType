import Foundation

/// Turns the stored BCP-47 locale (e.g. `"en-US"`, `"pt-BR"`) into the forms the
/// different engines need:
///
/// - speech models want an ISO 639-1 language code (`"en"`, `"pt"`),
/// - the on-device cleanup LLM wants a human-readable language name (`"English"`)
///   so it can be told, in plain words, which language to write in.
///
/// Kept dependency-free (Foundation only) so it stays in the pure `VoiceTypeKit`
/// core and is trivially testable.
public enum LanguageTag {
    /// The ISO 639-1 primary language subtag of a BCP-47 locale.
    /// `"en-US" -> "en"`, `"pt-BR" -> "pt"`, `"zh-CN" -> "zh"`.
    public static func code(for locale: String) -> String {
        let primary = locale.split(whereSeparator: { $0 == "-" || $0 == "_" }).first
        return (primary.map(String.init) ?? locale).lowercased()
    }

    /// The English name of the locale's language, for use inside a prompt.
    /// `"es-ES" -> "Spanish"`, `"ja-JP" -> "Japanese"`. Falls back to the raw
    /// language code when no name is known.
    public static func englishName(for locale: String) -> String {
        let code = code(for: locale)
        // Resolve the name in English regardless of the user's system locale so
        // the cleanup prompt is stable and unambiguous.
        return Locale(identifier: "en_US").localizedString(forLanguageCode: code) ?? code
    }
}
