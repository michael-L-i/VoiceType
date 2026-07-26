import Foundation

/// The words an Italian speaker uses to dictate a character out loud, rendered
/// deterministically — but only in the positions where they cannot be ordinary
/// prose.
///
/// Italian does **not** ship a `SpokenSymbolVocabulary`. That pipeline replaces
/// on trigger words alone, and Italy's trigger words are its everyday nouns:
/// `punto` is "the point", `virgola` is "the comma" you can talk *about*,
/// `barra` is a bar, `chiocciola` is a snail, `parentesi` is a digression ("tra
/// parentesi"). docs/LOCALIZATION.md calls this out as the reason every Latin
/// pack has an empty `spokenPunctuation`, and names the way in: render them
/// only in unambiguous positions. That's what these rules do.
///
/// Every rule below is anchored on something a sentence about snails or
/// digressions cannot have:
/// - a **compound name** that only ever names a character (`punto
///   interrogativo`, `punto e virgola`, `parentesi aperta`, `trattino basso`);
/// - a **known file extension** right after `punto`;
/// - a **top-level domain** closing an address, which is what makes the lone
///   `chiocciola` safe there and nowhere else;
/// - **identifier-shaped neighbours** on both sides of a `trattino`.
///
/// Deliberately NOT rendered, because no anchor makes them safe: bare `punto`
/// and `virgola` (except the spoken decimal, see `italianDecimalCommaRule`),
/// `due punti` for `:` ("ha segnato due punti"), `e commerciale` for `&` ("il
/// settore industriale e commerciale"), and the single-noun names `asterisco`,
/// `cancelletto`, `apostrofo`, `barra`. Those are the LLM's job — it can see
/// the sentence around them, and `ItalianPrompt` tells it how.
extension LanguagePack {
    static let italianSymbolRules: [CleanupRule] = [
        italianEmailRule,
        italianFileExtensionRule,
        italianIdentifierRule,
        italianPunctuationNameRule,
        italianTerminalRule,
    ]

    // MARK: - Email addresses

    /// "mario punto rossi chiocciola gmail punto com" → mario.rossi@gmail.com.
    ///
    /// Anchored on the closing top-level domain, so the lone word `chiocciola`
    /// ("snail") is only ever read as `@` inside something that already looks
    /// like an address. A single-word local part that is a function word is
    /// rejected outright, the same guard English's renderer uses to keep "guarda
    /// a gmail punto com" as prose.
    static let italianEmailRule = CleanupRule(
        name: "indirizzi email dettati",
        stage: .early) { text, _ in
        let tld = "com|it|net|org|io|co|eu|dev|app|ai|edu|gov|me|info"
        let pattern = #"(?i)\b([\p{L}\d._-]+(?:\s+punto\s+[\p{L}\d_-]+)*)\s+chiocciola\s+((?:[\p{L}\d-]+\s+punto\s+)+(?:\#(tld)))\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        var out = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let whole = Range(match.range, in: out),
                  let localRange = Range(match.range(at: 1), in: out),
                  let domainRange = Range(match.range(at: 2), in: out) else { continue }
            let local = String(out[localRange])
            if !local.contains(" "), LanguagePack.italianStopwords.contains(local.lowercased()) {
                continue
            }
            let joined = (local + "@" + String(out[domainRange]))
                .replacingOccurrences(of: #"\s+punto\s+"#, with: ".",
                                      options: [.regularExpression, .caseInsensitive])
            out.replaceSubrange(whole, with: joined.lowercased())
        }
        return out
    }

    // MARK: - File names

    /// "main punto py" → main.py. The anchor is the extension itself: `punto`
    /// only renders when the very next word names a file type, so "il punto è
    /// che" and "a un certo punto" are untouched.
    ///
    /// `pi` is the transcription an Italian speaker's ".py" reliably comes back
    /// as — the letter is pronounced /pi/ — and is the one homophone worth
    /// resolving.
    static let italianFileExtensionRule = CleanupRule(
        name: "estensioni di file dettate",
        stage: .early) { text, _ in
        let extensions = [
            "py", "js", "ts", "tsx", "jsx", "rs", "go", "swift", "rb", "php",
            "java", "sh", "md", "txt", "json", "yaml", "yml", "toml", "html",
            "css", "xml", "sql", "csv", "log", "lock", "env", "cpp", "hpp",
            "pdf", "png", "jpg", "zip",
        ].joined(separator: "|")
        var out = italianReplacing(
            text,
            pattern: #"\b([\p{L}\d_-]+)\s+[Pp]unto\s+(\#(extensions))\b"#,
            template: "$1.$2")
        out = italianReplacing(
            out,
            pattern: #"\b([\p{L}\d_-]+)\s+[Pp]unto\s+pi\b"#,
            template: "$1.py")
        return out
    }

    // MARK: - Identifiers

    /// "max trattino basso tentativi" → max_tentativi, "michael trattino l
    /// trattino i" → michael-l-i.
    ///
    /// `trattino basso` is the Italian name for `_` and names nothing else, so
    /// it only needs identifier-shaped neighbours. Bare `trattino` needs one
    /// more guard: "metti un trattino qui" is a sentence, so a determiner on
    /// the left side blocks the join. Both run to a fixpoint, which is what
    /// chains a multi-part handle together.
    static let italianIdentifierRule = CleanupRule(
        name: "identificatori dettati",
        stage: .early) { text, _ in
        // Words that, standing immediately left of "trattino", mean the speaker
        // is talking about a dash rather than spelling one.
        let guards = "un|uno|una|il|lo|la|i|gli|le|questo|quel|del|dal|nel|al|con|senza|e|o|ci"
        var out = italianFixpoint(text) {
            italianReplacing($0,
                             pattern: #"(?i)\b(?!(?:\#(guards))\b)([\p{L}\d_]+)\s+trattino\s+basso\s+([\p{L}\d]+)"#,
                             template: "$1_$2")
        }
        out = italianFixpoint(out) {
            italianReplacing($0,
                             pattern: #"(?i)\b(?!(?:\#(guards))\b)([\p{L}\d]+)\s+trattino\s+([\p{L}\d]+)"#,
                             template: "$1-$2")
        }
        return out
    }

    // MARK: - Compound punctuation names

    /// The punctuation names that are compounds, and therefore unambiguous.
    ///
    /// Source for the vocabulary: Apple's Italian dictation command list
    /// (macOS/iOS) — "punto interrogativo", "punto esclamativo", "punto e
    /// virgola", "puntini sospensivi", "parentesi aperta/chiusa", "parentesi
    /// quadra/graffa", "virgolette". This renders the subset that cannot be
    /// read as prose; the single-word commands from that same list are left to
    /// the model on purpose (see the type comment).
    ///
    /// Marks glue to the word on their left; brackets and quotes are emitted
    /// with their own spacing and tightened by `italianFinalSpacingRule`, so
    /// the result holds in both cleanup paths.
    static let italianPunctuationNameRule = CleanupRule(
        name: "nomi composti della punteggiatura",
        stage: .early) { text, _ in
        var out = text
        for (pattern, template) in italianPunctuationNames {
            out = italianReplacing(out, pattern: pattern, template: template,
                                   options: [.caseInsensitive])
        }
        return out
    }

    /// Longest name first, so "parentesi quadra aperta" is never shadowed by
    /// "parentesi aperta".
    static let italianPunctuationNames: [(String, String)] = [
        // Sentence marks: absorb the space in front, keep the one behind.
        (#"[ \t]*\bpunto\s+(?:interrogativo|di\s+domanda)\b"#, "?"),
        (#"[ \t]*\bpunto\s+esclamativo\b"#, "!"),
        (#"[ \t]*\bpunto\s+e\s+virgola\b"#, ";"),
        (#"[ \t]*\b(?:puntini\s+(?:sospensivi|di\s+sospensione)|tre\s+puntini)\b"#, "…"),
        // Square and curly brackets before round ones.
        (#"[ \t]*\b(?:parentesi\s+quadra\s+aperta|aperta\s+parentesi\s+quadra|apri\s+(?:la\s+)?parentesi\s+quadra)\b[ \t]*"#, " ["),
        (#"[ \t]*\b(?:parentesi\s+quadra\s+chiusa|chiusa\s+parentesi\s+quadra|chiudi\s+(?:la\s+)?parentesi\s+quadra)\b"#, "]"),
        (#"[ \t]*\b(?:parentesi\s+graffa\s+aperta|aperta\s+parentesi\s+graffa|apri\s+(?:la\s+)?parentesi\s+graffa)\b[ \t]*"#, " {"),
        (#"[ \t]*\b(?:parentesi\s+graffa\s+chiusa|chiusa\s+parentesi\s+graffa|chiudi\s+(?:la\s+)?parentesi\s+graffa)\b"#, "}"),
        (#"[ \t]*\b(?:parentesi\s+(?:tonda\s+)?aperta|aperta\s+parentesi(?:\s+tonda)?|apri\s+(?:la\s+)?parentesi)\b[ \t]*"#, " ("),
        (#"[ \t]*\b(?:parentesi\s+(?:tonda\s+)?chiusa|chiusa\s+parentesi(?:\s+tonda)?|chiudi\s+(?:la\s+)?parentesi)\b"#, ")"),
        // Quotation marks. Italian also writes «caporali»; the high curly pair
        // is the safer default for dictation into arbitrary apps, and the
        // caporali a speaker types themselves are tightened, never rewritten.
        (#"[ \t]*\b(?:aperte\s+virgolette|virgolette\s+aperte|apri\s+(?:le\s+)?virgolette)\b[ \t]*"#, " “"),
        (#"[ \t]*\b(?:chiuse\s+virgolette|virgolette\s+chiuse|chiudi\s+(?:le\s+)?virgolette)\b"#, "”"),
    ]

    // MARK: - Terminal

    /// Spoken options and paths, terminal only. The trigger words are Italian,
    /// so a real command ("git status", "npm run build") contains none of them
    /// and passes through byte-for-byte — which is why this rule can opt into
    /// the terminal at all.
    ///
    /// The extra aggression matches the bias the rest of the engine already
    /// applies there: in a shell, "trattino" is an option marker, not a word.
    static let italianTerminalRule = CleanupRule(
        name: "percorsi e opzioni nel terminale",
        stage: .early,
        runsInTerminal: true) { text, context in
        guard context.category == .terminal else { return text }
        var out = italianReplacing(text,
                                   pattern: #"(?i)\btrattin[oi]\s+trattin[oi]\s+([\p{L}\d][\p{L}\d-]*)"#,
                                   template: "--$1")
        out = italianReplacing(out,
                               pattern: #"(?i)\btrattino\s+([\p{L}\d][\p{L}\d-]*)"#,
                               template: "-$1")
        out = italianReplacing(out,
                               pattern: #"(?i)\btilde\s+barra\s+([\p{L}\d][\p{L}\d._-]*)"#,
                               template: "~/$1")
        out = italianReplacing(out,
                               pattern: #"(?i)\bpunto\s+barra\s+([\p{L}\d][\p{L}\d._-]*)"#,
                               template: "./$1")
        out = italianFixpoint(out) {
            italianReplacing($0,
                             pattern: #"(?i)([\p{L}\d][\p{L}\d._~/-]*)\s+barra\s+([\p{L}\d][\p{L}\d._-]*)"#,
                             template: "$1/$2")
        }
        return out
    }

    // MARK: - Helpers

    /// Re-apply a transform until it stops changing the text, so a chain of
    /// joins ("a trattino b trattino c") folds completely. Bounded, because a
    /// pathological rule must never hang a dictation.
    static func italianFixpoint(_ text: String, _ transform: (String) -> String) -> String {
        var out = text
        for _ in 0..<8 {
            let next = transform(out)
            if next == out { return out }
            out = next
        }
        return out
    }
}
