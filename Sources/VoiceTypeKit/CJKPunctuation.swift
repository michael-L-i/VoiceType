import Foundation

/// Punctuation and spacing conventions for full-width languages (currently
/// Chinese). Shared by `RuleBasedCleanup` (raw transcripts) and
/// `CleanupPolish` (model output, which drifts to ASCII commas inside Chinese
/// text). Every rule is anchored on a Han character or a full-width mark, so
/// pure-ASCII substrings — embedded English, file names, numbers — pass
/// through untouched.
public enum CJKPunctuation {

    /// True for Han ideographs (the letters of Chinese text).
    public static func isHan(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF:
            return true
        default:
            return false
        }
    }

    /// True for any CJK letter — Han plus the kana Japanese text is mostly
    /// written in. The spacing/terminal rules anchor on this so they work for
    /// Japanese sentences that end in ます/です, not just kanji.
    public static func isCJKLetter(_ scalar: Unicode.Scalar) -> Bool {
        if isHan(scalar) { return true }
        switch scalar.value {
        case 0x3040...0x309F, 0x30A0...0x30FF, 0x31F0...0x31FF:
            return true
        default:
            return false
        }
    }

    /// Normalize a full-width-language text:
    /// 1. ASCII `, ? ! : ;` after a Han character become full-width (the mark
    ///    engines/models most often get wrong), swallowing any following space.
    /// 2. ASCII `.` after a Han character becomes `。` — unless it opens an
    ///    identifier/number tail ("今天.py", "3.14" are left alone).
    /// 3. Spaces vanish between two Han characters and around full-width
    ///    marks (Whisper pads CJK tokens with spaces). Latin↔Han boundaries
    ///    keep their space ("VoiceType 很棒"). Newlines are never touched —
    ///    they only exist because the speaker dictated them.
    /// 4. Doubled marks collapse ("。。" → "。", "？。" → "？") so spoken
    ///    punctuation stays idempotent when the engine already rendered it.
    public static func normalize(_ text: String) -> String {
        var out = text
        // Han plus kana, so the same rules serve Chinese and Japanese.
        let han = "[\\p{Han}\\p{Hiragana}\\p{Katakana}]"
        // 1. ASCII → full-width after a CJK letter.
        for (ascii, full) in [(",", "，"), ("?", "？"), ("!", "！"), (":", "："), (";", "；")] {
            out = replace(out, "(?<=\(han))\\\(ascii)[ \\t]*", full)
        }
        // 2. Sentence period, guarded against identifier/decimal tails.
        out = replace(out, "(?<=\(han))\\.(?![A-Za-z0-9._~/\\\\-])[ \\t]*", "。")
        // 3. Inter-letter and around-mark spaces.
        out = replace(out, "(?<=\(han))[ \\t]+(?=\(han))", "")
        out = replace(out, "[ \\t]+(?=[\(fullWidthMarks)])", "")
        out = replace(out, "(?<=[\(fullWidthMarks)])[ \\t]+(?=\(han))", "")
        // 4. Idempotence: repeated identical marks, then a stray 。 trailing a
        //    stronger terminal.
        out = replace(out, "([。，、！？：；])\\1+", "$1")
        out = replace(out, "(?<=[！？])。", "")
        return out
    }

    /// The full-width marks the spacing rules anchor on (a regex character
    /// class body — no escaping needed for these).
    private static let fullWidthMarks = "。，、！？：；（）“”…"

    private static func replace(_ text: String, _ pattern: String, _ template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: template)
    }
}
