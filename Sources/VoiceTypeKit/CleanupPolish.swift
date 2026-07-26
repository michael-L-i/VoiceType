import Foundation

/// Deterministic touch-ups applied to *model* output after sanitizing. The
/// small on-device model is unreliable at exactly these mechanical details —
/// eval showed it leaving whole outputs lowercase, lone "i" pronouns, and
/// literal joiner words inside identifiers — so we guarantee them in code
/// instead of spending prompt tokens asking harder.
///
/// Everything here must be conservative: a rule that could corrupt a
/// legitimate output (file names, commands) doesn't belong in a blind
/// post-pass.
public enum CleanupPolish {
    public static func apply(_ text: String,
                             options: CleanupOptions,
                             context: CleanupContext = .general,
                             locale: String = "en-US") -> String {
        var out = text
        let pack = LanguagePack.pack(for: locale)
        // The model sometimes keeps the spoken joiner inside an identifier:
        // "max_underscore_retries" → "max_retries". Underscores only ever come
        // from explicit dictation, so this replacement cannot touch prose.
        out = out.replacingOccurrences(
            of: "_underscore_", with: "_", options: [.caseInsensitive])

        // The pack's own rules run in this path too, at the same three stages
        // and in the same order as in `RuleBasedCleanup` — a language's
        // orthography must hold whichever engine produced the text.
        out = pack.rules.applying(.early, to: out, context: context)

        // The model occasionally drifts into CJK punctuation ("。" for ".") even
        // when the words stay English — below the script guard's radar, since
        // punctuation isn't letters. Repair it unless the dictation language
        // legitimately writes with these marks. Full-width languages get the
        // opposite repair: the model drifts to ASCII "," inside Chinese text.
        if pack.usesFullWidthPunctuation {
            // The small model rarely renders spoken punctuation names it wasn't
            // trained on ("逗号" stays words) — run the deterministic renderer
            // on its output too, then normalize widths and spacing.
            out = RuleBasedCleanup.renderSpokenPunctuation(out, pack: pack)
            out = CJKPunctuation.normalize(out)
        } else if !pack.preservesFullWidthMarks {
            out = normalizeForeignPunctuation(out)
        }

        out = pack.rules.applying(.afterPunctuation, to: out, context: context)

        // The remaining repairs are prose rules: skip them in a terminal,
        // where "git status" must never gain a capital or a "?".
        let isTerminal = context.category == .terminal

        if options.addPunctuation && !isTerminal {
            out = ensureQuestionMark(out, pack: pack)
            if pack.usesFullWidthPunctuation {
                // The model also drops the terminal 。 in Chinese; guarantee it
                // the same way the rules floor does.
                out = RuleBasedCleanup.ensureTerminalPunctuation(out, pack: pack)
            }
        }
        guard options.fixCapitalization, !isTerminal,
              pack.separatesWordsWithSpaces else {
            return pack.rules.applying(.final, to: out, context: context)
        }
        if let pronoun = pack.capitalizedStandalonePronoun {
            out = RuleBasedCleanup.capitalizeStandalonePronoun(out, pronoun: pronoun, pack: pack)
        }
        out = capitalizeFirstPlainWord(out, pack: pack)
        return pack.rules.applying(.final, to: out, context: context)
    }

    /// Full-width / CJK punctuation → the ASCII the speaker's language expects.
    static let foreignPunctuation: [Character: String] = [
        "。": ".", "，": ",", "、": ",", "？": "?", "！": "!",
        "：": ":", "；": ";", "（": "(", "）": ")", "\u{3000}": " ",
    ]

    static func normalizeForeignPunctuation(_ text: String) -> String {
        guard text.contains(where: { foreignPunctuation[$0] != nil }) else { return text }
        return String(text.flatMap { foreignPunctuation[$0] ?? String($0) })
    }

    /// Append the question mark to an unpunctuated output that reads as a
    /// question in the pack's language — opening interrogative words (English
    /// "what/is/can…") or a sentence-final particle (Chinese …吗). Fires only
    /// when the model left NO terminal punctuation at all — if it chose "." or
    /// anything else, we respect that choice.
    static func ensureQuestionMark(_ text: String, pack: LanguagePack? = nil) -> String {
        let pack = pack ?? .english
        guard let last = text.last, last.isLetter || last.isNumber else { return text }
        // Longest particle first: a language can list both か and ですか
        // without the shorter one shadowing the longer.
        let lowered = text.lowercased()
        for particle in pack.questionSuffixParticles.sorted(by: { $0.count > $1.count })
        where lowered.hasSuffix(particle.lowercased()) {
            return text + pack.questionMark
        }
        guard !pack.questionPrefixWords.isEmpty else { return text }
        let first = text.prefix(while: { !$0.isWhitespace }).lowercased()
        guard pack.questionPrefixWords.contains(first) else { return text }
        return text + pack.questionMark
    }

    /// Uppercase the first letter, but only when the leading token is a plain
    /// word. A leading identifier, path, or file name ("app.py is missing",
    /// "~/projects has moved") must stay exactly as rendered.
    static func capitalizeFirstPlainWord(_ text: String,
                                         pack: LanguagePack = .english) -> String {
        guard let firstChar = text.first, firstChar.isLowercase else { return text }
        // Trailing punctuation ("yeah,") is fine; internal symbols ("app.py",
        // "get_user", "~/x") mean the token is not a plain word.
        let firstToken = text.prefix(while: { !$0.isWhitespace })
            .trimmingCharacters(in: .punctuationCharacters)
        guard !firstToken.isEmpty,
              firstToken.allSatisfy({ $0.isLetter || $0 == "'" }) else { return text }
        return pack.uppercased(String(firstChar)) + text.dropFirst()
    }
}
