import Foundation

extension LanguagePromptGuidance {
    /// Maltese-specific substance for the shared English instruction frame.
    /// No few-shot pairs ship: this guidance has not been evaluated against
    /// the single shared on-device model, so examples would add leakage risk.
    static let maltese = LanguagePromptGuidance(
        fillerExamples: #": “ee”, “em”, “emm”, “mm”, and “qq” only when they are hesitation sounds. Keep “eħe” and “mhm” when they answer or confirm. Never delete “mela”, “allura”, “jiġifieri”, “taf”, “sewwa”, or “tajjeb” merely because they can be discourse markers; they often carry meaning"#,
        capitalizationRule: """
        Fix Maltese capitalization: capitalize the first word of each sentence \
        and proper names, but not ordinary common nouns. Preserve Maltese \
        titlecase — write Għ and Ie at the start of an ordinary capitalized \
        word, not GĦ or IE unless the whole word is in capitals. Capitalize \
        Maltese month names and the official weekday forms with their article \
        (It-Tnejn, It-Tlieta, L-Erbgħa, Il-Ħamis, Il-Ġimgħa, Is-Sibt, Il-Ħadd).
        """,
        codeRendering: """
        Maltese technical dictation commonly keeps English code words. Render \
        an explicit file name, identifier, email address, or symbol compactly, \
        while leaving ordinary Maltese prose alone:
        - “main punt py” or “main dot py” → main.py; a bare “punt” in prose \
        stays a word because it can mean a point, score, or decimal point.
        - “max underscore retries” → max_retries; “michael sing l sing i” → \
        michael-l-i. Consume the spoken trigger instead of retaining its name.
        - “iftaħ parentesi x virgola y agħlaq parentesi” → (x, y). Maltese \
        speakers may also use open/close, paren, bracket, comma, and at.
        - Keep established English identifiers, file extensions, product names, \
        and code exactly in ASCII. Do not translate them or respell them \
        phonetically as Maltese.
        - Never compact words that were not explicitly joined by a spoken \
        symbol. In ordinary prose, “il-punt ewlieni” remains ordinary words.
        """,
        terminalGuidance: """
        The user is dictating a shell command, usually with English command \
        names inside Maltese speech:
        - “sing sing verbose” or “dash dash verbose” → --verbose; “sing v” → \
        -v. “tilde slash projects” → ~/projects and “punt slash build” → \
        ./build.
        - Keep commands, flags, paths, environment-variable names, and file \
        names exactly cased and compact. Do not add Maltese articles, smart \
        punctuation, capitalization, or a final period to a command.
        - If the dictated text is clearly prose such as a commit message, clean \
        it as Maltese prose without translating embedded technical terms.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Prefer compact rendering only \
        when explicit Maltese or English symbol words mark code. Preserve \
        existing identifiers and string contents exactly; prose in comments or \
        documentation still follows Maltese orthography.
        """,
        selfCorrectionRule: """
        Resolve only clear Maltese self-corrections: when “le”, “mhux”, \
        “stenna”, “anzi”, or “skużi” immediately retracts an earlier attempt, \
        keep the corrected version spoken last — “ħames, le sitt kopji” becomes \
        “sitt kopji”. Otherwise those words keep their ordinary meaning.
        """,
        addendum: """
        - Use the Maltese letters ċ, ġ, għ, ħ, and ż where they are already \
        established by the transcript and preserve final grave accents (à, è, \
        ì, ò, ù). Do not guess lexical repairs for silent għ/h, aspirated stops, \
        or ambiguous verb boundaries.
        - Use the apostrophe ’ for genuine omission or contraction (ta’, ma’, \
        f’April, x’taħseb), never a grave accent, and retain the hyphen in the \
        Maltese article (il-ktieb, it-tifel, l-iskola).
        - Maltese prose uses “…” for quotations and „…‟ for a quotation nested \
        inside one. Put no space before , . ; : ! or ?, and one normal space \
        after it, except inside numbers, times, paths, and identifiers.
        - Write decimals with a full stop and thousands with a comma \
        (12,345.67). Write currency without a space (€543.21 or EUR543.21). \
        Dates are day–month–year: 2 ta’ Diċembru 2002 or 02/12/2002; times use \
        a colon, such as 14:30.
        - Preserve code-switched English words and technical identifiers in \
        their original spelling. Never translate a Maltese transcript or \
        respell an English identifier phonetically.
        """)
}
