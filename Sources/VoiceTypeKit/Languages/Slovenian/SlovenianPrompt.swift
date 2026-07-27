import Foundation

extension LanguagePromptGuidance {
    static let slovenian = LanguagePromptGuidance(
        fillerExamples: #": non-lexical "eee"; remove "hm", "mhm", "no", "pa", "torej", "mislim", "pravzaprav", or "v bistvu" only when context proves they are throwaway hesitation or planning language, never when they contribute agreement, contrast, emphasis, or meaning"#,
        capitalizationRule: """
        Fix Slovenian capitalization: capitalize sentence beginnings and proper \
        names, while keeping common nouns, titles, languages, nationalities, \
        holidays, weekdays, and months lowercase unless they begin a sentence. \
        Preserve the official casing of brands and the exact casing of file \
        names, commands, paths, and identifiers.
        """,
        codeRendering: """
        When the surrounding words clearly indicate code, a file name, an email \
        address, or an identifier, render Slovenian spoken symbol names compactly \
        and leave ordinary prose alone:
        - "main pika swift" → main.swift; "config pika json" → config.json. \
        Consume `pika` only for a known extension, domain, or path — the ordinary \
        noun `pika` remains a word.
        - "uporabnik podčrtaj id" → uporabnik_id; "ime pika priimek afna primer \
        pika si" → ime.priimek@primer.si.
        - "odpri oklepaj x vejica y zapri oklepaj" → (x, y); `oglati oklepaj` \
        renders [ ], and `zaviti oklepaj` renders { }.
        - Keep English technical spellings and exact letter case when spoken. \
        Never translate commands, API names, file extensions, identifiers, or \
        code tokens into Slovenian.
        - A symbol word in ordinary prose stays prose. Join only the words the \
        speaker explicitly marks; never invent snake_case or camelCase.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Expect English command names and \
        flags inside Slovenian speech:
        - "vezaj vezaj verbose" → --verbose, "vezaj m" → -m, "tilda poševnica \
        projekti" → ~/projekti, and "pika poševnica build" → ./build.
        - Preserve command, flag, path, environment-variable, branch, and file \
        spelling exactly. Do not translate or inflect them, do not capitalize \
        the command, and do not add sentence punctuation to a command line.
        - If the dictated content is clearly prose (for example a commit message), \
        clean it as Slovenian prose while leaving embedded code tokens exact.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Prefer compact symbol, file, and \
        identifier rendering only where explicit Slovenian trigger words mark it. \
        Preserve English code tokens and exact identifier casing. Comments and \
        documentation remain natural Slovenian prose, including deliberate \
        colloquial wording.
        """,
        selfCorrectionRule: """
        Resolve Slovenian self-corrections by keeping only the replacement spoken \
        last: "v petek, ne, v soboto popoldne" → "v soboto popoldne". Treat `ne`, \
        `oziroma`, `pravzaprav`, and `mislim` as correction markers only when the \
        speaker clearly retracts an earlier word or phrase; otherwise keep them.
        """,
        // No few-shot examples: they have not been shown to beat the leakage
        // risk for Slovenian, and model eval is intentionally not run while the
        // shared on-device model is in use by parallel language work.
        fewShot: [],
        terminalFewShot: [],
        addendum: """
        - Use Slovenian typography: »…« for ordinary computer-set quotations; \
        no space before . , : ; ! or ?; a space after them where another word \
        follows; and three dots / an ellipsis for an unfinished sentence.
        - Use a decimal comma (3,14). Separate thousands with a dot or a \
        non-breaking space (41.000 or 41 000). Write dates with spaces \
        (1. 5. 2026), time-of-day with a dot (ob 8.30), and a space before %, \
        ‰, €, EUR, and units (5 %, 20 €, 30 kg, 18 °C).
        - Preserve Slovenian č, š, and ž; grammatical case, number, and especially \
        the dual. Do not standardize dialect or colloquial word choices, and do \
        not change a name or technical token merely because it resembles a typo.
        """)
}
