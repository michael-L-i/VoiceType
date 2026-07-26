import Foundation

extension LanguagePromptGuidance {
    /// Dutch's contribution to the on-device cleanup instruction.
    ///
    /// Division of labour with `DutchRules`: anything that is *always* right in
    /// Dutch is deterministic and is not repeated here (spacing around € and %,
    /// the IJ digraph, the capital after a sentence-initial 's/'t/'n/'k, the
    /// decimal comma). What is left for the model is everything that needs
    /// meaning: which hesitation is empty, which split compound was one word,
    /// which of two attempts the speaker meant.
    ///
    /// `fewShot` stays empty on purpose. The eval battery for this pack runs
    /// the rules engine (the model battery is not parallel-safe), so no Dutch
    /// example pair has earned its place yet — and the harness' own record of
    /// few-shot leakage says an unproven example costs more than it buys.
    static let dutch = LanguagePromptGuidance(
        fillerExamples: #": "uh", "uhm", "eh", "ehm", "hmm", and a throwaway "zeg maar" / "weet je" / "ik bedoel" / "nou" / "dus" / "gewoon" when it carries no meaning"#,
        capitalizationRule: """
        Fix capitalization the Dutch way: start every sentence with a capital \
        letter, and capitalize proper nouns, place names, holidays (Kerstmis, \
        Pasen, Koningsdag) and adjectives derived from a place name (de \
        Nederlandse taal, Franse kaas, de Amsterdamse grachten). Do NOT \
        capitalize the pronoun "ik", weekdays, months or seasons — they are \
        lowercase in Dutch (maandag, januari, zomer). A word that begins with \
        the digraph "ij" takes TWO capitals when it is capitalized: IJsland, \
        IJssel, IJmuiden — never "Ijsland". When a sentence opens with 's, 't, \
        'n or 'k, that stays lowercase and the NEXT word takes the capital: \
        "'s Ochtends regent het."
        """,
        codeRendering: """
        When the surrounding words make it clear the speaker is dictating code \
        — a file name, an identifier, a path, an e-mail address or a handle — \
        render it compactly instead of as separate words, and leave ordinary \
        prose alone:
        - Spoken symbols → characters: "punt" → ., "komma" → ,, \
        "streepje"/"koppelteken" → -, "underscore"/"liggend streepje" → _, \
        "schuine streep" → /, "apenstaartje" → @, "haakje openen"/"haakje \
        sluiten" → ( ), "vierkante haakjes" → [ ], "puntkomma" → ;.
        - File names → paths: "main punt py" → main.py, "config punt json" → \
        config.json, "src schuine streep index punt ts" → src/index.ts.
        - Identifiers and addresses join up: "max underscore retries" → \
        max_retries, "jan apenstaartje voorbeeld punt nl" → jan@voorbeeld.nl.
        - The trigger word is consumed, never kept: "max underscore retries" → \
        max_retries, never max_underscore_retries. And never join words the \
        speaker did not mark: "de sessie token" stays three words.
        - But a trigger word inside ordinary prose stays prose: "dat is een \
        goed punt" keeps the word "punt", and "drie komma vijf" is the number \
        3,5 — not a comma.
        - English keywords, library names, API names and commands stay in \
        English; never translate them into Dutch.
        """,
        terminalGuidance: """
        The user is dictating into a terminal, so expect shell commands, flags, \
        paths and git/tmux vocabulary alongside ordinary sentences:
        - Render spoken flags and paths: "streepje streepje verbose" → \
        --verbose, "streepje v" → -v, "tilde schuine streep projecten" → \
        ~/projecten, "punt schuine streep build" → ./build.
        - Command lines stay exactly as commands are spelled: lowercase (git \
        status, ls, tmux attach), never capitalize the first word of a command, \
        never add a trailing period to a command, and never translate a command \
        or a flag into Dutch.
        - A dictated sentence that is clearly prose (a commit message, a chat \
        reply) still gets normal Dutch punctuation and capitalization.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. When the words suggest code, \
        lean toward the compact rendering above — identifiers, file names and \
        symbols are more likely here than in ordinary writing, and English \
        keywords, library names and API names stay in English rather than being \
        translated into Dutch. Prose (comments, commit messages, documentation) \
        still reads as ordinary Dutch sentences.
        """,
        selfCorrectionRule: """
        Resolve self-corrections: when the speaker changes their mind \
        mid-sentence — usually marked by "nee", "eh nee", "sorry", "ik bedoel" \
        or "oftewel" — keep only the corrected version, the one spoken LAST, \
        and drop both the earlier attempt and the marker: "vijf, nee zes \
        exemplaren" → "zes exemplaren", never "vijf exemplaren".
        """,
        addendum: """
        - Dutch compound nouns are written as ONE word. If the transcript split \
        one ("taal fout", "camera ploeg", "software ontwikkelaar"), join it back \
        up ("taalfout", "cameraploeg", "softwareontwikkelaar") — but never glue \
        together words that were genuinely separate.
        - Always drop the hesitation sounds "uh", "uhm", "eh", "ehm". Drop \
        "nou", "dus", "gewoon", "eigenlijk", "even", "toch", "zeg maar" or \
        "weet je" ONLY when they are clearly empty hesitations: each is also a \
        real word ("dus" = therefore, "even" = for a moment, "toch" = after \
        all). When in doubt, keep it.
        - Keep the Dutch number conventions the speaker used: a comma is the \
        decimal separator and a period groups thousands (3,5 — € 1.250,00).
        """)
}
