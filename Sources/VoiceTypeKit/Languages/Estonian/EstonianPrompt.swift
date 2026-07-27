import Foundation

extension LanguagePromptGuidance {
    /// Estonian-specific substance for the shared cleanup contract.
    ///
    /// No few-shot examples ship: this task intentionally does not run the
    /// single shared on-device model, so there is no evidence that examples
    /// outweigh their known leakage risk.
    static let estonian = LanguagePromptGuidance(
        fillerExamples: #": Estonian hesitation sounds such as "õõ"; remove "aa", "ää", "ee", "mm", "noh", "nagu", "nii", "siis", "see", "tähendab", or "tegelikult" ONLY when context makes them a throwaway hesitation"#,
        capitalizationRule: """
        Fix Estonian capitalization: capitalize sentence starts and proper \
        names, but keep ordinary nouns, job titles, weekdays, and month names \
        lowercase unless they belong to an official proper name. Preserve the \
        established case of brands, file names, commands, and identifiers.
        """,
        codeRendering: """
        When Estonian wording clearly dictates a file name, email address, \
        symbol, or identifier, render it compactly and leave ordinary prose \
        alone:
        - "main punkt py" → main.py; "config punkt json" → config.json. Consume \
        the spoken `punkt` only before a known extension.
        - "kasutaja alakriips id" → kasutaja_id; "ava sulg x koma y sulge sulg" \
        → (x,y); "mari punkt tamm ätt gmail punkt com" → \
        mari.tamm@gmail.com.
        - `alakriips`, `kaldkriips`, `sidekriips`/`kriips`, `tilde`, `ätt`, \
        `ava`, and `sulge` are rendering instructions only when the technical \
        context is clear. Consume the instruction word; never write it into \
        the identifier.
        - Keep dictated English API names, commands, extensions, and existing \
        identifiers in their exact spelling and case. Never translate them or \
        add Estonian inflection inside the identifier.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Expect English shell vocabulary \
        inside Estonian speech:
        - "kriips kriips verbose" → --verbose, "kriips v" → -v, "tilde \
        kaldkriips projektid" → ~/projektid, and "punkt kaldkriips build" → \
        ./build.
        - Preserve command, flag, path, branch, environment-variable, and file \
        name spelling exactly. Keep commands lowercase and do not translate \
        English tokens such as git, status, checkout, npm, swift, or build.
        - Never capitalize a command or append sentence punctuation to a shell \
        command. Estonian prose used as a commit message still follows normal \
        sentence rules.
        """,
        codeEditorGuidance: """
        The user is dictating in a code editor. Prefer compact symbol and \
        identifier rendering only when Estonian trigger words or surrounding \
        code make that intent clear. Keep source code, API names, file names, \
        and English identifiers exact; Estonian comments and documentation \
        remain normal Estonian prose.
        """,
        selfCorrectionRule: """
        Resolve Estonian self-corrections only when a phrase is clearly \
        retracted by `ei`, `ei, hoopis`, `õigemini`, `vabandust`, or \
        `tegelikult`: "kohtume teisipäeval, ei, kolmapäeval" → "kohtume \
        kolmapäeval". Keep only the version spoken last. Do not remove ordinary \
        negation `ei`, or lexical/contrastive uses of `tegelikult`; when the \
        correction is uncertain, preserve all words.
        """,
        addendum: """
        - Use Estonian quotation marks „…“. Write decimal fractions with a \
        comma (3,14), group long integers with spaces (10 000), write fully \
        numeric dates as 24.01.2017, and keep either the Estonian 10.30 or \
        international 10:30 time style when spoken. Put the euro sign after \
        the amount with a space (3,50 €), but attach percent signs (9%).
        - Use common Estonian abbreviations as established: lowercase \
        abbreviations normally have no final period (`nt`, `jne`), while \
        distinguishing internal periods remain in forms such as `v.a` and \
        `s.o`. Do not expand an abbreviation the speaker dictated.
        - Preserve Estonian letters õ, ä, ö, ü, š, and ž. Preserve apostrophes \
        in foreign names and forms, and do not alter punctuation inside file \
        names, URLs, email addresses, versions, or identifiers.
        - Estonian ASR often splits compound words, substitutes an inflectional \
        suffix, or misspells a foreign proper name. Join an obvious established \
        compound or repair a suffix only when grammar and meaning make the \
        intended form certain. Preserve uncertain wording and foreign names \
        rather than guessing.
        - `öö` is a real word form, and `aa`, `ää`, `ee`, `mm`, `noh`, `nagu`, \
        `nii`, `siis`, `see`, `tähendab`, and `tegelikult` can all carry \
        meaning. Remove one only when it is unmistakably a disfluency; when in \
        doubt, keep it.
        - Questions may begin with `kas`, `ega`, an interrogative word, or a \
        verb, and colloquial questions may end in `või`. Add `?` only when the \
        whole sentence is actually a direct question; an embedded indirect \
        question remains part of its surrounding statement.
        """)
}
