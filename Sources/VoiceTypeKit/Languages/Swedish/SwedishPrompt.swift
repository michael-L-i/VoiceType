import Foundation

extension LanguagePromptGuidance {
    /// Swedish's contribution to the on-device cleanup instruction.
    ///
    /// The division of labour with `SwedishRules` is deliberate: anything that
    /// is *always* right in Swedish — spacing before %, ”…” quotes, lowercase
    /// weekdays, the period after an unambiguous "punkt" — is done in code and
    /// left out of the prompt, because prompt content leaks and prompt tokens
    /// cost latency. What is left here is the judgment the model is actually
    /// needed for:
    ///
    /// - **Särskrivning.** Swedish compounds are one word, and speech
    ///   recognition splits them constantly ("kaffe kopp", "styr else möte").
    ///   Rejoining needs a lexicon and context; no rule can do it.
    /// - **de / dem / dom.** Spoken Swedish says "dom" for both; written
    ///   Swedish needs the subject/object distinction. A blind mapping would
    ///   be wrong roughly half the time, and "dom" is also a noun (a verdict).
    /// - **The spoken "å"** standing in for "och" or "att" — but "å" is also a
    ///   real word (a stream) and an interjection.
    /// - **Ambiguous hesitations** — `liksom`, `typ`, `alltså`, `ju`, `ba` are
    ///   never removed deterministically; here the model has the context to
    ///   decide whether they carry meaning.
    /// - **Decimal comma and thousands grouping**, which a rule cannot tell
    ///   apart from version numbers, years and port numbers.
    ///
    /// `fewShot` stays empty. The harness's own hard-won lesson is that
    /// example pairs leak into unrelated output, and nothing in this pack has
    /// been through a `--engine model` battery yet; shipping examples on a
    /// hunch is exactly the failure mode documented in
    /// `Scripts/cleanup-eval/README.md`.
    static let swedish = LanguagePromptGuidance(
        fillerExamples: #": "eh", "öh", "öhm", "hmm", and throwaway "liksom" / "typ" / "alltså" / "ba" / "ju" when they carry no meaning — but keep them when they do ("liksom hans bror" = "like his brother", "typ 20 personer" = "about 20")"#,
        capitalizationRule: """
        Fix capitalization the Swedish way: start every sentence with a \
        capital letter and capitalize proper nouns (people, places, \
        companies). Swedish keeps lowercase where English capitalizes — \
        weekdays (måndag), months (juli), seasons (vintern), holidays (jul, \
        påsk), languages and nationalities (svenska, engelska, svensk, tysk), \
        job titles (vd, professor) — and the pronoun "jag" is never \
        capitalized mid-sentence. In a multi-word name only the first word \
        takes a capital: Stockholms universitet, Sveriges riksdag.
        """,
        codeRendering: """
        When the surrounding words make it clear the speaker is dictating code \
        — a file name, a symbol, an identifier, or a username — render it \
        compactly instead of as separate words, and leave ordinary prose alone:
        - File names → paths: "app punkt py" → app.py, "main punkt paj" → \
        main.py ("paj"/"pi" is how a Swedish transcriber writes the spoken \
        ".py"). Pick the extension from context (.py, .js, .ts, .rs, .go, \
        .swift).
        - Spoken symbols → characters: "punkt" → ., "understreck" → _, \
        "bindestreck" → -, "snedstreck" → /, "snabel-a" → @, \
        "vänsterparentes"/"högerparentes" → ( ), "hakparentes" → [ ], \
        "kommatecken" → ,, "likhetstecken" → =.
        - Identifiers join up and keep the spelling the speaker used, Swedish \
        or English: "max understreck försök" → max_försök, "get understreck \
        user data" → get_user_data. Never translate an identifier.
        - The trigger word is consumed, never kept: "max understreck försök" → \
        max_försök, never max_understreck_försök. And never join words the \
        speaker did not mark: "den nya sessionen" stays three words.
        - But a trigger word inside ordinary prose stays prose: "punkt" in "en \
        viktig punkt" is the noun, and "streck" in "ett streck i räkningen" is \
        a line — neither is a character.
        """,
        terminalGuidance: """
        The user is dictating into a terminal, so expect shell commands, \
        flags, paths and git vocabulary alongside ordinary sentences:
        - Render spoken flags and paths: "streck streck verbose" → --verbose, \
        "streck v" → -v, "tilde snedstreck projekt" → ~/projekt, "punkt \
        snedstreck build" → ./build.
        - Command lines stay exactly as commands are spelled: lowercase (git \
        status, ls, tmux attach), never capitalize the first word of a \
        command, and never add a trailing period to a command.
        - Command names, subcommands and flags stay English even though the \
        dictation is Swedish — never translate "status", "commit" or \
        "--force".
        - A dictated sentence that is clearly prose (a commit message, a chat \
        reply) still gets normal Swedish punctuation and capitalization.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. When the words suggest code, \
        lean toward the compact rendering above — identifiers, file names and \
        symbols are more likely here than in ordinary writing, and an \
        identifier keeps whatever language the speaker spelled it in. Prose \
        (comments, commit messages, documentation) still reads as normal \
        Swedish sentences, with compounds written as one word.
        """,
        selfCorrectionRule: """
        Resolve self-corrections: when the speaker changes their mind \
        mid-sentence — marked by "nej", "förlåt", "eller", "eller förresten", \
        "jag menar", "rättare sagt" — keep only the corrected version, the one \
        spoken LAST, and drop both the earlier attempt and the marker: "fem, \
        nej sex exemplar" → "sex exemplar", never "fem exemplar".
        """,
        // Empty until a --engine model battery shows they earn their place.
        fewShot: [],
        terminalFewShot: [],
        // The shared assembly appends this straight after the category
        // guidance, so it opens with its own header — otherwise the Swedish
        // orthography rules read as a continuation of the terminal section.
        addendum: """
        Swedish writing conventions, whatever the app:
        - Swedish compounds are written as ONE word. Speech recognition splits \
        them constantly — "kaffe kopp", "styr else möte", "e post adress" — so \
        join them back up: kaffekopp, styrelsemöte, e-postadress. Never split \
        a compound that arrived whole.
        - Write "de" or "dem" in running text, never the spoken "dom": "de" as \
        the subject (de kommer i morgon), "dem" as the object or after a \
        preposition (jag såg dem, till dem). If the transcript says "dom", \
        pick the right one; if it is genuinely unclear, use "de". Leave the \
        noun "dom" (a court ruling) alone.
        - A spoken "å" that stands for "och" or "att" is a transcription \
        error — write och / att. The noun "å" (a stream) and the interjection \
        "å nej" stay as they are.
        - Numbers follow Swedish conventions: decimal comma (3,14 — never \
        3.14) and a space as the thousands separator (1 500, 20 000). Leave \
        version numbers, dates and identifiers exactly as they are.
        - Genitive is a bare -s with no apostrophe: Annas bok, Sveriges \
        riksdag. A name that already ends in s, x or z takes nothing at all: \
        Lars bok.
        - Keep English loanwords, product names, commands and identifiers in \
        their English spelling — never translate or Swedify them.
        """)
}
