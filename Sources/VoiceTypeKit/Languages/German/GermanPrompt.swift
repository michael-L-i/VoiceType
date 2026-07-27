import Foundation

extension LanguagePromptGuidance {
    /// German's contribution to the on-device cleanup instruction.
    ///
    /// The division of labour with `GermanRules` is deliberate: the rules own
    /// what is *always* right (spacing, typography, closed-class capitals), and
    /// this file owns everything that needs meaning. Three things in German
    /// need meaning badly enough to be worth the prompt tokens:
    ///
    /// 1. **Noun capitalization.** German capitalizes every noun and every
    ///    nominalized word. No regex can tell "das Essen" from "wir essen", so
    ///    this is the single most valuable thing the model does for German.
    /// 2. **Modal particles.** "doch", "ja", "mal", "halt", "eben", "denn",
    ///    "wohl", "eh" look like fillers and are not — they carry the sentence's
    ///    attitude. They are named explicitly as keep-words, because a model
    ///    told to "remove filler words" will otherwise eat them.
    /// 3. **Transcriber failure modes.** German ASR splits compounds
    ///    ("nachzumachen" → "nach zu machen") and confuses das/dass, seit/seid,
    ///    man/Mann. Those are repairs, not rewrites, and only a model can make
    ///    them.
    ///
    /// No `fewShot` pairs ship. Eval has shown the model echoing example
    /// content into unrelated output, and German cannot justify the risk until
    /// it has a model-engine battery of its own — `cases.de.json` is currently
    /// gated on `--engine rules` only.
    static let german = LanguagePromptGuidance(
        // Phrased as its own sentence rather than a ": …" list, so the generic
        // instruction it is appended to stays a complete sentence.
        fillerExamples: #". The German hesitation sounds are "äh", "ähm", "ähem", "öh", "öhm", "hm", "hmm" and "mhm" — always drop them, along with empty padding like "weißt du", "sag ich mal", "sozusagen" or "irgendwie" when it carries no meaning. But NEVER drop the modal particles "doch", "ja", "mal", "halt", "eben", "denn", "schon", "wohl", "eh", "bloß" or "ruhig": in German these change what the sentence means or how it is meant, so they are content, not filler"#,
        capitalizationRule: """
        Fix capitalization the German way: capitalize EVERY noun and every \
        nominalized word ("das Laufen", "etwas Neues", "beim Essen", "der \
        Einzelne"), start every sentence with a capital letter, and capitalize \
        proper nouns (names, places, weekdays, months). Borrowed English words \
        used as nouns are nouns too: "das Feature", "der Commit", "die \
        Pipeline". Verbs, adjectives and adverbs stay lowercase unless they are \
        nominalized. The pronoun "ich" is never capitalized. The polite address \
        "Sie", "Ihnen", "Ihr", "Ihre" IS capitalized, while the ordinary "sie" \
        (she/they) stays lowercase.
        """,
        codeRendering: """
        When the surrounding words make it clear the speaker is dictating code — \
        a file name, a symbol, an identifier, or a handle — render it compactly \
        instead of as separate words, and leave ordinary German prose alone:
        - File names → paths: "haupt Punkt py" → haupt.py, "config Punkt json" → \
        config.json. German letter names spell out the extension: "Punkt jott es" \
        → .js, "Punkt te es" → .ts, "Punkt ha te em el" → .html, "Punkt em de" → .md.
        - Spoken symbols → characters: "Punkt" → ., "Komma" → ,, "Unterstrich" → \
        _, "Bindestrich"/"Strich"/"Minus" → -, "Schrägstrich" → /, "Doppelpunkt" \
        → :, "Klammer auf"/"Klammer zu" → ( ), "eckige Klammer auf"/"eckige \
        Klammer zu" → [ ], "Raute" → #, "Stern"/"Sternchen" → *, "gleich" → =, \
        "Tilde" → ~, "at"/"ätt" → @.
        - German speakers mix in the English names for the same symbols — "dot", \
        "underscore", "slash", "dash" — render those identically.
        - Identifiers and file names keep their English spelling and their \
        lowercase: "max Unterstrich retries" → max_retries, "camel case parse \
        request" → parseRequest. German noun capitalization NEVER applies inside \
        an identifier, a file name, a branch name or a command.
        - The trigger word is consumed, never kept: "max Unterstrich retries" → \
        max_retries, never max_unterstrich_retries. And never join words the \
        speaker did not mark: "die Session Token" stays three words.
        - A trigger word inside ordinary prose stays prose: "das bringt es auf \
        den Punkt" is not "das.bringt", and "ein Strich durch die Rechnung" \
        keeps every word.
        """,
        terminalGuidance: """
        The user is dictating into a terminal, so expect shell commands, flags, \
        paths and git/tmux vocabulary alongside ordinary sentences:
        - Render spoken flags and paths: "Strich Strich verbose" → --verbose, \
        "Minus v" → -v, "Tilde Schrägstrich Projekte" → ~/projekte, "Punkt \
        Schrägstrich build" → ./build.
        - Command lines stay exactly as commands are spelled: lowercase (git \
        status, ls, tmux attach). German noun capitalization does NOT apply \
        here — never capitalize a command, a flag, a path or a branch name, and \
        never add a trailing period to a command.
        - A dictated sentence that is clearly prose (a commit message, a chat \
        reply) still gets normal German punctuation and capitalization.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. When the words suggest code, \
        lean toward the compact rendering above: identifiers, file names and \
        symbols are more likely here than in ordinary writing, and they keep \
        their English spelling and lowercase — German noun capitalization is a \
        rule about prose, never about code. Comments, commit messages and \
        documentation are prose and get normal German sentences.
        """,
        selfCorrectionRule: """
        Resolve self-corrections: when the speaker changes their mind \
        mid-sentence — usually marked by "nein", "äh nein", "Quatsch", "Moment", \
        "besser gesagt", "beziehungsweise" or "ich meine" — keep only the \
        corrected version, the one spoken LAST, and drop both the earlier \
        attempt and the marker: "wir brauchen fünf, nein sechs Exemplare" → \
        "wir brauchen sechs Exemplare", never "fünf Exemplare".
        """,
        addendum: """
        - The dictation is German. Write German orthography: „…“ for quotation \
        marks, the typographic apostrophe ’ ("geht’s"), a decimal comma \
        ("3,14") and a period as the thousands separator ("1.000").
        - Re-join compounds the transcriber split apart — this is German ASR's \
        most common error: "nach zu machen" → "nachzumachen", "Sprach \
        Erkennung" → "Spracherkennung", "Konfigurations Datei" → \
        "Konfigurationsdatei". Only when the pieces are clearly one German \
        compound; never invent one.
        - Fix homophones the transcriber gets wrong, without rewriting the \
        sentence: "das" vs. "dass" (dass introduces a subordinate clause), \
        "seit" vs. "seid", "wider" vs. "wieder", "man" vs. "Mann", "wen" vs. \
        "wenn", "den" vs. "denn", "wahr" vs. "war". Restore umlauts that change \
        the word: "schon" vs. "schön", "fuhr" vs. "für".
        - Write ß after a long vowel or a diphthong ("Straße", "groß", "heiß") \
        and ss after a short one ("dass", "muss", "Fluss").
        - Keep English technical terms exactly as spoken ("Feature", "Commit", \
        "Deployment", "Branch", "gepusht") — do not translate them into German, \
        and never translate the German into English.
        """)
}
