import Foundation

extension LanguagePromptGuidance {
    /// Portuguese's contribution to the cleanup instruction. The frame stays
    /// English (the small on-device model follows English instructions more
    /// reliably); what is Portuguese is the substance.
    ///
    /// The division of labour with `LanguagePack.portuguese` is deliberate:
    /// anything a regex can be *right* about — decimal comma, ordinal
    /// indicators, sentence-final "quê", lowercase months, spoken bracket
    /// names — is deterministic and is not repeated here. What is left is
    /// everything that needs to know what a word *means*: which discourse
    /// markers are hesitation this time, which homophone the speaker meant,
    /// where a crase or an enclitic hyphen belongs.
    ///
    /// `fewShot` is deliberately empty. The eval battery for this language runs
    /// the deterministic engine only, and the house rule is that a pack ships
    /// examples only once its own model-engine battery shows they earn their
    /// place — the model has been observed echoing example content into
    /// unrelated output.
    static let portuguese = LanguagePromptGuidance(
        fillerExamples: #": "hum", "ãh", "ahn", "éé", and a throwaway "né" / "tipo" / "então" / "aí" / "assim" / "sabe" / "quer dizer" when it carries no meaning"#,
        capitalizationRule: """
        Fix capitalization: start every sentence with a capital letter and \
        capitalize proper nouns (people, cities, countries, companies). \
        Portuguese writes days of the week, months, seasons, languages and \
        nationalities in LOWERCASE — "segunda-feira", "março", "verão", \
        "português", "brasileiro" — and never capitalizes "eu" mid-sentence. \
        Restore the accents the transcriber dropped (ç, ã, õ, á, é, í, ó, ú, â, \
        ê, ô, à).
        """,
        codeRendering: """
        When the surrounding words make it clear the speaker is dictating code — \
        a file name, a symbol, an identifier, or a username/handle — render it \
        compactly instead of as separate words, and leave ordinary prose alone:
        - File names → paths: "app ponto py" → app.py. Pick the extension from \
        context (.py, .js, .ts, .rs, .go, .swift); ".py" read aloud in \
        Portuguese sounds like "pai" or "pi".
        - Spoken symbols → characters: "ponto" → ., "vírgula" → ,, \
        "underline"/"sublinhado" → _, "traço"/"hífen" → -, "barra" → /, \
        "barra invertida" → \\, "til" → ~, "arroba" → @, "dois pontos" → :, \
        "igual" → =, "abre/fecha parênteses" → ( ), "abre/fecha colchetes" → \
        [ ], "abre/fecha chaves" → { }.
        - Identifiers and handles join up: "max underline retries" → \
        max_retries, "camel case parse request" → parseRequest, "michael traço \
        L traço i" → michael-L-i (join with hyphens; keep handles lowercase \
        unless a letter is spoken on its own).
        - The trigger word is consumed, never kept: "max underline retries" → \
        max_retries, never max_underline_retries. And never join words the \
        speaker did not mark: "o token de sessão" stays four separate words.
        - A trigger word inside ordinary prose stays prose: "o ponto de vista", \
        "o ponto de ônibus", "chegou em ponto", "a barra do bar" and "traço de \
        personalidade" are NOT symbols. "três vírgula catorze" is the number \
        3,14, not a comma.
        """,
        terminalGuidance: """
        The user is dictating into a terminal, so expect shell commands, flags, \
        paths and git/tmux vocabulary alongside ordinary sentences:
        - Render spoken flags and paths: "traço traço verbose" → --verbose, \
        "traço v" → -v, "til barra projetos" → ~/projetos, "ponto barra build" \
        → ./build.
        - Command lines stay exactly as commands are spelled: lowercase, in \
        English, unaccented (git status, ls, tmux attach, cd Documentos). Never \
        capitalize the first word of a command, never add accents to it, and \
        never add a trailing period.
        - A dictated sentence that is clearly prose (a commit message, a chat \
        reply) still gets normal Portuguese punctuation, accents and \
        capitalization.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. When the words suggest code, \
        lean toward the compact rendering above — identifiers, file names and \
        symbols are more likely here than in ordinary writing, and identifiers \
        are almost always unaccented English. Prose (comments, commit messages, \
        documentation) still reads as normal Portuguese sentences, with accents.
        """,
        selfCorrectionRule: """
        Resolve self-corrections: when the speaker changes their mind \
        mid-sentence — usually marked by "não", "quer dizer", "ou melhor", \
        "digo", "aliás", "desculpa", "na verdade" — keep only the corrected \
        version, the one spoken LAST, and drop both the earlier attempt and the \
        marker: "cinco, não, seis cópias" → "seis cópias", never "cinco cópias".
        """,
        addendum: """
        - The dictation is Portuguese. Use ordinary Latin punctuation: NO \
        opening ¿ or ¡ (that is Spanish), no space before ; : ! ?, and curly \
        double quotes “…” around quoted speech.
        - Numbers follow Portuguese convention: the decimal separator is a \
        comma ("três vírgula catorze" → 3,14) — never turn it into a point — \
        and a currency symbol is separated from the amount by a space (R$ 1.200, \
        250 €). Ordinals are written 1º / 2ª. Write the time as 14h30.
        - Pick the right homophone from context, because the transcriber cannot: \
        "há" (verb, time elapsed) vs "a" (preposition); "mas" (but) vs "mais" \
        (more); "mal" vs "mau"; "a gente" (we) vs "agente"; "de repente", "com \
        certeza" and "por isso" are each two words. Use the crase "à/às" before \
        a feminine noun or a time ("vou à praia", "das 9 às 18").
        - Distinguish the four "porquês": "porque" (because, an answer), "por \
        que" (why, opening a question), "por quê" (why, ending a sentence), \
        "porquê" (the noun, after an article).
        - Restore the hyphen in enclitic pronouns when the speaker clearly used \
        one: "diga me" → "diga-me", "vou fazê lo" → "vou fazê-lo". Do not add a \
        hyphen anywhere the pronoun comes first ("me diga" stays).
        - "né", "tipo", "aí", "então", "assim", "sabe", "olha" are only \
        sometimes hesitation. Drop one when it carries no meaning; keep it when \
        it does ("aí" = there/then, "então" = so/therefore, "tipo" = kind of, \
        "sabe" = knows, "olha" = look). When in doubt, keep it.
        - Keep English technical words exactly as spoken and unaccented \
        (deploy, commit, branch, build, deadline, sprint). Never translate them, \
        and never translate the dictation itself.
        """)
}
