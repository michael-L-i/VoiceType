import Foundation

extension LanguagePromptGuidance {
    /// Italian's contribution to the on-device cleanup instruction.
    ///
    /// The division of labour with `ItalianRules` is deliberate: anything that
    /// is *always* right in Italian (accents, elision spacing, the decimal
    /// comma, compound punctuation names) is already guaranteed in code before
    /// the model's output is shown, so the prompt spends its tokens only on the
    /// calls that need a sentence's worth of context — which of the *segnali
    /// discorsivi* are filler this time, whether a bare "punto" names a
    /// character or a point, whether "Lei" is a courtesy form.
    ///
    /// `fewShot` stays empty. The battery in `Scripts/cleanup-eval/cases.it.json`
    /// was written against the deterministic path; until an `--engine model`
    /// run shows examples earn their place, shipping them only risks the
    /// leakage documented in Scripts/cleanup-eval/README.md.
    static let italian = LanguagePromptGuidance(
        fillerExamples: #": "ehm", "uhm", "mmm". Also drop "cioè", "diciamo", "tipo", "praticamente", "insomma", "allora", "niente", "no?" and "eh" ONLY when they are hesitation and carry no meaning — each of them is a real word too ("allora partiamo", "cioè il punto è questo", "un tipo strano"), and when in doubt you keep it"#,
        capitalizationRule: """
        Fix capitalization the Italian way: a capital letter starts every \
        sentence and marks proper nouns (names, places, brands), but Italian \
        keeps LOWERCASE what English capitalizes — the days of the week \
        (lunedì, sabato), the months (gennaio, maggio), the seasons, the \
        languages and nationality adjectives (italiano, inglese, francese), \
        and the pronoun "io". A sentence that begins with "è" is written "È", \
        never "E'".
        """,
        codeRendering: """
        When the surrounding words make it clear the speaker is spelling out \
        something technical — a file name, an identifier, an address, a \
        handle — render it compactly, and leave ordinary prose alone:
        - "punto" → . only when it names the character: before a file \
        extension ("main punto py" → main.py) or inside an address. The \
        ordinary noun stays a word: "il punto è che", "a un certo punto", "fino \
        a questo punto" are prose.
        - "virgola" → , only between digits ("tre virgola cinque" → 3,5); \
        elsewhere it is the noun.
        - "trattino" → -, "trattino basso" → _, "barra" → /, "barra \
        rovesciata" → \\, "chiocciola" → @, "due punti" → :, "cancelletto" → #, \
        "asterisco" → *, "parentesi aperta"/"parentesi chiusa" → ( ). Italian \
        speakers also borrow the English names — "underscore", "slash", "dot", \
        "camel case" — treat those the same way.
        - Identifiers join up: "max trattino basso tentativi" → max_tentativi, \
        "camel case leggi utente" → leggiUtente, "mario punto rossi chiocciola \
        gmail punto com" → mario.rossi@gmail.com.
        - The trigger word is consumed, never kept: "max trattino basso \
        tentativi" → max_tentativi, never max_trattino_basso_tentativi.
        - Never join words the speaker did not mark: "il token di sessione" \
        stays three words.
        - Keep English technical terms, commands, and identifiers exactly as \
        spoken, in ASCII: do not translate "commit", "build", "deploy", \
        "branch", "token" into Italian.
        """,
        terminalGuidance: """
        The user is dictating into a terminal, so expect shell commands, \
        options, and paths mixed with ordinary sentences:
        - Render spoken options and paths: "trattino trattino verbose" → \
        --verbose, "trattino emme" → -m, "tilde barra progetti" → ~/progetti, \
        "punto barra build" → ./build.
        - Commands are spelled the way the tool spells them: lowercase (git \
        status, ls, npm run build), never capitalize the first word of a \
        command, and never add a full stop at the end of one.
        - Commands stay in English even inside Italian dictation — never \
        translate "commit", "push", "branch", "status".
        - A dictated sentence that is plainly prose (a commit message, a chat \
        reply) still gets normal Italian punctuation and capitalization.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. When the words suggest code, \
        lean toward the compact rendering above — identifiers, file names and \
        symbols are likelier here than in ordinary writing, and English \
        keywords stay English. Prose (comments, commit messages, \
        documentation) still reads as normal Italian sentences.
        """,
        selfCorrectionRule: """
        Resolve self-corrections: when the speaker changes their mind \
        mid-sentence — usually with "anzi", "no scusa", "volevo dire", "cioè \
        no" — keep only the corrected version, the one spoken LAST, and drop \
        both the earlier attempt and the marker: "mandalo a Marco, anzi no, a \
        Giulia" → "mandalo a Giulia", never "mandalo a Marco".
        """,
        addendum: """
        - The dictation is Italian. Use Italian punctuation spacing: no space \
        before , . ; : ! ? and one space after; the apostrophe of an elision \
        takes no space at all ("l'amico", "dell'anno", "un'altra").
        - Italian spelling to respect: acute accents on perché, poiché, benché, \
        finché, né, sé — never "perchè" or "perche'"; "è" not "e'"; "un po'" \
        with an apostrophe, never "pò"; "qual è" without one; "un altro" \
        (masculine) takes no apostrophe, "un'altra" does.
        - Numbers follow the Italian convention: comma for decimals and point \
        for thousands (3,14 — 1.000). Dates read "5 gennaio 2027", with the \
        month lowercase.
        - Quotation marks are «caporali» or "virgolette alte", with no space \
        inside them.
        """)
}
