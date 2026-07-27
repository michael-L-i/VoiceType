import Foundation

extension LanguagePromptGuidance {
    /// Bulgarian-specific substance for the shared on-device cleanup prompt.
    ///
    /// There are deliberately no few-shot examples. This pack cannot run the
    /// single shared on-device model during parallel localization work, and an
    /// unmeasured example is not worth the known content-echoing risk.
    static let bulgarian = LanguagePromptGuidance(
        fillerExamples: #": prolonged hesitation sounds such as "ъъъ", "ааа", "ъм"; and "ами", "значи", "такова", "нали", "така", or "в смисъл" ONLY when context makes them empty planning noise. Keep those words whenever they connect ideas, answer, confirm, point to something, or otherwise carry meaning. A single "а", and responses/interjections such as "мхм", "аха", "да", "не", "ех", and "ах", are meaningful — keep them"#,
        capitalizationRule: """
        Fix Bulgarian capitalization: capitalize the beginning of each \
        sentence and genuine proper names. Bulgarian common nouns, language \
        and nationality names, weekdays, and months normally stay lowercase. \
        In a multi-word Bulgarian proper name, capitalize the first component \
        and any component that is itself a proper name; do not copy English \
        Title Case. Preserve clearly intentional polite Вие/Ви/Ваш in formal \
        direct address, but do not capitalize ordinary plural pronouns.
        """,
        codeRendering: """
        When context clearly says the speaker is dictating code, a file name, \
        an identifier, an email address, or a handle, interpret Bulgarian \
        symbol names and keep the result compact:
        - "main точка py" → main.py, "config точка джейсон" → config.json, and \
        "test долна черта client точка py" → test_client.py. Keep extensions \
        and identifiers in Latin script; never transliterate or translate \
        existing English code tokens.
        - "долна черта"/"ъндърскор" → _, "тире"/"дефис" → -, "наклонена \
        черта"/"слеш" → /, "отваряща скоба"/"затваряща скоба" → ( ), \
        "квадратна скоба" → [ ], "равно" → =, and "запетая" → , where code \
        context makes the symbol reading clear.
        - In an email address, "кльомба" or "маймунско а" → @ and "точка" → .; \
        join the marked parts without spaces.
        - Consume the spoken trigger instead of retaining its words. Do not \
        join unmarked words, and keep an ordinary lexical use such as \
        "отправна точка", "долна черта на графиката", or "минус три" as prose.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Preserve commands, flags, paths, \
        file names, environment variables, and identifiers exactly in their \
        Latin spelling; do not translate or transliterate them into Cyrillic.
        - "тире v", "дефис v", or "минус v" → -v; two spoken markers before a \
        name → a long flag, so "тире тире verbose" → --verbose.
        - "тилда наклонена черта projects" → ~/projects, "точка наклонена \
        черта build" → ./build, and spoken slashes join path segments.
        - A shell command stays lowercase and receives no trailing sentence \
        punctuation. Prose supplied as a commit message or argument still uses \
        normal Bulgarian orthography when that role is clear.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Prefer compact rendering for \
        explicitly spoken identifiers, file names, operators, and delimiters, \
        and preserve their case and script. Bulgarian comments, documentation, \
        and prose strings still follow normal Bulgarian punctuation and \
        capitalization; do not turn ordinary Bulgarian words into symbols \
        without a clear code signal.
        """,
        selfCorrectionRule: """
        Resolve explicit Bulgarian self-corrections by keeping the replacement \
        spoken last and removing only the abandoned attempt: "трябват ни пет, \
        не, шест копия" → "трябват ни шест копия"; "в сряда, всъщност в \
        четвъртък" → "в четвъртък". Markers can include "не", "чакай", \
        "всъщност", "по-скоро", "тоест", or "поправка", but these words also \
        have legitimate meanings. Treat them as repair markers only when the \
        speaker clearly replaces earlier material, and preserve ordinary \
        negation and explanation.
        """,
        addendum: """
        - Use standard Bulgarian typography: paired quotation marks are „…“; \
        there is no space before . , ; : ! or ?, and one space follows them \
        in running text. Quotation marks and parentheses touch the text inside.
        - Use a comma as the decimal separator and a nonbreaking space for \
        digit grouping and between a number and a following currency sign or \
        code (for example 1 234,56 €, 50 EUR, 50 лв.). Do not reinterpret \
        version numbers, IP addresses, dates, file names, or code as decimals.
        - Keep Bulgarian numeric dates compact with dots (26.07.2026 г.) and \
        write month and weekday names lowercase. Put currency units after the \
        amount unless faithfully preserving a quoted foreign or code form.
        - Use the apostrophe for a genuinely omitted letter in colloquial \
        writing. Use ѝ, not и or й, for the feminine singular dative/possessive \
        clitic only when grammar makes that reading certain; keep the \
        conjunction и unchanged.
        - Bulgarian yes/no questions often use ли after the focused word \
        ("Ще дойдеш ли утре?"). Add the question mark from sentence meaning, \
        including multi-word question openers, without turning embedded \
        clauses such as "Не знам има ли време" into standalone questions.
        """)
}
