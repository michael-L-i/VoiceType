import Foundation

extension LanguagePromptGuidance {
    /// Bokmål-specific guidance for the on-device cleanup model.
    ///
    /// `fewShot` and `terminalFewShot` deliberately remain empty. This task's
    /// model engine is shared and not safe to run in parallel, so no Norwegian
    /// example has earned the leakage risk. Mechanical guarantees live in
    /// `NorwegianRules`; this prompt covers only decisions requiring context.
    static let norwegian = LanguagePromptGuidance(
        fillerExamples: #": "eh", "ehm", "øh", "øhm", and a throwaway "altså" / "liksom" / "på en måte" / "du vet" / "ikke sant" only when it carries no meaning"#,
        capitalizationRule: """
        Fix capitalization the Norwegian Bokmål way: start sentences and \
        proper names with a capital letter. Keep ordinary nouns, titles, \
        languages, nationalities, weekdays, months and holidays lowercase \
        (statsministeren, norsk, nordmann, mandag, juli, jul). After a colon, \
        capitalize only when a complete independent sentence or a direct \
        quotation follows; a single word, phrase or subordinate clause stays \
        lowercase. Preserve established casing in names, brands, acronyms, \
        file names and identifiers.
        """,
        codeRendering: """
        When context clearly shows that the speaker is dictating code, a file \
        name, identifier, path, e-mail address or handle, render it compactly \
        and leave ordinary Norwegian prose alone:
        - Spoken symbols → characters: "punktum" → ., "komma" → ,, \
        "bindestrek" → -, "understrek"/"underscore" → _, "skråstrek" → /, \
        "krøllalfa"/"alfakrøll" → @, "åpne parentes"/"lukk parentes" → ( ).
        - File names and paths join up: "main punktum py" → main.py, "config \
        punktum json" → config.json, "src skråstrek index punktum ts" → \
        src/index.ts.
        - Identifiers and addresses join only where a symbol was spoken: \
        "maks understrek forsøk" → maks_forsøk, "ola krøllalfa eksempel \
        punktum no" → ola@eksempel.no. Never join unmarked words.
        - Consume the symbol name; never output main_punktum_py or \
        maks_understrek_forsøk.
        - In ordinary prose the same word stays a word: "sette punktum for \
        saken" is prose, and "tre komma fem" is the decimal 3,5.
        - Preserve English commands, keywords, APIs, library names, product \
        names and identifiers exactly; never translate them into Norwegian.
        """,
        terminalGuidance: """
        The user is dictating into a terminal, so expect shell commands, flags, \
        paths and git/tmux vocabulary mixed with Norwegian:
        - Render flags and paths: "bindestrek bindestrek verbose" or "minus \
        minus verbose" → --verbose, "bindestrek v" → -v, "tilde skråstrek \
        prosjekter" → ~/prosjekter, "punktum skråstrek build" → ./build.
        - Keep commands, subcommands, flags, paths, environment variables and \
        identifiers in their exact original casing and language. Never \
        capitalize the first command, translate a command/flag, or add a \
        trailing period.
        - If the dictated terminal text is clearly prose (for example a commit \
        message), use normal Bokmål capitalization and punctuation inside that \
        prose without changing the command syntax around it.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Prefer compact symbol, file \
        name and identifier rendering when code context makes it clear. Keep \
        English keywords, API names, commands and existing identifier casing \
        unchanged. Comments, documentation, commit messages and other prose \
        still follow ordinary Bokmål orthography.
        """,
        selfCorrectionRule: """
        Resolve Norwegian self-corrections marked by "nei", "eh nei", "vent", \
        "beklager", "jeg mener", "eller rettere": keep only the corrected \
        wording spoken LAST, and remove the abandoned attempt and correction \
        marker. "fem, nei seks eksemplarer" becomes "seks eksemplarer", never \
        "fem eksemplarer". Do not treat an ordinary contrast containing "nei" \
        as a correction.
        """,
        addendum: """
        - Write standard Norwegian Bokmål without translating, paraphrasing or \
        replacing legitimate Bokmål variants. Preserve dialect-bearing content \
        and embedded English names; correct only a clearly mechanical \
        transcription/spacing error when the intended words are certain.
        - Norwegian compounds are normally written as one word. Rejoin an \
        obviously split compound ("språk modell", "programvare utvikler") as \
        "språkmodell", "programvareutvikler", but do not guess when the words \
        can form an ordinary phrase.
        - Use Norwegian number typography: decimal comma (3,5), spaces to group \
        large numbers (1 250 000), a space between a number and a unit or \
        designator (10 %, 10 kr, 5 kg, 18 °C), and day-month-year dates with \
        lowercase month names (17. mai 2026). Keep ISO dates and technical \
        version strings unchanged.
        - Prefer outward Norwegian guillemets («slik») for prose quotations, \
        with punctuation inside them only when it belongs to the quoted text. \
        Preserve straight quotes in code and identifiers.
        - Always remove eh/ehm/øh/øhm. Remove "altså", "liksom", "bare", \
        "egentlig", "sånn", "vel", "jo", "du vet", "ikke sant" or "på en \
        måte" ONLY when clearly empty; each can carry meaning. When in doubt, \
        keep it.
        """)
}
