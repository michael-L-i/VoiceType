import Foundation

/// One user-defined substitution: what the transcriber keeps hearing → what
/// should be typed. The user's own dictionary for names, jargon, and chronic
/// mishears ("voice type" → "VoiceType"); applied to the final text no matter
/// which cleanup engine produced it.
public struct WordReplacement: Sendable, Codable, Equatable, Hashable, Identifiable {
    public var id: UUID
    public var from: String
    public var to: String

    public init(id: UUID = UUID(), from: String = "", to: String = "") {
        self.id = id
        self.from = from
        self.to = to
    }
}

public enum WordReplacements {
    /// Apply every replacement, in order, as a case-insensitive whole-word
    /// match. Lookarounds instead of `\b` so multi-word and symbol-bearing
    /// phrases ("voice type", "k8s") still anchor on word edges; the
    /// replacement text is inserted literally.
    public static func apply(_ replacements: [WordReplacement], to text: String) -> String {
        guard !replacements.isEmpty, !text.isEmpty else { return text }
        var out = text
        for replacement in replacements {
            let from = replacement.from.trimmingCharacters(in: .whitespaces)
            guard !from.isEmpty else { continue }
            // ICU's \w matches Han, so the word-edge lookarounds would forbid
            // any match inside continuous CJK text (which has no word edges to
            // find). CJK phrases match literally instead.
            let containsCJK = from.unicodeScalars.contains { CJKPunctuation.isCJKLetter($0) }
            let escaped = NSRegularExpression.escapedPattern(for: from)
            let pattern = containsCJK ? escaped : "(?<!\\w)" + escaped + "(?!\\w)"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }
            let range = NSRange(out.startIndex..., in: out)
            out = regex.stringByReplacingMatches(
                in: out, range: range,
                withTemplate: NSRegularExpression.escapedTemplate(for: replacement.to))
        }
        return out
    }
}
