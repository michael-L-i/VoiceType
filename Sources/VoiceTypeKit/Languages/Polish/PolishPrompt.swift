import Foundation

extension LanguagePromptGuidance {
    /// Polish's contribution to the on-device cleanup instruction.
    ///
    /// The division of labour with `PolishRules` is deliberate: anything that
    /// is *always* right in Polish (quotation marks, the wielokropek, the
    /// obligatory clause comma, the spaced myślnik) is done in code, where it
    /// costs no prompt tokens and cannot be ignored. What is left here needs
    /// meaning — which `no` is a hesitation and which is a word, whether
    /// `kropka` names a mark or a dot, whether "trzy przecinek czternaście" is
    /// a number.
    ///
    /// `fewShot` ships empty. The rule in docs/LOCALIZATION.md is that a
    /// language only adds examples once its own model-engine eval shows they
    /// earn their place, and the model has been observed echoing example
    /// content into unrelated output. This pack was built with the rules
    /// engine only (the on-device model is a single shared resource), so it
    /// has no such evidence and ships none.
    static let polish = LanguagePromptGuidance(
        fillerExamples: #": "yyy", "eee", "mmm", "hmm", and throwaway "no", "wiesz", "znaczy", "jakby", "tak jakby", "w sumie", "po prostu", "prawda" when they carry no meaning. Be careful: "no" is usually a real word in Polish ("no dobra", "no i co", "no nie?") — drop it only when it is pure hesitation, and keep "yhy"/"aha"/"mhm", which mean "yes""#,
        // Polish capitalization differs from English in exactly the places the
        // generic instruction gets wrong, so it is replaced wholesale.
        capitalizationRule: """
        Fix capitalization the Polish way: start every sentence with a capital \
        letter, and capitalize proper names — people, places, titles, and the \
        NOUNS naming nationalities and inhabitants (Polak, Niemka, Ślązak, \
        Warszawiak). Polish writes several things in LOWERCASE that English \
        capitalizes, and you must not "fix" them: days of the week \
        (poniedziałek, środa), months (styczeń, marzec), and adjectives of \
        nationality or language (polski, angielski, niemiecki, po polsku). \
        Capitalize the polite pronouns Pan, Pani, Państwo, and — only when the \
        speaker is addressing one person directly, as in a message or letter — \
        Ty, Ciebie, Tobie, Twój, Wam.
        """,
        codeRendering: """
        When the surrounding words make it clear the speaker is dictating code \
        — a file name, a symbol, an identifier, or a username/handle — render \
        it compactly instead of as separate words, and leave ordinary prose \
        alone. Polish speakers say the identifier in English and the connector \
        in Polish, so expect a mix:
        - File names: "main kropka py" → main.py, "index kropka ts" → index.ts. \
        Pick the extension from context (.py, .js, .ts, .rs, .go, .swift).
        - Spoken symbols → characters: "kropka" → ., "przecinek" → ,, \
        "podkreślnik"/"podkreślenie" → _, "myślnik"/"łącznik" → -, "ukośnik" → \
        /, "tylda" → ~, "małpa" → @, "gwiazdka" → *, "krzyżyk" → #, \
        "dwukropek" → :, "średnik" → ;, "znak równości" → =, "otwórz nawias" / \
        "zamknij nawias" → ( ), "nawias kwadratowy" → [ ].
        - Identifiers join up: "max podkreślnik retries" → max_retries, \
        "camel case parse request" → parseRequest, "michał myślnik L" → \
        michał-L (join with hyphens; keep handles lowercase unless a letter is \
        spoken on its own).
        - The trigger word is consumed, never kept: "max podkreślnik retries" → \
        max_retries, never max_podkreślnik_retries. Never join words the \
        speaker did not mark: "token sesji" stays two separate words.
        - Keep an English identifier in English — NEVER translate it. \
        "user data" inside Polish dictation stays user_data, not \
        dane_użytkownika.
        - A trigger word inside ordinary prose stays prose: "kropka nad i" and \
        "i kropka" are idioms, not punctuation, and "trzy przecinek \
        czternaście" is the number 3,14.
        """,
        terminalGuidance: """
        The user is dictating into a terminal, so expect shell commands, flags, \
        paths, and git vocabulary alongside ordinary sentences:
        - Render spoken flags and paths: "myślnik myślnik verbose" → --verbose, \
        "myślnik v" → -v, "tylda ukośnik projekty" → ~/projekty, "kropka \
        ukośnik build" → ./build.
        - Command lines stay exactly as commands are spelled: lowercase (git \
        status, ls, tmux attach), never capitalize the first word of a command, \
        never add a trailing period, and never translate a command or a flag \
        into Polish.
        - A dictated sentence that is clearly prose (a commit message, a chat \
        reply) still gets normal Polish punctuation and capitalization.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. When the words suggest code, \
        lean toward the compact rendering above — identifiers, file names, and \
        symbols are more likely here than in ordinary writing, and they stay in \
        English even when the surrounding speech is Polish. Prose (comments, \
        commit messages, documentation) reads as normal Polish sentences, with \
        Polish punctuation and diacritics.
        """,
        selfCorrectionRule: """
        Resolve self-corrections: when the speaker changes their mind \
        mid-sentence — usually marked by "nie", "znaczy", "to znaczy", \
        "raczej", "a właściwie", "przepraszam" — keep only the version spoken \
        LAST and drop both the earlier attempt and the marker: "pięć, nie, \
        sześć kopii" → "sześć kopii", never "pięć kopii"; "we wtorek, znaczy w \
        środę" → "w środę".
        """,
        addendum: """
        - The dictation is Polish. Keep every Polish diacritic exactly as \
        spoken (ą ć ę ł ń ó ś ź ż) — never write "zazolc" for "zażółć".
        - Polish punctuation is grammatical, not optional: put a comma before \
        the word that opens a subordinate clause (że, iż, żeby, aby, bo, \
        ponieważ, gdyż, jeśli, jeżeli, który/która/które and its inflections), \
        e.g. "Myślę, że to dobry pomysł" and "Dom, w którym mieszkam". When \
        two conjunctions meet, the comma goes before the first one, and \
        compound conjunctions take it before their first word: "…, dlatego \
        że …", "…, mimo że …", "…, chyba że …".
        - Polish quotation marks are „…” — lower opening, upper closing.
        - Numbers follow Polish conventions: a comma is the decimal separator \
        (3,14 — never 3.14), thousands are grouped with a space (12 345), and \
        the currency follows the amount (25 zł, 100 euro). Dates are written \
        "12 marca 2026" or 12.03.2026.
        - Keep embedded English words, file names, identifiers, and commands in \
        ASCII with ASCII punctuation inside them.
        """)
}
