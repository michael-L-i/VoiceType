import Foundation

extension LanguagePromptGuidance {
    /// Hindi-specific guidance for the on-device cleanup model. There are no
    /// few-shot examples: Hindi has not had a parallel model eval, and example
    /// leakage is a larger risk than any unmeasured benefit.
    static let hindi = LanguagePromptGuidance(
        fillerExamples: #": non-lexical pauses such as "उमम्", "उम्", "उम्म", and "उह"; and context-dependent "मतलब", "यानी", "तो", "अच्छा", "अरे", or "वो" ONLY when they are clearly throwaway hesitation rather than meaning"#,
        capitalizationRule: """
        Hindi in Devanagari has no uppercase or lowercase, so never invent \
        capitalization for Hindi text. Preserve the exact case of embedded \
        Latin code, identifiers, flags, paths, file names, URLs, and email \
        addresses; retain established casing for known Latin names and brands.
        """,
        codeRendering: """
        Hindi speakers commonly mix Devanagari prose with Latin code. When the \
        surrounding words clearly indicate a file name, identifier, symbol, \
        email address, or handle, render the technical part compactly and keep \
        ordinary Hindi prose unchanged:
        - "main डॉट पाई" → main.py, "config डॉट जेसन" → config.json, and \
        "utils डॉट टी एस" → utils.ts. Keep the file name and extension in \
        ASCII; consume the spoken trigger.
        - "max अंडरस्कोर retries" → max_retries. डैश/हाइफ़न → `-`, स्लैश → \
        `/`, खुला कोष्ठक/बंद कोष्ठक → `( )`, खुला ब्रैकेट/बंद ब्रैकेट → \
        `[ ]`, and कॉमा inside code → `,`.
        - Join only words the speaker explicitly connects. "session token" \
        stays two words; डॉट in ordinary prose stays a word unless the context \
        clearly calls for a literal symbol.
        - Preserve API names, commands, identifiers, and user-supplied case \
        exactly. Never translate them into Hindi or transliterate them into \
        Devanagari.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Hindi prose may surround shell \
        commands, but command names, flags, paths, and identifiers stay compact \
        ASCII and exactly cased:
        - "git commit डैश m संदेश" → git commit -m संदेश; "npm run build डैश \
        डैश verbose" → npm run build --verbose.
        - "cd टिल्ड स्लैश projects" → cd ~/projects; "डॉट स्लैश build" → \
        ./build. Consume डैश, स्लैश, डॉट, and टिल्ड when they are commands.
        - Never capitalize a command, translate a flag, add a danda/period to \
        a command line, or alter quoted arguments. Hindi commit messages and \
        other prose arguments remain Hindi.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor, where Hindi-English \
        code-switching is expected. Prefer compact ASCII for explicit code, \
        symbols, API names, identifiers, and file names; keep Hindi comments, \
        documentation, and prose as normal Hindi sentences with Hindi \
        punctuation. Do not rewrite string contents or guess a spelling for an \
        unfamiliar name.
        """,
        selfCorrectionRule: """
        Resolve only an explicit Hindi self-correction, keeping the replacement \
        spoken last: "बैठक बुधवार को—नहीं, गुरुवार को रखो" → "बैठक गुरुवार को \
        रखो". Markers can include "नहीं", "नहीं, मेरा मतलब", "रुकिए", or \
        "माफ़ कीजिए" when they clearly retract earlier words. Keep "नहीं" when \
        it is genuine negation and keep "मतलब" when it means "meaning"; when \
        uncertain, preserve both phrases.
        """,
        addendum: """
        - End an ordinary Hindi declarative sentence with the Devanagari danda \
        `।`; use `?` for a direct question and `!` for an exclamation. Put no \
        space before these marks and one space after a mark when another \
        sentence follows.
        - Use Hindi typographic quotation marks “…” and ‘…’ for quoted Hindi \
        prose, with no spaces just inside the marks. Keep ASCII quotes in code \
        and literal technical strings. Parentheses likewise have no inner \
        padding.
        - Preserve the speaker's number and digit choices. When the speaker \
        explicitly dictates a formatted Indian quantity, use period decimals \
        and Indian grouping (`12,34,567.89`); write rupee amounts as \
        `₹12,34,567.89`, percentages as `28%`, and numeric dates day-first \
        (`26/07/2026`). Never change a numeric value or infer a date/currency \
        conversion.
        - Hindi abbreviations may use the Devanagari abbreviation sign `॰`, \
        while embedded Latin abbreviations retain ASCII punctuation. An \
        apostrophe in Hindi marks omitted digits (for example `सन् ’47`), not \
        possession. Do not invent an abbreviation or elision.
        - Hindi ASR often splits or merges words, distorts number words, loses \
        optional diacritics/conjuncts, and transliterates English code into \
        Devanagari. Repair one of these only when the intended original is \
        unambiguous in context; never guess a proper name, number, command, or \
        identifier, and never translate Hindi-English code-switched speech.
        - मतलब, यानी, तो, अच्छा, अरे, बस, वो, हाँ, हम्म, ना, and नहीं can all \
        carry meaning. Remove one only when context proves it is a disposable \
        hesitation or an explicit repair marker; when in doubt, keep it.
        """)
}
