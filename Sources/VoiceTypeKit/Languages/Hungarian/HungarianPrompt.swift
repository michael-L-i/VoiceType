import Foundation

extension LanguagePromptGuidance {
    /// Hungarian-specific substance for the shared cleanup contract.
    ///
    /// No few-shot examples ship: the Hungarian model path is deliberately not
    /// run during parallel language work, and unvalidated examples can leak
    /// their content into unrelated output.
    static let hungarian = LanguagePromptGuidance(
        fillerExamples: #": repeated hesitation sounds such as "öö", "ööö", "őő", "ööhm", "hmm"; and words such as "izé", "hát", "szóval", "ugye", "amúgy", or "tulajdonképpen" ONLY when context proves they are throwaway hesitation rather than meaning-bearing discourse"#,
        capitalizationRule: """
        Fix Hungarian capitalization: capitalize sentence starts and proper \
        names, but keep common nouns, adjectives, language and nationality \
        names, weekdays, and month names lowercase unless they begin a sentence. \
        Preserve the established case of acronyms, brands, file names, paths, \
        handles, and identifiers
        """,
        codeRendering: """
        When the surrounding Hungarian words make it clear that the speaker is \
        dictating code, a file name, an identifier, an email address, or a \
        handle, render it compactly and keep ordinary prose unchanged:
        - File names: "main pont pé ipszilon" → main.py, "config pont dzsézon" \
        → config.json, and "index pont jé es" → index.js. Hungarian letter \
        names after `pont` spell the ASCII extension; do not put accents into \
        file names unless the speaker explicitly includes them.
        - Symbols: "aláhúzásjel"/"alulvonás" → _, "kötőjel" → -, "perjel" → /, \
        "kukac" → @, "nyitó zárójel"/"záró zárójel" → ( ), and "vessző" → , \
        when they are clearly commands rather than words being discussed.
        - Join only explicitly marked identifiers: "max aláhúzásjel retries" → \
        max_retries. Consume the symbol word. Never join an unmarked Hungarian \
        phrase, and never translate or Magyarize an existing identifier.
        - Preserve English programming words, commands, API names, flags, \
        extensions, and their exact ASCII case. A Hungarian sentence around \
        `main.py`, `getUser`, or `VoiceType` remains Hungarian while those \
        tokens remain byte-for-byte technical text.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Treat Hungarian symbol names and \
        Hungarian letter names as shell syntax when the context is clear:
        - "kötőjel kötőjel verbose" → --verbose, "kötőjel em" → -m, "tilde \
        perjel projektek" → ~/projektek, and "pont perjel build" → ./build.
        - Keep command names, subcommands, flags, environment variables, paths, \
        and identifiers exactly as technical ASCII; never translate them, add \
        Hungarian accents to them, capitalize the command, or append sentence \
        punctuation.
        - If the terminal dictation is clearly prose (for example a commit \
        message), clean the Hungarian wording but do not invent shell quoting.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Prefer compact rendering for \
        explicitly dictated identifiers, file names, extensions, brackets, and \
        symbols. Keep code tokens in their original language and exact case; do \
        not add Hungarian accents or suffix spelling inside an identifier. \
        Hungarian comments, documentation, and commit prose still follow normal \
        Hungarian punctuation, accents, and capitalization.
        """,
        selfCorrectionRule: """
        Resolve Hungarian self-corrections only when the phrase clearly retracts \
        an earlier attempt: keep the version spoken LAST and remove the rejected \
        words, for example "öt, nem, hat példány" → "hat példány". Markers such \
        as "nem", "pontosabban", "illetve", "bocsánat", "úgy értem", or "vagyis \
        inkább" are not automatically removable; keep them when they function \
        as ordinary negation, contrast, or explanation
        """,
        fewShot: [],
        terminalFewShot: [],
        addendum: """
        - Use Hungarian orthography throughout and never translate the \
        dictation. Preserve ő/ű and all other accents in Hungarian words, but \
        do not guess a diacritic in a proper name or technical token when \
        context does not settle it.
        - Use Hungarian quotation marks „…” in prose (nested quotation: »…«). \
        Put no spaces just inside quotation marks or parentheses. Use three \
        dots/… for an unfinished thought, not a single period.
        - Numeric decimals use a comma with no surrounding spaces (3,14). Group \
        large numbers with spaces when grouping is needed. Put a space between \
        a number and a measurement or currency symbol/abbreviation (25 kg, \
        2500 Ft, 20 €), but no space before % (5%); attach a suffix to a symbol \
        or abbreviation with a hyphen (5%-os, Ft-tal).
        - Hungarian full dates run year–month–day: "2026. július 26." Month and \
        weekday names stay lowercase. Do not capitalize after a non-sentence \
        abbreviation such as "kb." or after the year period in a date.
        - Do not introduce apostrophes into Hungarian words. Preserve apostrophes \
        that genuinely belong to a foreign name, contraction, or code token.
        - `pont` and `vessző` are ambiguous ordinary words. Render them as \
        punctuation only when dictation or technical context makes that intent \
        clear. Likewise remove `hát`, `izé`, `szóval`, `ugye`, `amúgy`, or \
        `tulajdonképpen` only when it contributes no meaning; when in doubt, \
        keep it.
        - Infer questions from the whole Hungarian sentence. Yes/no questions \
        may have statement-like word order and no question particle; embedded \
        interrogative words do not necessarily make the whole sentence a \
        question.
        - Repair clearly dictated spacing and compound-word orthography, but \
        never replace a word, change an inflection, or fuse a plausible phrase \
        merely because another reading seems more common.
        """)
}
