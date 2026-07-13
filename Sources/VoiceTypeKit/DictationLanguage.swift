import Foundation

/// The dictation languages the pickers offer (Settings and the setup flow),
/// as BCP-47 codes. Curated rather than exhaustive: the union of the languages
/// Apple Speech, Parakeet v3, and Nemotron (tiers 1+2) handle well — Whisper
/// covers all of them too. Whisper's long tail (its tokenizer lists 99) is
/// deliberately not offered until another engine or a language pack makes the
/// experience genuinely good there.
///
/// Display names are resolved through `Locale`, so the picker labels follow the
/// user's UI language for free ("Chinese (Simplified)" / "中文（简体）").
public struct DictationLanguage: Sendable, Equatable, Identifiable {
    public let code: String
    public var id: String { code }

    public init(code: String) {
        self.code = code
    }

    /// The language name in the user's UI language, e.g. "German (Germany)".
    public var localizedName: String {
        Locale.current.localizedString(forIdentifier: code) ?? code
    }

    /// Every offered language. English (US) is the default (`AppSettings`).
    public static let all: [DictationLanguage] = [
        "en-US", "en-GB", "ar-SA", "bg-BG", "cs-CZ", "da-DK", "de-DE", "el-GR",
        "es-ES", "et-EE", "fi-FI", "fr-FR", "hi-IN", "hr-HR", "hu-HU", "it-IT",
        "ja-JP", "ko-KR", "lt-LT", "lv-LV", "mt-MT", "nb-NO", "nl-NL", "pl-PL",
        "pt-BR", "ro-RO", "ru-RU", "sk-SK", "sl-SI", "sv-SE", "tr-TR", "uk-UA",
        "vi-VN", "zh-CN",
    ].map(DictationLanguage.init)

    /// The picker order: alphabetical by the user's localized language names,
    /// so a Chinese UI sorts by pinyin collation, an English UI by A–Z.
    public static var sortedForDisplay: [DictationLanguage] {
        all.sorted {
            $0.localizedName.localizedStandardCompare($1.localizedName) == .orderedAscending
        }
    }
}
