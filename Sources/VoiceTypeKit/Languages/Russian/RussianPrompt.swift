import Foundation

extension LanguagePromptGuidance {
    /// Russian-specific substance for the shared on-device cleanup contract.
    /// Few-shot examples intentionally stay empty: this language has not run a
    /// model eval, and example leakage is worse than a slightly plainer prompt.
    static let russian = LanguagePromptGuidance(
        fillerExamples: #": drawn-out hesitation sounds such as "ээ", "эээ", "э-э", "э-э-э", and — only when they carry no meaning — "ну", "вот", "значит", "короче", "типа", "как бы", "это самое", "так сказать", "в общем""#,
        capitalizationRule: """
        Fix Russian capitalization: capitalize the first word of each sentence \
        and genuine proper names, while keeping ordinary nouns lowercase. Keep \
        days of the week and month names lowercase (понедельник, июль) except \
        where a proper holiday name requires otherwise. Write вы/ваш lowercase \
        by default; use Вы/Ваш only when the context clearly is a polite formal \
        address to one specific person. Preserve established all-caps \
        abbreviations and do not treat abbreviation periods as sentence ends.
        """,
        codeRendering: """
        When the surrounding Russian words clearly indicate code, a file name, \
        an email, a symbol, an identifier, or a handle, render the technical \
        text compactly and keep ordinary Russian prose unchanged:
        - File names: "main точка пай" / "main точка пи" → main.py, "config \
        точка json" → config.json, "index точка джи эс" → index.js. Preserve \
        the extension and Latin spelling supported by context; do not \
        transliterate an existing Latin identifier into Cyrillic.
        - Symbols: "нижнее подчёркивание" / "подчеркивание" → _, "дефис" → -, \
        "слэш" / "косая черта" → /, "обратный слэш" → \\, "тильда" → ~, \
        "собака" → @, "открывающая скобка" / "закрывающая скобка" → ( / ).
        - Consume the spoken symbol name: "max нижнее подчёркивание retries" → \
        max_retries, never max_нижнее_подчёркивание_retries. Join only the \
        parts the speaker explicitly marked; "токен сессии" remains two words.
        - Keep letter case that is meaningful in code. If the speaker says \
        "camel case parse request", render parseRequest; if the speaker spells \
        Latin letters, keep them Latin.
        - A symbol word in ordinary prose remains a word: "точка зрения", \
        "точка доступа", "плюс проекта", "минус решения" must not become code.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Expect Russian command narration \
        mixed with literal ASCII commands, flags, paths, and Git vocabulary:
        - Render flags: "дефис дефис verbose" / "минус минус verbose" → \
        --verbose; "дефис v" / "минус вэ" → -v when the intended Latin letter \
        is clear.
        - Render paths: "тильда слэш projects" → ~/projects, "точка слэш build" \
        → ./build, "src слэш main" → src/main.
        - Keep literal commands, options, paths, environment variables, hashes, \
        and file names in ASCII with their exact case. Never capitalize the \
        first command and never add sentence-final punctuation to a command.
        - Russian prose intentionally dictated as a commit message or shell \
        argument still gets normal Russian spelling, but do not quote, escape, \
        or execute it unless those characters were spoken.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Bias technical phrases toward \
        compact identifiers, file names, symbols, and Latin API names, but keep \
        Russian comments, documentation, commit messages, and string content as \
        normal Russian prose. Never translate an existing identifier or silently \
        change its API spelling.
        """,
        selfCorrectionRule: """
        Resolve Russian self-corrections only when the change is explicit: keep \
        the LAST version and remove the retracted words around markers such as \
        "нет", "неверно", "точнее", "вернее", "стоп", "подожди", "то есть". \
        Thus "во вторник, нет, в среду утром" keeps "в среду утром". Do not \
        delete an ordinary negation merely because it contains "не" or "нет".
        """,
        fewShot: [],
        terminalFewShot: [],
        addendum: """
        - Use Russian punctuation and typography. Outer quotation marks are \
        «ёлочки»; nested quotation marks are „лапки“. Put a full stop after the \
        closing quotation mark, while a question mark, exclamation mark, or \
        ellipsis that belongs to the quoted words stays inside.
        - A punctuation dash is spaced (слово — слово); a hyphen inside a word \
        is not (по-русски). Do not confuse a mathematical minus or an unspaced \
        numeric range with a punctuation dash.
        - Use a comma for an ordinary Russian decimal fraction (3,14) and spaces \
        to group long numbers (1 000 000), but preserve dots in versions, IP \
        addresses, dates, file names, and machine-readable values. Numeric dates \
        use day.month.year (26.07.2026); a worded date is "26 июля 2026 г.".
        - Put currency and measurement designations after the value with a space: \
        "100 ₽", "100 руб.", "20 °C", "80 %". Do not rewrite a fully spoken \
        amount such as "сто рублей" into digits or a symbol.
        - Preserve apostrophes in foreign names and Latin/Cyrillic technical \
        forms. Do not use an apostrophe instead of the Russian hard sign.
        - The letter ё may be written consistently or selectively in ordinary \
        Russian text. Preserve the speaker/transcriber's ё; add it only when it \
        prevents a real ambiguity or is known to belong to a proper name. Never \
        guess between е and ё.
        - Correct obvious ASR spelling only when context makes the intended \
        Russian word certain. Be especially conservative with unstressed-vowel \
        homophones, не/ни, -тся/-ться, names, abbreviations, mixed Cyrillic/Latin \
        text, and dictated individual letters.
        """)
}
