import Foundation

/// English's deterministic fixes beyond the shared pack fields.
///
/// These are deliberately command-shaped: they act only on words the speaker
/// uses to request a mechanical rendering. Lexical cleanup that needs meaning
/// stays in the model prompt.
///
/// Deliberately NOT a rule: bare numeric `five, no six` correction. The same
/// token shape can be ordinary negation ("the answer is five, no six is
/// allowed by the rubric"), and `CleanupRule` intentionally has no cleanup-
/// option input that could limit deletion to disfluency removal. That judgment
/// remains in English's model prompt rather than risking lost content.
extension LanguagePack {
    static let englishRules: [CleanupRule] = [
        CleanupRule(
            name: "en: spoken camel case joins an identifier",
            stage: .early,
            transform: { text, _ in englishRenderingCamelCase(text) }),
        // The repeated preposition identifies the exact phrase being
        // retracted without guessing from meaning:
        // "to Bob, no wait, to Alice" -> "to Alice".
        CleanupRule.regex(
            name: "en: repeated-preposition no-wait correction",
            stage: .early,
            pattern: #"\b(to|from|at|on|in|for|with|by)[ \t]+[\p{L}\p{N}][^,\n]{0,39},[ \t]*no[ \t]+wait,[ \t]*\1[ \t]+"#,
            template: "$1 ",
            options: [.caseInsensitive]),
    ]

    /// Render an explicit `camel case` command and consume only the identifier
    /// words that follow it. English function words form a conservative right
    /// boundary, so `camel case get user name with the token` becomes
    /// `getUserName with the token`; unmarked words are never joined.
    private static func englishRenderingCamelCase(_ text: String) -> String {
        guard let trigger = try? NSRegularExpression(
            pattern: #"\bcamel[ \t]+case\b[ \t]+"#,
            options: [.caseInsensitive]),
            let word = try? NSRegularExpression(pattern: #"^\p{L}[\p{L}\p{N}]*"#),
            let followingWord = try? NSRegularExpression(
                pattern: #"^[ \t]+(\p{L}[\p{L}\p{N}]*)"#)
        else { return text }

        let source = text
        let matches = trigger.matches(
            in: source,
            range: NSRange(source.startIndex..., in: source))
        var out = text

        // Work backwards so ranges measured in `source` stay valid while
        // earlier replacements change the string's length.
        for match in matches.reversed() {
            guard let triggerRange = Range(match.range, in: source) else { continue }
            var cursor = triggerRange.upperBound
            var words: [String] = []

            let firstRange = NSRange(cursor..<source.endIndex, in: source)
            guard let firstMatch = word.firstMatch(in: source, range: firstRange),
                  firstMatch.range.location == firstRange.location,
                  let firstWordRange = Range(firstMatch.range, in: source)
            else { continue }

            let firstWord = String(source[firstWordRange])
            guard !englishStopwords.contains(firstWord.lowercased()) else { continue }
            words.append(firstWord)
            cursor = firstWordRange.upperBound

            while words.count < 6 {
                let tailRange = NSRange(cursor..<source.endIndex, in: source)
                guard let nextMatch = followingWord.firstMatch(in: source, range: tailRange),
                      nextMatch.range.location == tailRange.location,
                      let nextWordRange = Range(nextMatch.range(at: 1), in: source)
                else { break }

                let nextWord = String(source[nextWordRange])
                guard !englishStopwords.contains(nextWord.lowercased()) else { break }
                words.append(nextWord)
                cursor = nextWordRange.upperBound
            }

            // A single word gains nothing from camel casing. Requiring at
            // least two also leaves prose such as "camel case is common"
            // untouched.
            guard words.count >= 2 else { continue }

            let rendered = words.enumerated().map { index, component in
                if index == 0 { return component.lowercased() }
                if component == component.uppercased() {
                    return component
                }
                return component.prefix(1).uppercased() + component.dropFirst()
            }.joined()

            out.replaceSubrange(triggerRange.lowerBound..<cursor, with: rendered)
        }
        return out
    }
}
