import Foundation

/// Last line of defense against an LLM cleanup engine wrapping its answer in a
/// conversational shell despite being told not to. Small on-device models will
/// occasionally emit a "Sure, here's the cleaned transcript:" lead-in or wrap the
/// whole output in quotes — most often when the dictation itself *contains* a
/// question or command and the model "helpfully" responds. The prompt is the
/// primary defense; this strips the residue deterministically so the user never
/// sees it.
///
/// Conservative by construction: it only removes a tightly-matched preamble (one
/// that names the transcript, or is introduced by an opener like "Sure,") and a
/// single layer of quotes wrapping the ENTIRE output. Plain dictation such as
/// "Here is my plan: buy milk" is left untouched.
public enum CleanupSanitizer {
    /// Strip any conversational wrapper the model added around the cleaned text.
    public static func strip(_ text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        s = removingMarkerEcho(s)
        s = removingCodeFence(s)
        if let withoutLeadIn = removingLeadIn(s) { s = withoutLeadIn }
        if let unquoted = removingWrappingQuotes(s) { s = unquoted }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The model occasionally wraps the output in a Markdown code fence
    /// (terminal dictation invites it: "git status\n```"). Nobody dictates
    /// backtick fences — `SpokenSymbols` renders "backtick" as the character —
    /// so a fence line at either edge is always the model's wrapper.
    static func removingCodeFence(_ s: String) -> String {
        var out = s
        for pattern in [#"^\s*```[^\n]*\n"#, #"\n?\s*```\s*$"#] {
            guard let re = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(out.startIndex..., in: out)
            out = re.stringByReplacingMatches(in: out, range: range, withTemplate: "")
        }
        return out
    }

    /// The model occasionally echoes the prompt's transcript fence back — a
    /// trailing "<<<TRANSCRIPT … TRANSCRIPT>>>" block (usually empty), or a
    /// stray marker on its own line. The markers are ours, never dictation, so
    /// stripping them is always safe.
    static func removingMarkerEcho(_ s: String) -> String {
        var out = s
        for pattern in [#"\s*<<<TRANSCRIPT\b[\s\S]*?TRANSCRIPT>>>\s*$"#,
                        #"\s*<<<TRANSCRIPT\s*$"#,
                        #"^\s*TRANSCRIPT>>>\s*"#] {
            guard let re = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(out.startIndex..., in: out)
            out = re.stringByReplacingMatches(in: out, range: range, withTemplate: "")
        }
        return out
    }

    // A preamble worth stripping looks like an assistant talking ABOUT the output:
    // it's at the very start, stays on one line (no earlier colon/newline), ends
    // in a colon, and EITHER is introduced by an opener ("Sure,", "Okay,") OR names
    // the transcript ("...cleaned transcript:", "...tidied text:"). Requiring one of
    // those two signals is what keeps legitimate "Here is my plan:" prose safe.
    private static let leadInPatterns: [String] = [
        // Opener-led: "Sure, here's …:", "Okay, here is the cleaned version:".
        #"(?i)^\s*(?:sure|okay|ok|got it|certainly|absolutely|alright|no problem)[,!.]+\s*(?:here(?:['’]s| is| are| you go| it is)?\b)?[^\n:]{0,80}:\s+"#,
        // Transcript-named: "Here's the cleaned transcript:", "The cleaned-up text:".
        #"(?i)^\s*(?:here(?:['’]s| is| are| you go| it is)?\b|the\b)?[^\n:]{0,60}(?:transcript|dictation|cleaned(?:[- ]up)?|tidied|corrected)[^\n:]{0,30}:\s+"#,
    ]

    static func removingLeadIn(_ s: String) -> String? {
        for pattern in leadInPatterns {
            guard let re = try? NSRegularExpression(pattern: pattern) else { continue }
            let full = NSRange(s.startIndex..., in: s)
            guard let m = re.firstMatch(in: s, range: full),
                  m.range.location == 0,
                  let r = Range(m.range, in: s) else { continue }
            let remainder = String(s[r.upperBound...])
            // Never strip everything — if no real content follows, leave it alone.
            if !remainder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return remainder
            }
        }
        return nil
    }

    /// Remove one layer of straight or smart DOUBLE quotes (or guillemets) that
    /// wrap the whole output. Single quotes are left alone — apostrophes and
    /// contractions make them ambiguous.
    static func removingWrappingQuotes(_ s: String) -> String? {
        guard s.count >= 2, let first = s.first, let last = s.last else { return nil }
        let pairs: [(open: Character, close: Character)] = [("\"", "\""), ("“", "”"), ("«", "»")]
        for pair in pairs where first == pair.open && last == pair.close {
            let inner = String(s.dropFirst().dropLast())
            // For symmetric quotes ("…"), bail if the inner text contains the same
            // character — then the outer marks were probably part of real content.
            if pair.open == pair.close && inner.contains(pair.open) { return nil }
            return inner
        }
        return nil
    }
}
