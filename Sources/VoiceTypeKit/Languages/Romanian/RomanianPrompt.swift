import Foundation

extension LanguagePromptGuidance {
    /// Romanian guidance for the on-device cleanup model. No few-shot examples
    /// ship: the Romanian model engine was intentionally not run during the
    /// parallel localization round, so there is no evidence that examples
    /// outweigh the known echo/leakage risk.
    static let romanian = LanguagePromptGuidance(
        fillerExamples: #": non-lexical hesitation sounds such as "ă", "ăăă", "îîî", "ăm", and "ăhm"; remove "mmm", "hm", or "mhm" only when it is clearly hesitation rather than appreciation, doubt, or agreement; remove "deci", "păi", "adică", "gen", "mă rog", "știi", "bun", or "așa" only when context proves it is empty verbal padding, never when it connects, qualifies, reformulates, exemplifies, or otherwise contributes meaning"#,
        capitalizationRule: """
        Fix Romanian capitalization: capitalize sentence starts and proper \
        names, including the official significant words of institution and \
        organization names. Keep ordinary nouns, languages, nationalities, \
        weekdays, and month names lowercase unless they begin a sentence. \
        Preserve established acronym and code casing; do not mistake a period \
        in an abbreviation such as "nr.", "str.", "dl.", "prof.", or "etc." \
        for the end of a sentence.
        """,
        codeRendering: """
        When the surrounding Romanian words clearly dictate code, render it \
        compactly and keep ordinary prose untouched:
        - File names: "main punct pai" → main.py, "config punct geison" → \
        config.json. Interpret punct as a dot only beside a plausible file \
        extension, domain, address, or path; "un punct important" stays words.
        - Identifiers: "max underscore retries" → max_retries. Consume the \
        joiner word and never join words the speaker did not mark.
        - Tech symbols: "deschide paranteză" / "închide paranteză" → ( ), \
        "semnul egal" → =, "minus" or "cratimă" → -, "slash" or "bară \
        oblică" → /, "tildă" → ~, and "arond" → @ when the context is code.
        - Keep file names, paths, commands, URLs, email addresses, identifiers, \
        flags, and extensions in their intended ASCII spelling and casing. Do \
        not translate English technical tokens or add Romanian diacritics to \
        them.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Expect Romanian framing around \
        exact shell commands, flags, and paths:
        - "minus minus verbose" → --verbose, "minus v" → -v, "tildă slash \
        proiecte" → ~/proiecte, and "punct slash build" → ./build.
        - Preserve command names, subcommands, flags, paths, environment \
        variables, and identifiers exactly; commands normally remain lowercase \
        ASCII. Never translate them, capitalize the command, typographically \
        replace ASCII syntax, or add sentence-final punctuation.
        - If the dictated text is clearly Romanian prose for a commit message \
        or another quoted argument, clean that prose while leaving its shell \
        quoting and surrounding command syntax intact.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Prefer compact code rendering \
        when Romanian symbol names surround identifiers, file names, operators, \
        or syntax. Preserve ASCII syntax, exact identifier casing, English API \
        names, and code literals. Romanian comments, documentation, and prose \
        still use correct diacritics, punctuation, and sentence capitalization.
        """,
        selfCorrectionRule: """
        Resolve explicit Romanian self-corrections by keeping only the last \
        intended version: "cinci, nu, șase exemplare" → "șase exemplare" and \
        "marți, de fapt miercuri" → "miercuri". Treat "adică" as a correction \
        cue only when the speaker retracts or replaces the previous wording; \
        keep it when it explains, defines, translates, or reformulates content \
        that remains part of the message.
        """,
        addendum: """
        - Use the Romanian letters ă, â, î, ș, and ț with comma-below ș/ț, \
        never legacy cedilla ş/ţ. Restore omitted diacritics only from clear \
        grammatical and lexical context; never guess inside names or code.
        - Romanian prose uses quotation marks „…” and nested «…». Do not \
        convert straight quotes that are code syntax. Put no space before \
        commas, periods, semicolons, colons, question marks, or exclamation \
        marks, and one space after them when text follows.
        - Write decimals with a comma (13,6), times with a colon (14:30), and \
        ordinary numeric dates day–month–year (31.12.2026). Keep Romanian month \
        and weekday names lowercase. Keep the amount and currency together \
        with the amount first (25 lei, 25 RON, 25 €). Preserve an already \
        coherent thousands-grouping style rather than changing its separator.
        - Romanian clitics and contractions use a hyphen, for example s-a, \
        m-am, n-am, și-a, într-un, and dintr-o. An apostrophe marks genuine \
        omission (for example anii ’90), not ordinary clitic attachment. Repair \
        sa/s-a, sau/s-au, ia/i-a, la/l-a, mai/m-ai, nea/ne-a, and va/v-a only \
        when syntax makes the intended form certain; otherwise keep the \
        transcript.
        - Render spoken punctuation names only when they function as dictation \
        commands. Bare punct, virgulă, and două puncte can be content; keep \
        them as words when the speaker is discussing a point, comma, score, or \
        other literal meaning.
        """)
}
