import Foundation

extension LanguagePromptGuidance {
    /// English's contribution to the cleanup instruction — moved here verbatim
    /// from `CleanupPrompt`, where it used to be hardcoded and therefore sent
    /// to every language. A German dictation was being told to strip "um" and
    /// "you know" and to render the spoken word "dot"; it now gets German's
    /// guidance, or a language-neutral instruction where German is silent.
    static let english = LanguagePromptGuidance(
        fillerExamples: #": "um", "uh", "er", "hmm", and throwaway "you know" / "I mean" / "like" / "so" when they carry no meaning"#,
        capitalizationRule: #"Fix capitalization: start every sentence with a capital letter, always capitalize the pronoun "I", and capitalize proper nouns (names, days, places)."#,
        codeRendering: """
        When the surrounding words make it clear the speaker is dictating code — a \
        file name, a symbol, an identifier, or a username/handle — render it \
        compactly instead of as separate words, and leave ordinary prose alone:
        - File names → paths: "app dot pie" → app.py. Pick the extension from \
        context (.py, .js, .ts, .rs, .go, .swift); resolve homophones like "pie" → .py.
        - Spoken symbols → characters: "dot" → ., "underscore" → _, "dash"/"hyphen" \
        → -, "open paren"/"close paren" → ( ), "open bracket"/"close bracket" → \
        [ ], "equals" → =, "comma" → ,.
        - Identifiers & handles join up: "get underscore user data" → \
        get_user_data, "camel case parse request" → parseRequest, "michael dash L \
        dash I" → michael-L-i (join with hyphens; keep handles lowercase unless a \
        letter is spoken on its own).
        - The trigger word is consumed, never kept: "max underscore retries" → \
        max_retries, never max_underscore_retries. And never join words the \
        speaker did not mark: "the session token" stays three separate words.
        - But a trigger word inside ordinary prose stays prose: "the dot product" \
        is NOT "the.product".
        """,
        terminalGuidance: """
        The user is dictating into a terminal, so expect shell commands, flags, \
        paths, and git/tmux vocabulary alongside ordinary sentences:
        - Render spoken flags and paths: "dash dash verbose" → --verbose, "dash \
        v" → -v, "tilde slash projects" → ~/projects, "dot slash build" → ./build.
        - Command lines stay exactly as commands are spelled: lowercase (git \
        status, ls, tmux attach), never capitalize the first word of a command, \
        and never add a trailing period to a command.
        - A dictated sentence that is clearly prose (a commit message, a chat \
        reply) still gets normal punctuation and capitalization.
        """,
        // English is the only language whose few-shot block has been through
        // the eval battery — see CleanupExamples and docs/LOCALIZATION.md.
        fewShot: CleanupExamples.fewShot,
        terminalFewShot: CleanupExamples.terminalFewShot,
        addendum: nil)
}
