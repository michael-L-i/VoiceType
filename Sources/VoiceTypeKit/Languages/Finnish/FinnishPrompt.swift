import Foundation

extension LanguagePromptGuidance {
    /// Finnish-specific guidance for the on-device cleanup model. Few-shot
    /// examples intentionally remain empty: without a parallel model eval,
    /// their leakage risk outweighs an unmeasured benefit.
    static let finnish = LanguagePromptGuidance(
        fillerExamples: #": nonlexical hesitation sounds such as "öö", "ööö", "ää", and "hmm". Treat "tota"/"tuota", "niinku"/"niin kuin", "siis", "no", and "mhm" as ambiguous: remove one only when it is clearly a throwaway hesitation, never when it contributes meaning, stance, or an answer"#,
        capitalizationRule: """
        Fix Finnish capitalization: capitalize sentence starts and proper \
        names, but keep ordinary nouns, weekdays, months, languages, \
        nationalities, currencies, and titles lowercase unless they begin a \
        sentence. Preserve the exact casing of brands, file names, identifiers, \
        commands, and other embedded technical text.
        """,
        codeRendering: """
        When context clearly shows that the speaker is dictating code, a file \
        name, an identifier, an email address, or a handle, interpret Finnish \
        symbol names compactly and leave ordinary Finnish prose untouched:
        - "main piste py" or an ASR homophone such as "main piste pyy" → main.py; \
        "max alaviiva yritykset" → max_yritykset.
        - "avaa kaarisulku x pilkku y sulje kaarisulku" → (x, y). Other explicit \
        names include hakasulku, kauttaviiva, tavuviiva/yhdysmerkki, tilde, and \
        ät/at-merkki.
        - Consume the spoken symbol name; never leave it inside the identifier. \
        Do not join neighboring words unless the speaker explicitly names the \
        separator.
        - Bare piste, pilkku, and viiva are also normal Finnish nouns. Render \
        them as symbols only when technical structure or an explicit dictation \
        command makes that reading clear.
        - Keep ASCII punctuation inside code, file names, versions, URLs, IP \
        addresses, and identifiers. Never translate identifiers or English \
        technical tokens.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Expect shell commands, flags, \
        paths, and English command vocabulary embedded in Finnish:
        - "viiva v" → -v, "viiva viiva verbose" → --verbose, "tilde \
        kauttaviiva projektit" → ~/projektit, and "piste kauttaviiva build" → \
        ./build.
        - Preserve command spelling and case exactly; never translate a command, \
        capitalize its first token, add Finnish number formatting, or append \
        sentence punctuation.
        - Finnish prose intentionally dictated as a commit message or other \
        argument still uses normal Finnish spelling, but do not invent shell \
        quoting that the speaker did not dictate.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Prefer compact rendering for \
        explicitly dictated identifiers, file names, and symbols, while keeping \
        code and English API names unchanged. Finnish comments, documentation, \
        and prose retain the speaker's register and normal Finnish orthography.
        """,
        selfCorrectionRule: """
        Resolve Finnish self-corrections introduced by "eiku", "ei kun", \
        "korjaan", or "tarkoitan": keep the corrected wording spoken LAST and \
        remove only the retracted attempt and repair marker — "kokous on \
        tiistaina, eiku keskiviikkona" becomes "kokous on keskiviikkona". Keep \
        the marker when it is quoted, ironic, turn-final, or otherwise \
        intentionally meaningful.
        """,
        addendum: """
        - Preserve the speaker's Finnish variety and wording. Do not standardize \
        colloquial or dialectal forms (for example, do not change "mä" to \
        "minä"), translate English technical terms, or guess at compounds, \
        inflection, names, or a one-letter ASR uncertainty.
        - In Finnish prose, use no space before , . ! ? ; or :, and one space \
        after them. Use Finnish paired quotation marks ”like this” and the \
        apostrophe ’ where Finnish orthography requires it. Keep ASCII quotes \
        and apostrophes in code and machine-readable text.
        - Use a decimal comma (3,14), spaces between digit groups (1 000 000), \
        day-month-year dates (26.7.2026), and a period in prose clock times \
        (klo 9.15). Put a space between a number and %, ‰, a unit, or a currency \
        symbol (29,90 €). Do not rewrite machine-oriented numbers such as \
        versions, file names, IP addresses, URLs, or command arguments.
        """)
}
