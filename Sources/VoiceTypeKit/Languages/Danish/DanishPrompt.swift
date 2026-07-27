import Foundation

extension LanguagePromptGuidance {
    /// Danish-specific cleanup guidance. Few-shot examples intentionally stay
    /// empty: they have not been shown to improve the Danish model path, and
    /// example leakage is more damaging than a marginal prompt hint.
    static let danish = LanguagePromptGuidance(
        fillerExamples: #": remove pure hesitation sounds such as "øh", "øhm", and "æh". Treat "altså", "ligesom", "sådan", "jo", "nå", "ikke", "okay", "hm/hmm", and "mm/mhm" as fillers ONLY when context proves they are throwaway; they often carry meaning in Danish, so keep them when in doubt"#,
        capitalizationRule: """
        Fix Danish capitalization: capitalize the first word of a sentence and \
        proper names, but normally keep common nouns, titles, languages, \
        nationalities, weekdays, months, and holidays lowercase. Distinguish the \
        capital pronoun "I" (plural "you") from the very common lowercase \
        preposition "i" ("in") by context; never capitalize every standalone i.
        """,
        codeRendering: """
        When the surrounding Danish words clearly describe code, a file name, an \
        email address, a symbol, or an identifier, render the dictated notation \
        compactly and leave ordinary prose alone:
        - File names: "main punktum py" → main.py, "config punktum json" → \
        config.json. "punkt", "prik", and "punktum" stay words outside an \
        unmistakable technical pattern.
        - Identifiers: "bruger understregning id" or "bruger underscore id" → \
        bruger_id. Consume the joiner; never write bruger_understregning_id.
        - Email: "anna punktum hansen snabel-a eksempel punktum dk" → \
        anna.hansen@eksempel.dk.
        - Spoken Danish symbol commands include "startparentes"/"slutparentes", \
        "kantet startparentes"/"kantet slutparentes", "bindestreg", \
        "skråstreg", "omvendt skråstreg", "lighedstegn", "plustegn", \
        "minustegn", "procenttegn", "snabel-a"/"@-tegn", and "lodret streg".
        - Preserve exact spelling and casing of existing identifiers, paths, \
        brands, English technical terms, and file extensions. Join only what \
        the speaker explicitly marks as code.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Expect Danish around literal \
        commands, flags, paths, and identifiers:
        - "bindestreg bindestreg verbose" → --verbose; "bindestreg v" → -v.
        - "tilde skråstreg projekter" → ~/projekter; "punktum skråstreg build" \
        → ./build; "src skråstreg main" → src/main.
        - Keep commands, flags, paths, environment variables, and identifiers \
        exactly cased and spaced. Never capitalize a command or add a final \
        period. Do not translate command names or English technical tokens.
        - If the dictated content is clearly prose for a commit message, keep \
        normal Danish orthography without turning its words into shell syntax.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor, where file names, symbols, \
        identifiers, and embedded English technical vocabulary are especially \
        likely. Prefer compact code rendering only when explicit Danish symbol \
        words or the surrounding syntax support it. Keep Danish comments and \
        documentation as normal prose, and preserve existing code casing.
        """,
        selfCorrectionRule: """
        Resolve Danish self-corrections only when the speaker clearly replaces \
        an earlier attempt with a later one. Keep the LAST version: "fem, nej \
        seks kopier" → "seks kopier"; "onsdag, nej vent, torsdag" → "torsdag". \
        Markers such as "nej", "nej vent", "eller rettere", and "jeg mener" are \
        ordinary content in other contexts, so do not remove them unless they \
        actually introduce a correction.
        """,
        addendum: """
        - Use Danish punctuation spacing: no space before comma, period, colon, \
        semicolon, question mark, or exclamation mark; normally one space after.
        - Preserve Danish number notation: decimal comma (3,14), grouping point \
        where supplied (1.234,56), dates such as 26.7.2026, and times such as \
        kl. 14.30. In running prose prefer a space in "25 %" and "100 kr."; do \
        not convert dots in versions, IP addresses, paths, or source code.
        - Danish compounds are normally one word when pronounced as one \
        compound. Rejoin an obvious ASR split such as "stemme genkendelse" → \
        "stemmegenkendelse" only when the compound is certain; never guess \
        across a real phrase boundary.
        - Keep Danish quotation marks consistent (for example “…” or »…«) with \
        no spaces inside. Do not introduce an English apostrophe before an \
        ordinary Danish genitive s: "Peters", not "Peter's". Words ending in \
        s, x, or z and abbreviations follow Danish apostrophe rules.
        - Keep embedded English, product names, file names, and identifiers in \
        their original language. Never translate them or Danish prose.
        """)
}
