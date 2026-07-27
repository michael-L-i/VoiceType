import Foundation

extension LanguagePromptGuidance {
    /// Arabic-specific guidance for the on-device cleanup model. Few-shot
    /// examples are intentionally absent: the language eval has no model run,
    /// and an unproven example is more likely to leak than to help.
    static let arabic = LanguagePromptGuidance(
        fillerExamples: """
        : remove non-lexical hesitation sounds such as "إمم" and "ممم"; remove \
        "يعني", "آه", "طيب", "مثلاً", or "والله" ONLY when context makes it \
        unmistakably a throwaway hesitation, because each can carry meaning
        """,
        capitalizationRule: """
        Arabic has no uppercase or lowercase. Do not invent capitalization, \
        and preserve the exact case of embedded Latin names, file names, \
        commands, and identifiers
        """,
        codeRendering: """
        Arabic speakers often mix Arabic instructions with Latin code. Render \
        an explicitly dictated technical token compactly, but leave ordinary \
        Arabic prose alone:
        - Keep Latin identifiers, brands, extensions, URLs, and file names in \
        Latin script and preserve their case: "main دوت py" or "main نقطة py" \
        → main.py; never transliterate main.py into Arabic.
        - Render explicit joiners: "user أندرسكور id" or "user شرطة سفلية id" \
        → user_id; "src سلاش main" → src/main; "علامة آت" → @.
        - Render explicitly named delimiters and operators: "قوس مفتوح" / \
        "قوس مقفول" → ( / ), "علامة يساوي" → =, "فاصلة منقوطة" → ؛.
        - Consume the symbol words. Never output `main دوت py` or \
        `user_أندرسكور_id`.
        - Context is mandatory for ambiguous words: نقطة remains the ordinary \
        word "point" unless it sits between a file stem and a known extension; \
        شرطة remains "police" unless the speaker explicitly says علامة شرطة \
        or is clearly dictating a command flag.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Expect Arabic around exact Latin \
        commands, flags, and paths:
        - "داش داش verbose" or "علامة شرطة علامة شرطة verbose" → --verbose; \
        "داش m" → -m; "تيلدا سلاش projects" → ~/projects; "دوت سلاش build" \
        → ./build.
        - Preserve command spelling and case exactly. Do not translate `git \
        status`, flags, paths, environment variables, or identifiers into \
        Arabic, and do not add a final period to a command.
        - Arabic prose such as a commit message still uses normal Arabic \
        punctuation, but the shell syntax around it remains byte-for-byte safe.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Prefer compact code rendering \
        only when an explicit Arabic symbol name or surrounding syntax signals \
        code. Keep identifiers and APIs in Latin script with their original \
        case. Arabic comments and documentation remain natural Arabic prose.
        """,
        selfCorrectionRule: """
        Resolve only explicit Arabic self-corrections: keep the replacement \
        spoken LAST and remove the retracted attempt plus a marker such as \
        "لا، قصدي", "أقصد", "بل", or "عفوًا": "الاجتماع الثلاثاء، لا قصدي \
        الأربعاء" → "الاجتماع الأربعاء". When لا is ordinary negation, keep it
        """,
        addendum: """
        - Use Arabic punctuation in Arabic prose: comma `،` (U+060C), semicolon \
        `؛` (U+061B), and question mark `؟` (U+061F). A mark touches the word \
        before it and is followed by one space. The full stop `.`, colon `:`, \
        and exclamation mark `!` keep their ordinary shapes.
        - Arabic has multiple valid regional number practices. Preserve \
        Arabic-Indic versus European digits, decimal/group separators, date \
        order, currency notation, and abbreviations as supplied; never convert \
        them merely for visual uniformity.
        - Preserve the speaker's dialect. Do not "improve" dialectal Arabic \
        into Modern Standard Arabic, and do not translate embedded English or \
        French. Correct only an unmistakable transcription typo when context \
        leaves exactly one reading.
        - Preserve the input quotation/apostrophe style unless a spoken command \
        explicitly names a quote. Apostrophes inside Latin/French names and \
        code are data, not Arabic elision to rewrite.
        - Never insert RLM, LRM, ALM, embedding, override, or isolate controls. \
        Mixed-direction visual layout belongs to the receiving app; the pasted \
        text must contain only what the user dictated.
        """)
}
