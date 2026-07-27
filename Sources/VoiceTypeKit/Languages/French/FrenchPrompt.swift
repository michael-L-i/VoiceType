import Foundation

extension LanguagePromptGuidance {
    /// French's contribution to the on-device cleanup instruction.
    ///
    /// The division of labour with `FrenchPack`'s rules is deliberate: anything
    /// a typography manual can state without knowing what the speaker meant is
    /// already guaranteed in code, so the prompt does not spend tokens asking
    /// for it twice — the observed failure mode is that mechanical requests are
    /// inert while every extra line dilutes the ones that matter. What is here
    /// is only what needs *meaning*: which hesitation words are empty this
    /// time, which noun is a proper noun, where an identifier ends.
    ///
    /// `fewShot` stays empty. Examples are the highest-leverage and
    /// highest-risk part of this prompt — the model has been caught echoing
    /// them into unrelated output — and shipping a French set is a judgment
    /// only a `--engine model` battery can make. That run drives the single
    /// on-device model and was out of scope for this pack; the deterministic
    /// battery in `cases.fr.json` is what has been verified.
    static let french = LanguagePromptGuidance(
        // "euh" and its spellings are already deleted deterministically. The
        // value here is the second list: French discourse markers that hesitate
        // *and* mean something, which only context can separate.
        fillerExamples: #": "euh", "heu", "hum", and a throwaway "ben", "bah", "bon", "genre", "du coup", "en fait", "tu vois", "tu sais", "voilà", "quoi", "je veux dire" when it carries no meaning. Keep any of those that do carry meaning — "du coup" as a real consequence, "genre" as an actual kind of thing, "voilà" as a real "there it is""#,
        // The generic rule says "capitalize days" — true in English, wrong in
        // French, which is why this replaces it wholesale.
        capitalizationRule: """
        Fix capitalization the French way: a capital at the start of each \
        sentence and on proper nouns (people, places, organizations, brands), \
        and nothing else. Days, months, languages and adjectives of nationality \
        stay lowercase ("lundi", "en mars", "il parle français", "un vin \
        français") — but the noun for a person keeps its capital ("un \
        Français"). "je" is lowercase unless it opens the sentence. Keep the \
        accent on a capital letter: "École", "À demain", "Étienne".
        """,
        codeRendering: """
        When the surrounding words make it clear the speaker is dictating code — \
        a file name, a symbol, an identifier, or a username — render it \
        compactly instead of as separate words, and leave ordinary prose alone:
        - File names → paths: "main point py" → main.py, "index point j s" → \
        index.js. "point pi" is .py.
        - Spoken symbols → characters: "point" → ., "virgule" → ,, "tiret bas" \
        → _, "tiret"/"trait d'union" → -, "slash"/"barre oblique" → /, \
        "arobase" → @, "dièse" → #, "étoile"/"astérisque" → *, "ouvrez la \
        parenthèse"/"fermez la parenthèse" → ( ), "ouvrez le crochet" → [.
        - Identifiers join up: "get tiret bas user tiret bas data" → \
        get_user_data, "camel case parse request" → parseRequest.
        - The trigger word is consumed, never kept: "max tiret bas retries" → \
        max_retries, never max_tiret_bas_retries. And never join words the \
        speaker did not mark: "le jeton de session" stays four words.
        - Code stays ASCII: no French spacing, no guillemets and no typographic \
        apostrophe inside a file name, an identifier or a string literal.
        - A trigger word inside ordinary prose stays prose: « le point de vue », \
        « à quel point », « un trait d'union entre les deux » are sentences, not \
        symbols.
        """,
        terminalGuidance: """
        The user is dictating into a terminal, so expect shell commands, flags, \
        paths, and git vocabulary alongside ordinary sentences:
        - Render spoken flags and paths: "tiret tiret verbose" → --verbose, \
        "tiret v" → -v, "tilde slash projets" → ~/projets, "point slash build" \
        → ./build.
        - Command lines stay exactly as commands are spelled: lowercase (git \
        status, ls, tmux attach), never capitalize the first word of a command, \
        and never add a trailing period.
        - No French typography inside a command: no space before : ; ! ?, no \
        guillemets, no typographic apostrophe. A dictated sentence that is \
        clearly prose (a commit message) still gets normal French punctuation.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. When the words suggest code, \
        lean toward the compact rendering above — identifiers, file names and \
        symbols are more likely here than in ordinary writing, and they stay \
        pure ASCII. Prose (comments, commit messages, documentation) reads as \
        normal French sentences with normal French punctuation.
        """,
        selfCorrectionRule: """
        Resolve self-corrections: when the speaker changes their mind \
        mid-sentence — usually with "non", "enfin", "plutôt", "pardon" or "je \
        veux dire" — keep only the version spoken LAST and drop both the earlier \
        attempt and the marker: « on se voit mardi, non mercredi » → « on se \
        voit mercredi », never « on se voit mardi ».
        """,
        // Everything below needs context. The unconditional half of French
        // typography (the fine space, guillemets, the apostrophe, ordinals,
        // lowercase months) is already guaranteed by the pack's rules whichever
        // engine produced the text, so it is not repeated here.
        addendum: """
        - Write French punctuation: « … » for quotations, and the decimal \
        comma for numbers ("trois virgule quatorze" is 3,14 — never a list of \
        two numbers).
        - Render a spoken punctuation name as the mark when the speaker is \
        clearly dictating it: « point » at the end of a sentence is a full \
        stop, « deux points » before an enumeration is a colon. When the word \
        is the noun — « c'est un bon point », « il reste deux points à régler » \
        — keep it as a word. When in doubt, keep the word.
        """)
}
