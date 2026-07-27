import Foundation

extension LanguagePromptGuidance {
    /// Croatian-specific substance for the shared, English-language cleanup
    /// frame. No few-shot pairs ship: the Croatian rules battery validates the
    /// deterministic floor, but there is no model run proving examples help
    /// more than they leak.
    static let croatian = LanguagePromptGuidance(
        fillerExamples: #": non-lexical "eee", "mmm", "uh", "uhm", "hm"; and "ovaj", "onaj", "ono", "znači", "dakle", "pa", "mislim", or "zapravo" ONLY when context makes them empty hesitation"#,
        capitalizationRule: """
        Fix Croatian capitalization: capitalize the first word of each sentence \
        and genuine proper names. Keep days, months, language names, nationality \
        adjectives, and ordinary titles lowercase (ponedjeljak, srpanj, hrvatski, \
        profesor). In a multi-word Croatian name, capitalize only the first word \
        plus any component that is independently a proper name; never English-style \
        Title Case every word.
        """,
        codeRendering: """
        Croatian speakers often mix Croatian symbol names with English code. Only \
        compact a phrase when explicit symbol words or the code context make the \
        intent clear; never translate, inflect, or respell code tokens:
        - "main točka pi" → main.py, "config točka json" → config.json, and \
        "test donja crta client točka pi" → test_client.py.
        - "donja crta" / "underscore" → _, "crtica" / "spojnica" → -, "kosa \
        crta" → /, "tilda" → ~, "afna" / "znak at" → @.
        - "otvori oblu zagradu" / "zatvori oblu zagradu" → ( ), and the \
        corresponding "uglatu zagradu" phrases → [ ].
        - Preserve embedded English identifiers, APIs, case, extensions, URLs, \
        email addresses and product names exactly. Consume a symbol phrase only \
        as a symbol; ordinary Croatian prose such as "ključna točka projekta" \
        must remain words.
        """,
        terminalGuidance: """
        The user is dictating a shell command. Keep command names, flags, paths, \
        environment variables and arguments in their exact ASCII spelling and \
        never translate or Croatian-inflect them. Render "crtica crtica verbose" \
        as --verbose, "crtica v" as -v, "tilda kosa crta projekti" as ~/projekti, \
        and "točka kosa crta build" as ./build. A command stays lowercase and \
        receives no sentence-final punctuation; genuine prose dictated into the \
        terminal still follows Croatian orthography.
        """,
        codeEditorGuidance: """
        In a code editor, prefer compact rendering for explicitly dictated file \
        names, identifiers, brackets and symbols. Croatian prose in comments and \
        documentation remains normal prose. Preserve English technical vocabulary \
        and exact identifier casing; do not translate an API name or invent a \
        symbol the speaker did not dictate.
        """,
        selfCorrectionRule: """
        Resolve an unmistakable Croatian self-correction by keeping the replacement \
        spoken last: "u petak, ne, u subotu" becomes "u subotu". Treat "ne", \
        "zapravo", "čekaj", "odnosno" and "mislim" as correction markers only when \
        the surrounding phrase clearly retracts an earlier attempt; otherwise they \
        carry meaning and must stay.
        """,
        addendum: """
        - Use Croatian punctuation and typography: no space before . , ; : ? !, \
        one space after them in running text, Croatian quotation marks „…” (or \
        the already-used »…«), a decimal comma with no internal space, and a \
        space between a number and %, ‰, a measurement unit, or a currency sign.
        - Numeric dates use ordinal dots and spaces (24. 12. 2026.); do not \
        reinterpret version numbers, paths, IP addresses, identifiers or code as \
        dates. Preserve an already valid thousands grouping such as 10 000 or, \
        in financial text, 10.000.
        - Preserve Croatian letters č, ć, dž, đ, š and ž. In a clear direct \
        question distinguish "je li" from the past-tense word "jeli" and from \
        "jer", but never guess when context is ambiguous.
        - Preserve dialect, informal register, names and the speaker's chosen \
        Croatian/Bosnian/Serbian lexical form. Do not standardize or translate \
        content under the guise of cleanup.
        """)
}
