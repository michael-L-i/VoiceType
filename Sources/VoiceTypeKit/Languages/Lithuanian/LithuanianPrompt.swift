import Foundation

extension LanguagePromptGuidance {
    /// Lithuanian cleanup guidance. Few-shot examples intentionally stay empty:
    /// no Lithuanian model eval was run, and examples are known to leak into
    /// unrelated output.
    static let lithuanian = LanguagePromptGuidance(
        fillerExamples: #": "ėėė" / "eee" and, only when they carry no meaning, "mmm", "hmm", "na", "nu", "žodžiu", "ta prasme", "tipo", or "žinai""#,
        capitalizationRule: """
        Fix Lithuanian capitalization: capitalize the first word of each \
        sentence and proper names. Keep language names, nationalities, weekdays, \
        and month names lowercase unless they begin a sentence. In multi-word \
        institution, work, event, and product names, do not apply English title \
        case: capitalize only the first word and any proper-name components. \
        Preserve the exact casing of embedded file names, identifiers, commands, \
        acronyms, and foreign brands.
        """,
        codeRendering: """
        When context clearly shows Lithuanian technical dictation, render the \
        spoken symbols compactly and keep ordinary prose untouched:
        - File names: "config taškas json" → config.json, "main taškas py" → \
        main.py. Consume taškas only beside a plausible extension; in ordinary \
        Lithuanian taškas can mean a point, place, score, or decimal point.
        - Identifiers: "max pabraukimo brūkšnys retries" → max_retries. Consume \
        the whole phrase pabraukimo brūkšnys; do not leave its words in the \
        identifier and never join unmarked prose.
        - Parentheses and brackets: "atidaromasis skliaustas" / "uždaromasis \
        skliaustas" → ( / ); "atidaromasis laužtinis skliaustas" / \
        "uždaromasis laužtinis skliaustas" → [ / ].
        - Email: "jonas taškas jonaitis ženklas eta gmail taškas com" → \
        jonas.jonaitis@gmail.com.
        - Keep English technical tokens, extensions, identifiers, APIs, and \
        brands exactly spelled in ASCII. Do not translate or Lithuanianize them, \
        and do not invent diacritics or Lithuanian endings inside code.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Treat Lithuanian symbol names as \
        shell syntax while preserving command, flag, path, branch, and file-name \
        spelling exactly:
        - "brūkšnelis brūkšnelis verbose" → --verbose; "brūkšnelis v" → -v.
        - "tildė pasvirasis brūkšnys projektai" → ~/projektai; "taškas \
        pasvirasis brūkšnys build" → ./build; repeated pasvirasis brūkšnys \
        phrases continue a path.
        - Keep commands and flags lowercase unless the speaker explicitly spells \
        capitals. Never inflect or translate git, swift, npm, branch names, \
        identifiers, or paths. Never add sentence punctuation to a command.
        - If the terminal input is clearly Lithuanian prose, such as a commit \
        message, clean it as prose but do not alter quoted command fragments.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Prefer compact symbol, file, \
        and identifier rendering only where code context is clear. Preserve \
        ASCII spelling and casing inside code, strings, identifiers, paths, and \
        comments that quote code. Lithuanian comments and documentation use \
        normal Lithuanian sentence casing, punctuation, decimal commas, and \
        „…“ quotation marks; never rewrite an identifier to look Lithuanian.
        """,
        selfCorrectionRule: """
        Resolve Lithuanian self-corrections only when the correction is explicit: \
        keep the last replacement and remove the retracted wording, for example \
        "susitinkame trečiadienį, ne, ketvirtadienį" means keep only \
        "susitinkame ketvirtadienį". Markers such as "ne", "palauk", \
        "atsiprašau", "tiksliau", or "norėjau pasakyti" remain ordinary content \
        when they are not correcting earlier words. When uncertain, preserve \
        both attempts rather than guessing.
        """,
        addendum: """
        - Use Lithuanian punctuation spacing: no space before , . ; : ! or ?, \
        and one space after a mark when text continues.
        - Use Lithuanian double quotation marks „…“. Put a comma or full stop \
        after the closing quote when it belongs to the surrounding sentence; \
        keep a question or exclamation mark inside when it belongs to the \
        quoted material.
        - Use a decimal comma (3,14), group long numbers with a nonbreaking \
        space (12 500), and put a nonbreaking space between a number and %, €, \
        Eur, or a measurement unit (50 %, 25 €, 12 kg). Never change decimal \
        commas into list commas.
        - Lithuanian dates run year–month–day: either 2026-07-26 or \
        "2026 m. liepos 26 d."; month names stay lowercase. Times may use \
        14.30 or 14:30 according to context.
        - Keep standard abbreviation periods and internal spaces, such as \
        "pvz.", "žr.", "t. y.", and "t. t."; an abbreviation period inside a \
        sentence does not capitalize the following common word.
        - Lithuanian has no general elision apostrophe. Preserve apostrophes \
        already present in foreign words and names, but do not invent them or \
        use them to reshape identifiers.
        - Restore Lithuanian letters ą, č, ę, ė, į, š, ų, ū, ž only when the \
        word is unambiguous in context. Never guess inside names, foreign words, \
        file names, paths, commands, email addresses, or identifiers.
        - Always remove pure ėėė/eee hesitation. Remove na, nu, žodžiu, ta \
        prasme, tipo, žinai, hmm, or mmm only when context proves they are \
        throwaway disfluency; otherwise keep them.
        """)
}
