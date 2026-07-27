import Foundation

extension LanguagePromptGuidance {
    /// Spanish's contribution to the on-device cleanup instruction.
    ///
    /// The division of labour with `SpanishOrthography` is deliberate: anything
    /// always-true in Spanish (the opening `¿`, symbol spacing, lowercase
    /// months) is a deterministic rule and is NOT repeated here — prompt
    /// content leaks, and the small model is unreliable at mechanical detail
    /// even when told twice. What is left for the model is exactly the work
    /// that needs meaning: deciding whether "este" was a hesitation or a
    /// demonstrative, and resolving a self-correction.
    ///
    /// No `fewShot` pairs. The eval battery for Spanish passes on rules alone,
    /// and the harness's standing lesson is that examples leak into unrelated
    /// output; a Spanish example would additionally invite the model to
    /// translate. Add them only if a model run shows they earn their place.
    static let spanish = LanguagePromptGuidance(
        fillerExamples: #": "eh", "em", "ehm", "mmm", and — only when they carry no meaning at all — "este", "esto", "o sea", "pues", "bueno", "digamos", "en plan", "tipo", "¿sabes?", "¿no?", "¿vale?". These last ones are real words far more often than they are hesitations: "este informe" is a demonstrative, "pues bien" is a connector, "bueno" can mean good, and "¿no?" can be a genuine question. Keep them whenever they mean something"#,
        capitalizationRule: """
        Fix capitalization the Spanish way: start every sentence with a capital \
        letter and capitalize proper nouns (people, places, brands), but keep \
        lowercase everything Spanish does not capitalize — days of the week \
        (lunes, martes), months (enero, marzo), seasons, languages and \
        nationalities (español, inglés, mexicano), religions, and job titles \
        (el presidente, la doctora). "yo" is never capitalized mid-sentence.
        """,
        codeRendering: """
        When the surrounding words make it clear the speaker is dictating code — \
        a file name, an identifier, a path, or an address — render it compactly \
        instead of as separate words, and leave ordinary prose alone:
        - Spoken symbols → characters: "punto" → ., "coma" → ,, "guion bajo" → \
        _, "guion" → -, "barra" → /, "virgulilla" → ~, "arroba" → @, "dos \
        puntos" → :, "punto y coma" → ;, "abrir paréntesis"/"cerrar paréntesis" \
        → ( ), "abrir corchete"/"cerrar corchete" → [ ], "asterisco" → *, \
        "almohadilla" → #, "igual" → =.
        - File names → paths: "main punto pi" → main.py, "índice punto jota \
        ese" → index.js, "configuración punto json" → config.json. The extension \
        is spoken in Spanish letter names or as an English word; resolve it to \
        the real extension.
        - Identifiers join up: "max guion bajo reintentos" → max_reintentos, \
        "camel case obtener usuario" → obtenerUsuario, "michael guion L guion \
        i" → michael-L-i.
        - The trigger word is consumed, never kept: "max guion bajo reintentos" \
        → max_reintentos, never max_guion_bajo_reintentos. Never join words the \
        speaker did not mark: "el token de sesión" stays three words.
        - A trigger word inside ordinary prose stays prose: "el punto de vista" \
        is NOT "el.vista", "un guion de cine" is a screenplay, and "hasta cierto \
        punto" is not a file name.
        - Keep identifiers, commands and file names in ASCII exactly as they are \
        spelled — never add Spanish accents to them, and never translate them.
        """,
        terminalGuidance: """
        The user is dictating into a terminal, so expect shell commands, flags, \
        paths and git/tmux vocabulary alongside ordinary sentences:
        - Render spoken flags and paths: "guion guion verbose" → --verbose, \
        "guion uve" / "guion v" → -v, "virgulilla barra proyectos" → \
        ~/proyectos, "punto barra build" → ./build, "punto punto barra" → ../.
        - Commands stay exactly as commands are spelled: lowercase, in English \
        (git status, ls, tmux attach), never translated into Spanish, never \
        capitalized, and never given a trailing period.
        - NEVER add ¿ ¡ ? or ! to a command line. A dictated sentence that is \
        clearly prose (a commit message, a chat reply) still gets normal Spanish \
        punctuation.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. When the words suggest code, \
        lean toward the compact rendering above — identifiers, file names and \
        symbols are far more likely here than in ordinary writing, and they stay \
        in ASCII with no accents. Prose (comments, commit messages, \
        documentation) is still normal Spanish and keeps its accents, its ¿…? \
        and its ¡…!.
        """,
        selfCorrectionRule: """
        Resolve self-corrections: when the speaker changes their mind \
        mid-sentence — usually with "no", "perdón", "digo", "mejor dicho", \
        "quiero decir" or "o sea" — keep ONLY the corrected version, the one \
        spoken LAST, and drop both the earlier attempt and the marker: "el \
        martes, no, perdón, el miércoles" → "el miércoles"; "manda cinco, digo \
        seis copias" → "manda seis copias". Never keep both.
        """,
        addendum: """
        - Spanish questions and exclamations use opening marks too: write \
        ¿…? and ¡…! around them, placing the opening sign exactly where the \
        question or exclamation starts — after a leading vocative or \
        subordinate clause, not before it ("María, ¿qué hora es?", "Si no \
        tienes clase, ¿por qué no vienes?"). Never write a period after a \
        closing ? or !.
        - Accents are part of the spelling: restore the diacritic on \
        interrogatives inside a question (qué, quién, cuál, cómo, dónde, \
        cuándo, cuánto) and keep every other tilde the speaker's words need \
        (más, está, sí, él, tú, aquí). Do not add accents to names, commands \
        or identifiers.
        - Leave numbers exactly as dictated. Spanish accepts both the comma and \
        the point as the decimal separator, so never "correct" one into the \
        other, and never regroup digits.
        - Keep any English or other-language words the speaker used as they \
        were spoken. Do not translate them into Spanish, and do not translate \
        the dictation out of Spanish.
        """)
}
