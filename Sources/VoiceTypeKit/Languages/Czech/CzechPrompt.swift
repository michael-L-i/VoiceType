import Foundation

extension LanguagePromptGuidance {
    /// Czech guidance for the on-device cleanup model.
    ///
    /// There are intentionally no few-shot examples. This pack is evaluated
    /// against the deterministic engine only because the shared on-device
    /// model is not parallel-safe; an unmeasured example is not worth the
    /// documented risk of example leakage.
    static let czech = LanguagePromptGuidance(
        fillerExamples: #": "eee", "ééé", "ehm", and a throwaway "no" / "jako" / "prostě" / "vlastně" / "tedy" / "takže" / "jakoby" / "víš" when it carries no meaning"#,
        capitalizationRule: """
        Fix capitalization according to Czech rules: start every sentence with \
        a capital letter and capitalize genuine proper names. In a multi-word \
        Czech proper name, normally capitalize only the first word and any \
        independently proper name inside it — do NOT apply English Title Case. \
        Keep weekdays, months, languages, and adjectives derived from places \
        lowercase (pondělí, červenec, čeština, český), while names of holidays \
        begin with a capital (Vánoce, Velikonoce). Preserve an intentional \
        respectful Vy/Váš in correspondence, but never invent it from ordinary \
        lowercase vy/váš.
        """,
        codeRendering: """
        When context shows that the speaker is dictating code, a file name, an \
        identifier, an e-mail address, or a handle, render Czech spoken symbol \
        names compactly and leave ordinary prose alone:
        - Symbols: "tečka" → ., "čárka" → ,, "dvojtečka" → :, \
        "středník" → ;, "podtržítko" → _, "pomlčka"/"spojovník" → -, \
        "lomítko" → /, "zpětné lomítko" → \\, "tilda" → ~, "zavináč" \
        → @, "otevřená závorka"/"uzavřená závorka" → ( ).
        - File names and paths join up: "main tečka py" or "main tečka pé \
        ypsilon" → main.py; "config tečka json" → config.json; "src lomítko \
        index tečka té es" → src/index.ts.
        - Identifiers and addresses join up: "max podtržítko retries" → \
        max_retries; "jan zavináč example tečka cé zet" → jan@example.cz. \
        Consume the spoken symbol name; never output max_podtržítko_retries.
        - Preserve the exact case and spelling of existing identifiers, \
        commands, API/library names, paths, extensions, and embedded English. \
        Never add Czech diacritics to code and never translate code tokens.
        - Do not render a punctuation noun in ordinary prose: "desetinná \
        čárka", "udělej za tím tečku", and "otazník nad termínem" remain \
        Czech words unless the context clearly makes them dictation commands.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Expect shell commands, English \
        command names, flags, paths, and Git vocabulary alongside Czech prose:
        - Render flags and paths: "pomlčka pomlčka verbose" → --verbose, \
        "mínus v" → -v, "tilda lomítko projekty" → ~/projekty, "tečka \
        lomítko build" → ./build.
        - Keep command lines byte-conscious: git status, ls, npm, tmux and flag \
        names remain lowercase and untranslated; do not add diacritics, \
        capitalize the command, or append sentence punctuation.
        - A clearly dictated prose string such as a commit message still uses \
        normal Czech spelling, but do not invent shell quoting the speaker did \
        not dictate.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Prefer compact rendering for \
        explicit symbol names, identifiers, file names, and paths. Preserve \
        English keywords, API/library names, identifiers, and their exact case; \
        never translate them or add Czech diacritics. Comments, documentation, \
        commit messages, and other prose still follow normal Czech orthography.
        """,
        selfCorrectionRule: """
        Resolve Czech self-corrections: when the speaker retracts an attempt \
        with "ne", "teda ne", "vlastně", "oprava", "promiň", "pardon", \
        "myslím" or "chci říct", keep only the corrected wording spoken LAST \
        and remove the abandoned wording plus the repair marker: "ve středu, \
        ne, ve čtvrtek odpoledne" → "ve čtvrtek odpoledne", never "ve \
        středu odpoledne". Keep "ne", "vlastně" and "myslím" when they carry \
        their ordinary meaning rather than marking a repair.
        """,
        addendum: """
        - Always use Czech punctuation and typography in Czech prose: primary \
        quotation marks are „…“ (nested ‚…‘), an ellipsis is the single mark \
        …, and there is no space before , . ; : ? !. Keep punctuation inside \
        embedded code, paths, URLs, e-mail addresses, and identifiers ASCII.
        - Czech decimals use a comma with no surrounding spaces (3,14). Group \
        thousands with spaces when the context unambiguously represents a \
        number, but never rewrite a year, version, IP address, date, port, or \
        identifier. Dates in running Czech text normally read 5. 6. 2026 or \
        5. června 2026; keep ISO 2026-06-05 in technical contexts.
        - Put a space between an amount or measured value and its symbol \
        (250 Kč, 12 %, 20 °C, 5 kg). Do not insert one when the tight form is \
        deliberately adjectival (12% roztok, 100Kč bankovka), and preserve \
        technical unit syntax.
        - Preserve Czech clitics without apostrophes: "žes", "tys", "bys". Use \
        the typographic apostrophe ’ only where it is genuinely present in a \
        foreign name/phrase or deliberate elision; never turn a straight quote \
        inside code into an apostrophe.
        - Czech ASR often has to choose between markedly different colloquial \
        and formal forms. Preserve the speaker's register and word choice; do \
        not silently formalize "bysme" to "bychom". Repair a homophone, missing \
        diacritic, or boundary only when Czech grammar and context make the \
        recognition error certain, and never make that repair inside a name, \
        quotation, or code token.
        - Remove eee/ééé/ehm hesitation sounds. Remove no, jako, prostě, \
        vlastně, tedy, takže, jakoby, víš, or řekněme ONLY when context makes \
        the expression empty. Keep hm/mhm/aha/jo when it conveys a response, \
        doubt, realization, or agreement. When in doubt, keep the word.
        """)
}
