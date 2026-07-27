import Foundation

extension LanguagePromptGuidance {
    /// Slovak guidance for the on-device cleanup model.
    ///
    /// No few-shot examples ship here: Slovak has not had a parallel-safe model
    /// evaluation, and the model is known to echo examples into unrelated
    /// output. The instructions carry the language-specific behavior without
    /// giving it reusable transcript content.
    static let slovak = LanguagePromptGuidance(
        fillerExamples: #": Slovak non-lexical hesitations such as "ehm", "éé", and elongated "ééé"; remove "hm"/"mhm", "no", "teda", "vlastne", "proste", "akože", "oné", or "tento" ONLY when context makes them a throwaway hesitation, because each can express real meaning"#,
        capitalizationRule: """
        Fix Slovak capitalization: capitalize the first word of each sentence \
        and genuine proper names. Keep ordinary nouns, weekdays, months, \
        languages, and nationality adjectives lowercase unless they begin a \
        sentence or belong to an official proper name. Preserve respectful \
        Vy/Váš capitalization only when the speaker's direct-address register \
        calls for it; do not invent it in casual prose. Never change the case \
        of file names, paths, commands, identifiers, acronyms, or product names.
        """,
        codeRendering: """
        When context clearly shows that the speaker is dictating code, a file \
        name, an identifier, an email address, or a handle, interpret Slovak \
        symbol names compactly and leave ordinary prose alone:
        - "bodka" → `.`, "podčiarkovník" → `_`, "pomlčka"/"spojovník" → `-`, \
        "lomka" → `/`, "zavináč" → `@`, "otvorená zátvorka" → `(`, \
        "zatvorená zátvorka" → `)`, and "čiarka" → `,` inside a dictated pair.
        - Join known file extensions: "main bodka py" or "main bodka pé ypsilon" \
        → `main.py`; "config bodka json" → `config.json`. Keep ASCII dots in \
        file names and domains even though Slovak prose uses a decimal comma.
        - Consume spoken joiners: "max podčiarkovník retries" → `max_retries`, \
        never `max_podčiarkovník_retries`. Join only the words the speaker \
        explicitly connects, preserve their spelling and case, and never \
        translate an English identifier into Slovak or a Slovak one into English.
        - Render an address such as "jana bodka novakova zavináč example bodka sk" \
        as `jana.novakova@example.sk`.
        - In ordinary discussion the same words remain nouns: a sentence about \
        `bodka`, `čiarka`, `lomka`, or `pomlčka` must not turn into punctuation \
        unless the surrounding dictation clearly requests the symbol.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Prefer literal shell syntax and \
        exact command spelling:
        - "pomlčka pomlčka verbose" → `--verbose`, "pomlčka v" → `-v`, \
        "tilda lomka projekty" → `~/projekty`, "bodka lomka build" → `./build`, \
        and subsequent spoken "lomka" joins path components.
        - Keep command names, subcommands, flags, environment variables, paths, \
        and git/tmux vocabulary exactly as dictated. Do not translate them, \
        add Slovak diacritics to them, capitalize the first command token, or \
        append sentence punctuation.
        - If the terminal dictation is clearly Slovak prose, such as a commit \
        message, clean it as Slovak prose while preserving any embedded command \
        tokens byte-for-byte.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Bias explicit symbol names, \
        file extensions, and casing instructions toward compact code, while \
        preserving identifiers, APIs, keywords, paths, and string contents \
        exactly; never translate them or add Slovak diacritics. Interpret \
        "malé/veľké písmeno", "camel case", "snake case", and \
        "podčiarkovník" only when they clearly describe an identifier. Slovak \
        comments, documentation, commit messages, and other prose still follow \
        normal Slovak spelling and punctuation.
        """,
        selfCorrectionRule: """
        Resolve Slovak self-corrections only when the speaker clearly retracts \
        an earlier attempt with a correction marker such as "nie", "oprava", \
        "vlastne", "teda", or "respektíve": keep the corrected wording spoken \
        LAST and remove the retracted attempt and marker. For example, "päť, \
        nie, šesť položiek" becomes "šesť položiek". Those marker words can \
        carry ordinary meaning, so preserve them whenever the context is not \
        an unmistakable correction.
        """,
        addendum: """
        - Preserve Slovak words and every Slovak diacritic (á, ä, č, ď, dz, dž, \
        é, í, ľ, ĺ, ň, ó, ô, ŕ, š, ť, ú, ý, ž). Do not Czechify, translate, \
        modernize, or replace a speaker's chosen word.
        - Use Slovak quotation marks „…“ (nested ‚…‘), an en dash with spaces \
        for a parenthetical dash, no spaces around a hyphen or slash, and the \
        single ellipsis character … with no preceding space.
        - In prose, write decimal numbers with a comma (`3,14`), group \
        thousands with spaces (`12 500`), write numeric dates as `d. m. rrrr`, \
        and write clock times with a period (`9.30`). Keep version numbers, IP \
        addresses, URLs, file names, and code notation unchanged.
        - Put a nonbreaking space between a number and `%`, `€`, a currency \
        code, or a measurement unit: `20 %`, `50 EUR`, `9 °C`. Keep currency \
        after the amount unless the speaker explicitly chose another form.
        - Preserve established Slovak abbreviations and their periods (`napr.`, \
        `t. j.`, `tzv.`, `atď.`); an abbreviation period or ordinal period is \
        not a sentence boundary.
        """)
}
