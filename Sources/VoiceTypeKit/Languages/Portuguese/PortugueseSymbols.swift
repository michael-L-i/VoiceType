import Foundation

extension LanguagePack {
    /// Spoken-symbol rendering for Portuguese, written as position-guarded
    /// `CleanupRule`s rather than as a `SpokenSymbolVocabulary`.
    ///
    /// The shared `SpokenSymbols` pipeline is built around a language whose
    /// trigger words do nothing else: English "dot", "underscore", "slash".
    /// Portuguese has no such words. "ponto" is a point of view, a bus stop, an
    /// o'clock ("chegou em ponto") and a stitch; "barra" is a bar, a beach and
    /// a slash; "traço" is a stroke and a personality trait; "vírgula" is the
    /// decimal separator half the time. A pipeline that joins on the trigger
    /// word alone would fire constantly on ordinary prose.
    ///
    /// So every rule here renders a symbol from the *position* it appears in,
    /// never from the word alone:
    ///
    /// - "ponto" joins only when the next word names a real file extension.
    ///   "o ponto de vista" has no extension after it and survives untouched.
    /// - "arroba" becomes `@` only when the run it sits in ends in a real TLD,
    ///   so "um boi de vinte arrobas" stays prose.
    /// - "underline" joins only when both neighbours are identifier-shaped and
    ///   neither is a function word, so "eu quero underline o texto" survives.
    /// - "barra" becomes `/` only inside terminal dictation, where a path is
    ///   the overwhelmingly likely reading; in prose it is always a word.
    /// - "traço" becomes `-` only before a single spoken letter (a handle), or
    ///   as a flag inside a terminal. "traço de personalidade" matches neither.
    ///
    /// Deliberately NOT rendered:
    /// - bare "vírgula" as a comma — it is the decimal separator as often as
    ///   the mark, and the decimal case has its own digit-anchored rule.
    /// - "barra invertida" as a backslash — outside a terminal nobody wants
    ///   one, and inside one the path rule already owns "barra".
    /// - "asterisco", "cerquilha", "cifrão" — each names exactly one symbol,
    ///   but a lone `*` or `#` dropped into prose reads as breakage far more
    ///   often than as intent. Left to the LLM, which has context.
    /// - a spoken "vírgula" between the parentheses of a call (`soma(a, b)`) —
    ///   it needs bracket-depth state a regex does not have. Prompt covers it.
    static let portugueseSymbolRules: [CleanupRule] = [
        // "main ponto py" → main.py. The extension list is the anchor: it is
        // what makes a word as common as "ponto" safe to consume.
        CleanupRule(name: "pt spoken file extension", stage: .early, runsInTerminal: true) { text, _ in
            let joined = PortugueseText.sub(
                text,
                #"\b(?!\#(PortugueseText.joinGuard)\b)([\p{L}\p{N}][\p{L}\p{N}._-]*)\s+ponto\s+(\#(PortugueseText.fileExtensions))\b"#,
                "$1.$2")
            // ".py" read aloud in Portuguese comes out as "pai" or "pi", and
            // the transcriber writes the Portuguese words it knows. Mapping
            // after the join means a bare "pai" in prose is never touched.
            return PortugueseText.sub(joined, #"\.(pai|pi)\b"#, ".py")
        },

        // "max underline retries" → max_retries. Chains left to right, and is
        // blocked whenever either neighbour is a function word.
        CleanupRule(name: "pt spoken underscore", stage: .early, runsInTerminal: true) { text, _ in
            PortugueseText.subRepeat(
                text,
                #"\b(?!\#(PortugueseText.joinGuard)\b)([\p{L}\p{N}][\p{L}\p{N}._-]*)\s+(?:underline|underscore|sublinhado)\s+(?!\#(PortugueseText.joinGuard)\b)([\p{L}\p{N}][\p{L}\p{N}._-]*)"#,
                "$1_$2")
        },

        // "pedro ponto silva arroba gmail ponto com" → pedro.silva@gmail.com.
        // Anchored on the TLD, so an ordinary "arroba" never matches, and the
        // spoken dots collapse only inside the address the match proved.
        CleanupRule(name: "pt spoken email address", stage: .early, runsInTerminal: true) { text, _ in
            let pattern = #"\b([a-z0-9]+(?:\s+ponto\s+[a-z0-9]+)*)\s+arroba\s+((?:[a-z0-9]+\s+ponto\s+)+(?:\#(PortugueseText.emailTLDs)))\b"#
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                return text
            }
            var result = text
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches.reversed() {
                guard let whole = Range(match.range, in: result),
                      let localRange = Range(match.range(at: 1), in: result),
                      let domainRange = Range(match.range(at: 2), in: result) else { continue }
                let local = String(result[localRange])
                // A lone function word or verb before "arroba" is prose, not a
                // local part: "olha arroba gmail ponto com" is a sentence.
                if !local.contains(" "),
                   local.range(of: #"^\#(PortugueseText.emailLocalGuard)$"#,
                               options: [.regularExpression, .caseInsensitive]) != nil {
                    continue
                }
                let joinDots = { PortugueseText.sub($0, #"\s+ponto\s+"#, ".") }
                let rendered = joinDots(local) + "@" + joinDots(String(result[domainRange]))
                result.replaceSubrange(whole, with: rendered.lowercased())
            }
            return result
        },

        // Parentheses and brackets. The imperative "abre …" cannot be a noun
        // phrase, unlike "entre parênteses", which is ordinary prose.
        CleanupRule(name: "pt spoken brackets", stage: .early) { text, _ in
            var out = text
            for (noun, open, close) in [(#"par[êe]ntese[s]?"#, "(", ")"),
                                        (#"colchete[s]?"#, "[", "]")] {
                out = PortugueseText.sub(
                    out,
                    #"\s*\b(?:abre|abrir|abra)\s+(?:os\s+|as\s+|um\s+|uma\s+)?"# + noun + #"\b\s*"#,
                    " " + open)
                out = PortugueseText.sub(
                    out,
                    #"\s*\b(?:fecha|fechar|feche)\s+(?:os\s+|as\s+|o\s+|a\s+)?"# + noun + #"\b"#,
                    close)
            }
            return out
        },

        // "michael traço L traço i" → michael-L-i. A single spoken letter on
        // the right is the guard: "traço de personalidade" and "um traço de
        // humor" match neither side of it.
        CleanupRule(name: "pt spoken hyphen before a single letter", stage: .early) { text, context in
            guard context.category != .terminal else { return text }
            return PortugueseText.subRepeat(
                text,
                #"\b(?!\#(PortugueseText.joinGuard)\b)([\p{L}\p{N}][\p{L}\p{N}._-]*)\s+\b\#(PortugueseText.dashWord)\b\s+([A-Za-z])\b"#,
                "$1-$2")
        },

        // Terminal only: "traço traço verbose" → --verbose, "traço m" → -m.
        // Aggressive on purpose, exactly as the model prompt is told to be —
        // and inert on a command nobody spoke a dash into ("git status").
        CleanupRule(name: "pt spoken flags", stage: .early, runsInTerminal: true) { text, context in
            guard context.category == .terminal else { return text }
            let dash = #"\b\#(PortugueseText.dashWord)\b"#
            var out = PortugueseText.sub(
                text, dash + #"\s+"# + dash + #"\s+([A-Za-z0-9][A-Za-z0-9._-]*)"#, "--$1")
            out = PortugueseText.sub(out, dash + #"\s+([A-Za-z0-9][A-Za-z0-9._-]*)"#, "-$1")
            return out
        },

        // Terminal only: "til barra projetos barra voicetype" →
        // ~/projetos/voicetype, "ponto barra build" → ./build. In prose
        // "barra" is always a word.
        //
        // Declared at `.afterPunctuation`: the shared Latin pass deletes the
        // whitespace before a ".", which would glue "python ./scripts" into
        // "python./scripts" if the path were rendered any earlier.
        CleanupRule(name: "pt spoken paths", stage: .afterPunctuation, runsInTerminal: true) { text, context in
            guard context.category == .terminal else { return text }
            var out = PortugueseText.sub(text, #"\btil\s+barra\s+"#, "~/")
            out = PortugueseText.sub(out, #"\bponto\s+barra\s+"#, "./")
            return PortugueseText.subRepeat(
                out, #"([~./A-Za-z0-9_-]+)\s+barra\s+([A-Za-z0-9._-]+)"#, "$1/$2")
        },
    ]
}

/// The lexicons and regex helpers the Portuguese rules share. Namespaced rather
/// than left as file globals so nothing in this language directory can collide
/// with another language's pack.
enum PortugueseText {
    /// Function words that must never be joined into a dictated identifier —
    /// the guard that keeps "eu quero underline o texto" and "o ponto de
    /// vista" prose. A regex-shaped subset of `portugueseStopwords`.
    static let joinGuard =
        "(?:o|a|os|as|um|uma|uns|umas|de|do|da|dos|das|em|no|na|nos|nas"
        + "|e|ou|que|se|para|pra|pro|por|com|sem|ao|aos|à|às|meu|minha|seu|sua|nosso|nossa"
        + "|isso|isto|esse|essa|este|esta|aquele|aquela|eu|tu|ele|ela|eles|elas|nós|você|vocês"
        + "|não|é|ser|ter|tem|está|estão|vai|vou|muito|mais|menos|já|só|bem|aqui|ali|lá"
        + "|quero|queria|acho|achei|ponto|pontos)"

    /// Words that read as prose immediately before an "arroba", so a sentence
    /// is never mistaken for the local part of an address.
    static let emailLocalGuard =
        "(?:\(joinGuard)|olha|olhe|veja|manda|mande|envia|envie|escreve|escreva"
        + "|chega|chegou|volta|fica|ficou|depois|antes|reunião|reuniao|encontro)"

    /// Extensions safe to join after a spoken "ponto", plus the two Portuguese
    /// homophones of ".py". Keep to common, unambiguous ones — anything else
    /// stays prose.
    static let fileExtensions =
        "py|js|ts|jsx|tsx|rs|go|swift|c|h|cpp|hpp|java|rb|php|sh|md|txt"
        + "|json|yaml|yml|toml|html|css|xml|sql|csv|log|lock|env|pai|pi"

    /// Top-level domains that anchor the spoken-email pattern; "br" and "pt"
    /// are the ones this language actually needs.
    static let emailTLDs = "com|net|org|io|co|dev|app|ai|edu|gov|me|br|pt"

    /// The words Portuguese uses for a hyphen, including the unaccented
    /// spellings transcribers produce.
    static let dashWord = "(?:tra[çc]o|h[íi]fen)"

    /// A regex substitution that degrades to "no change" when the pattern does
    /// not compile, so a typo in this pack can never crash a dictation.
    /// Case-insensitive by default, which is what spoken-name matching needs —
    /// the same name arrives capitalized at a sentence start.
    static func sub(_ text: String, _ pattern: String, _ template: String,
                    options: NSRegularExpression.Options = [.caseInsensitive]) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range,
                                              withTemplate: template)
    }

    /// `sub` applied until the text stops changing, for joins that chain: each
    /// pass consumes one trigger word, so "get underline user underline data"
    /// needs two. Bounded so a pathological pattern cannot spin.
    static func subRepeat(_ text: String, _ pattern: String, _ template: String,
                          options: NSRegularExpression.Options = [.caseInsensitive]) -> String {
        var out = text
        for _ in 0..<8 {
            let next = sub(out, pattern, template, options: options)
            if next == out { break }
            out = next
        }
        return out
    }
}
