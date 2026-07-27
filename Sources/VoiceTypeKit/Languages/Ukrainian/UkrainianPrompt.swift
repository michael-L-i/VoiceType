import Foundation

extension LanguagePromptGuidance {
    /// Ukrainian-specific instruction for the on-device cleanup model.
    ///
    /// Few-shot examples are intentionally empty. Ukrainian has no isolated
    /// model eval proving they help, while example leakage is a known failure
    /// mode of the small on-device model.
    static let ukrainian = LanguagePromptGuidance(
        fillerExamples: #": Ukrainian hesitation sounds such as "е-е", "е-е-е", "ем-м", and "м-м-м""#,
        capitalizationRule: """
        Fix Ukrainian capitalization: capitalize the first word of each sentence \
        and Ukrainian proper names. Keep ordinary names of weekdays, months, \
        languages, and nationalities lowercase unless they begin a sentence. In \
        organization and document names, do not capitalize every word blindly.
        """,
        codeRendering: """
        When context clearly shows that the Ukrainian speaker is dictating code, \
        a file name, an identifier, an email address, or a handle, render it \
        compactly and leave ordinary prose alone:
        - File names: "main крапка пі" → main.py, "config крапка json" → \
        config.json, "index крапка джей ес" → index.js.
        - Identifiers: "user андерскор id" or "user підкреслення id" → user_id. \
        Consume the spoken symbol word; never output user_андерскор_id. Join \
        only words the speaker explicitly connects.
        - Symbols: "відкрита дужка" / "закрита дужка" → ( / ), "кома" inside \
        brackets → ,, "слеш" → /, "дефіс" → -, "ет" or "равлик" in a clearly \
        dictated email address → @.
        - Keep embedded English spelling, case, file extensions, API names, URLs, \
        and identifiers exactly as dictated. In ordinary Ukrainian prose, \
        "крапка", "мінус", "кома", and "підкреслення" remain words unless the \
        surrounding structure unambiguously calls for a symbol.
        """,
        terminalGuidance: """
        The user is dictating into a terminal, so prefer literal shell syntax:
        - "мінус m" → -m and "мінус мінус verbose" → --verbose; keep flag and \
        command names in their original Latin spelling and case.
        - "тильда слеш projects" → ~/projects, "крапка слеш build" → ./build, \
        and "src слеш main" → src/main.
        - Do not capitalize a command, translate it, inflect it, or add sentence \
        punctuation. A clearly dictated prose value such as a commit message \
        still keeps the speaker's Ukrainian wording.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Prefer compact symbol, \
        identifier, and file-name rendering when explicit Ukrainian code words \
        signal it, but preserve Ukrainian prose in comments and documentation. \
        Never translate an English API or identifier, and never transliterate \
        Ukrainian prose merely because it appears beside code.
        """,
        selfCorrectionRule: """
        Resolve Ukrainian self-corrections by keeping only the replacement spoken \
        last and removing the abandoned wording and correction marker: "п’ять, \
        ні, шість копій" → "шість копій"; "у середу, точніше, у четвер" → "у \
        четвер". Words such as "ні", "тобто", "точніше", "стоп", and \
        "перепрошую" remain when they carry their ordinary meaning rather than \
        marking a correction.
        """,
        addendum: """
        - Keep the output Ukrainian. Never translate it into Russian or \
        "correct" Ukrainian forms into Russian ones. Preserve Ukrainian letters \
        і, ї, є, ґ and Ukrainian lexical choices; preserve embedded English or \
        other-language names exactly where spoken.
        - Use Ukrainian typography in prose: outer quotation marks «…» and inner \
        quotation marks “…”; no spaces before , . : ; ! ?, and one space after \
        them where text follows.
        - Restore required Ukrainian in-word apostrophes (п’ять, об’єкт, \
        комп’ютер) without surrounding spaces. Use a decimal comma (3,14), spaces \
        to group long numbers (12 500), compact numeric dates (26.07.2026), and \
        a space between an amount and грн or ₴.
        - Always remove nonlexical prolonged hesitation sounds. Remove "ну", \
        "типу", "значить", "коротше", "власне", "так", or "ось" only when context \
        makes the token a throwaway disfluency. Each can carry real meaning; when \
        in doubt, keep it.
        """)
}
