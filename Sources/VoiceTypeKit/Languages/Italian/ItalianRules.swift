import Foundation

/// Italian's own deterministic fixes. Everything here is a convention that is
/// *always* right in Italian, so it is encoded in code rather than asked of the
/// model; anything that needs meaning to decide lives in `ItalianPrompt`.
///
/// The order these run in is declared by the pack (`italianRules` in
/// `ItalianPack.swift`), and it matters:
/// 1. accents run before the apostrophe join, so the ASCII spelling `e'` has
///    already become `è` and can never be glued to the next word;
/// 2. the spoken-symbol rules (`ItalianSymbols`) run after both, on words that
///    are already spelled the way Italian spells them;
/// 3. the numeric and typographic rules run at `.afterPunctuation`, because the
///    shared Latin spacing pass would otherwise undo them (it splits `3,14`
///    into `3, 14`);
/// 4. the line-break commands run at `.final`, after capitalization, because
///    the shared passes collapse whitespace — including a newline — and the
///    capitalizer tokenizes on spaces only.
extension LanguagePack {

    // MARK: - Accents

    /// Restore the accent on spellings that exist *only* as the accented word,
    /// and correct grave-for-acute on the `-ché` family.
    ///
    /// Sources: Accademia della Crusca, *Vademecum sull'accento* — `perché`,
    /// `né`, `sé`, `poiché`, `benché`, `finché`, `affinché`, `purché`,
    /// `nonché`, `cosicché` take the **acute** accent, and the grave (`perchè`)
    /// or apostrophe (`perche'`) spellings are errors. `po'` is written with an
    /// apostrophe and never `pò`. Treccani/Crusca, *elisione e troncamento* —
    /// `qual è` takes no apostrophe (it is a truncation, not an elision), and
    /// the masculine article `un` is never apostrophized (`un altro`, not
    /// `un'altro`, while the feminine `un'altra` is correct).
    ///
    /// The house rule that keeps this safe: a key only appears here when the
    /// bare spelling is not itself an Italian word. That is why `pero` (pear
    /// tree), `meta` (goal), `papa` (pope), `sara` (a name), `unita`,
    /// `necessita` and `facilita` (all verb/participle forms) are absent while
    /// their apostrophe spellings `pero'`, `meta'`, `papa'`, `sara'` are here:
    /// a trailing apostrophe on those words is never anything but an accent
    /// typed on a keyboard that lacked one.
    static let italianAccentRule = CleanupRule(
        name: "accenti e apostrofi normativi",
        stage: .early) { text, _ in
        italianRestoringAccents(text)
    }

    static let italianAccentFixes: [String: String] = [
        // "è" typed or transcribed as ASCII.
        "e'": "è",
        // The -ché family: acute accent, never grave, never an apostrophe.
        "perche": "perché", "perchè": "perché", "perche'": "perché",
        "poiche": "poiché", "poichè": "poiché", "poiche'": "poiché",
        "benche": "benché", "benchè": "benché", "benche'": "benché",
        "finche": "finché", "finchè": "finché", "finche'": "finché",
        "affinche": "affinché", "affinchè": "affinché",
        "nonche": "nonché", "nonchè": "nonché",
        "sicche": "sicché", "sicchè": "sicché",
        "cosicche": "cosicché", "cosicchè": "cosicché",
        "purche": "purché", "purchè": "purché",
        "anziche": "anziché", "anzichè": "anziché",
        "dacche": "dacché", "dacchè": "dacché",
        "allorche": "allorché", "allorchè": "allorché",
        "fuorche": "fuorché", "fuorchè": "fuorché",
        // "giacche" is deliberately absent — it is the plural of "giacca".
        "giacchè": "giacché",
        "nè": "né", "sè": "sé",
        // Monosyllables and adverbs whose bare spelling is not a word.
        "piu": "più", "piu'": "più",
        "giu": "giù", "giu'": "giù",
        "gia": "già", "gia'": "già",
        "puo": "può", "puo'": "può",
        "cosi": "così", "cosi'": "così",
        "cioe": "cioè", "cioe'": "cioè",
        "caffe": "caffè", "caffe'": "caffè",
        "percio": "perciò", "percio'": "perciò",
        "ahime": "ahimè", "ahime'": "ahimè",
        // Homographs: only the apostrophe spelling is safe to rewrite.
        "pero'": "però", "meta'": "metà", "papa'": "papà", "sara'": "sarà",
        "verra'": "verrà", "potra'": "potrà", "dovra'": "dovrà",
        "fara'": "farà", "andra'": "andrà",
        // -tà nouns with no unaccented reading.
        "citta": "città", "citta'": "città",
        "universita": "università", "universita'": "università",
        "qualita": "qualità", "quantita": "quantità",
        "liberta": "libertà", "verita": "verità", "societa": "società",
        "attivita": "attività", "possibilita": "possibilità",
        "novita": "novità", "realta": "realtà", "difficolta": "difficoltà",
        "velocita": "velocità", "capacita": "capacità",
        "identita": "identità", "priorita": "priorità",
        "autorita": "autorità", "comunita": "comunità",
        "utilita": "utilità", "responsabilita": "responsabilità",
        "opportunita": "opportunità", "curiosita": "curiosità",
        "finalita": "finalità", "modalita": "modalità",
        "funzionalita": "funzionalità", "compatibilita": "compatibilità",
        // Weekdays: the unaccented spellings are not words.
        "lunedi": "lunedì", "martedi": "martedì", "mercoledi": "mercoledì",
        "giovedi": "giovedì", "venerdi": "venerdì",
        // Truncation, not accent: "un po'", never "un pò".
        "pò": "po'",
        // Apostrophes that shouldn't be there at all.
        "qual'è": "qual è", "qual'e'": "qual è", "qual'era": "qual era",
        "un'altro": "un altro", "qualcun'altro": "qualcun altro",
        "nessun'altro": "nessun altro",
        // Compound numerals in -tré take the acute accent.
        "ventitre": "ventitré", "ventitrè": "ventitré",
        "trentatre": "trentatré", "trentatrè": "trentatré",
        "quarantatre": "quarantatré", "quarantatrè": "quarantatré",
    ]

    /// Word-wise so an identifier or a file name is never rewritten: only whole
    /// letter tokens (optionally carrying one apostrophe) are looked up, and a
    /// token that isn't in the table is returned byte-for-byte.
    static func italianRestoringAccents(_ text: String) -> String {
        guard text.contains(where: { $0.isLetter }),
              let regex = try? NSRegularExpression(pattern: #"\p{L}+(?:['’]\p{L}*)?"#)
        else { return text }
        // `c'e'` / `n'e'` — the ASCII spelling of "c'è" / "n'è". The token pass
        // below can't see it: the elision apostrophe already claimed the `e`,
        // so the accent apostrophe is left dangling on its own.
        var out = italianReplacing(text, pattern: #"(?<=['’])e['’](?!\p{L})"#, template: "è")
        let source = out
        let matches = regex.matches(in: source, range: NSRange(source.startIndex..., in: source))
        for match in matches.reversed() {
            guard let range = Range(match.range, in: out) else { continue }
            let token = String(out[range])
            let key = token.lowercased().replacingOccurrences(of: "\u{2019}", with: "'")
            // An elided article swallows the word into one token
            // ("l'universita"), so a whole-token miss falls back to the part
            // after the apostrophe — the prefix keeps whatever case it had.
            var prefix = ""
            var stem = token
            var fixed = italianAccentFixes[key]
            if fixed == nil, let cut = key.lastIndex(of: "'"), cut != key.startIndex {
                let split = token.index(token.startIndex,
                                        offsetBy: key.distance(from: key.startIndex, to: cut) + 1)
                let tail = String(token[split...])
                guard !tail.isEmpty, let mapped = italianAccentFixes[tail.lowercased()] else { continue }
                prefix = String(token[..<split])
                stem = tail
                fixed = mapped
            }
            guard let fixed, prefix + fixed != token else { continue }
            // Preserve how the speaker's transcript capitalized it: "Perche" →
            // "Perché", "E'" → "È" (an all-caps token uppercases wholesale, so
            // the two-character "E'" lands on "È" rather than "È'").
            let replacement: String
            if stem == stem.uppercased() && stem.contains(where: { $0.isLetter }) {
                replacement = fixed.uppercased()
            } else if stem.first?.isUppercase == true {
                replacement = fixed.prefix(1).uppercased() + fixed.dropFirst()
            } else {
                replacement = fixed
            }
            out.replaceSubrange(range, with: prefix + replacement)
        }
        return out
    }

    // MARK: - Apostrophe

    /// Close the gap a transcriber leaves after an elision: `l' amico` →
    /// `l'amico`, `dell' acqua` → `dell'acqua`, `cos' è` → `cos'è`.
    ///
    /// Source: Treccani, *domande e risposte* on punctuation — "non bisogna
    /// lasciare spazi tra l'apostrofo e la parola successiva".
    ///
    /// The blacklist is the whole trick. Italian also uses an apostrophe for
    /// **troncamento**, where a space legitimately follows: `un po' di tempo`,
    /// `va' via`, `fa' presto`, `da' retta`, `di' pure`, `sta' zitto`, `be'`,
    /// `mo'`, `Ca' Foscari`. Those forms are excluded by name, so the rule can
    /// never weld them onto the next word. `e'` is listed too as a backstop for
    /// any ASCII `è` the accent table above didn't catch.
    static let italianApostropheRule = CleanupRule.regex(
        name: "nessuno spazio dopo l'apostrofo",
        stage: .early,
        pattern: #"\b(?!(?:e|po|mo|be|ca|fa|da|va|di|to|pe|sta)['’])(\p{L}{1,7}['’])[ \t]+(?=\p{L})"#,
        template: "$1",
        options: [.caseInsensitive])

    // MARK: - Helpers

    /// A regex replacement that degrades to "no change" if the pattern doesn't
    /// compile, matching `CleanupRule.regex`'s contract.
    static func italianReplacing(_ text: String, pattern: String, template: String,
                                 options: NSRegularExpression.Options = []) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range,
                                              withTemplate: template)
    }

    /// Lowercase every match of `pattern` in place. Needed because a regex
    /// template can substitute text but not case-map it.
    static func italianLowercasingMatches(_ text: String, pattern: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return text
        }
        var out = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches.reversed() {
            guard let range = Range(match.range, in: out) else { continue }
            out.replaceSubrange(range, with: out[range].lowercased())
        }
        return out
    }
}
