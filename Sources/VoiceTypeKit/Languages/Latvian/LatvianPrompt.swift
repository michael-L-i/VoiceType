import Foundation

extension LanguagePromptGuidance {
    /// Latvian-specific substance for the shared English instruction frame.
    /// Few-shot examples stay empty: this pack has not run the model eval, and
    /// example leakage is a demonstrated failure mode.
    static let latvian = LanguagePromptGuidance(
        fillerExamples: """
        : non-lexical Latvian hesitation sounds such as "ē", "ēē", "emm", and \
        "hmm". Words such as "nu", "tā", "tā kā", "tipa", "respektīvi", and \
        "zini" are ambiguous: remove them only when context makes them a pure \
        hesitation; keep them whenever they contribute meaning
        """,
        capitalizationRule: """
        Fix Latvian capitalization: capitalize the first word of each sentence \
        and genuine proper names, but do not title-case ordinary words. Weekday \
        and month names, language names, and nationality names normally remain \
        lowercase. Preserve the established casing of acronyms, brands, file \
        names, and identifiers
        """,
        codeRendering: """
        When context clearly shows Latvian code, a file name, an identifier, or \
        an email address, consume the spoken symbol names and render compact \
        ASCII:
        - "config punkts json" → config.json; "main punkts py" → main.py.
        - "max pasvītra retries" → max_retries; "atverošā iekava" / \
        "aizverošā iekava" → ( ); "komats" inside them → ,.
        - In an email address, "et" → @ and "punkts" → ., for example \
        "janis punkts berzins et example punkts lv" → \
        janis.berzins@example.lv.
        - Consume "punkts", "pasvītra", "defise", "slīpsvītra", "tilde", and \
        "et" only in clear technical context. They remain ordinary Latvian \
        words elsewhere; never turn "svarīgs punkts" into "svarīgs.".
        - Keep embedded English technical terms and exact identifier casing; \
        do not translate, inflect, or add Latvian diacritics inside code tokens.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Render Latvian-spoken shell \
        syntax exactly: "defise defise verbose" → --verbose, "defise v" → -v, \
        "tilde slīpsvītra projekti" → ~/projekti, and "punkts slīpsvītra build" \
        → ./build. Keep command names, flags, paths, environment variables, and \
        git/tmux vocabulary exactly cased; do not capitalize the command or add \
        a final period. Prose such as a commit message still follows Latvian \
        punctuation when it is clearly prose.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Prefer compact rendering for \
        explicitly spoken identifiers, file names, parentheses, and symbols. \
        Preserve ASCII code and embedded English API names exactly; do not \
        translate or Latvian-inflect them. Comments, documentation, and commit \
        text remain normal Latvian prose.
        """,
        selfCorrectionRule: """
        Resolve Latvian self-corrections only when the repair is explicit: keep \
        the replacement spoken last and remove the abandoned wording, for \
        example "piecas, nē, sešas kopijas" → "sešas kopijas". A standalone \
        "nē" is a meaningful answer, not a correction, and must stay
        """,
        addendum: """
        - Use Latvian typography: decimal comma (12,5), spaces for grouped \
        thousands (1 250 000), low-high quotation marks („…”), and no space \
        before , . ; : ! or ?.
        - In prose dates use ordinal periods and spaces, for example \
        "2026. gada 26. jūlijā"; write clock time as "plkst. 18.00". Keep ISO \
        dates, software versions, IP addresses, and existing technical formats \
        unchanged.
        - Put currency codes and symbols after the amount with a non-breaking \
        space (25 EUR, 10 €), and likewise keep a non-breaking space before %.
        - Preserve Latvian letters ā, č, ē, ģ, ī, ķ, ļ, ņ, š, ū, and ž when \
        they are present. Do not guess a different inflectional ending or \
        restore a missing diacritic unless the intended word is unambiguous in \
        context; those changes can alter meaning.
        - Latvian does not use apostrophes for ordinary elision. Leave \
        apostrophes in foreign names, quotations, and code untouched.
        """)
}
