import Foundation

extension LanguagePromptGuidance {
    /// Turkish guidance for the on-device cleanup model. Examples remain empty
    /// intentionally: Turkish has no model-eval run proving that few-shot
    /// content earns its leakage risk.
    static let turkish = LanguagePromptGuidance(
        fillerExamples: #": always remove non-lexical "ıı", "ııı", and longer ıı… pauses; remove "ee/eee", "şey", "yani", "işte", "falan/filan", "hımm", or "hmm" ONLY when context shows pure hesitation. These words can carry real meaning in Turkish, so keep them when meaningful and keep them when unsure"#,
        capitalizationRule: """
        Fix Turkish capitalization using Turkish casing: sentence-initial i \
        becomes İ (not I), while ı becomes I. Capitalize proper names and \
        specific dates/holidays as Turkish requires, but do not change the \
        spelling or case of embedded code, commands, paths, file names, email \
        addresses, handles, or identifiers
        """,
        codeRendering: """
        When context clearly says the speaker is dictating code, a file name, \
        an identifier, an email address, or a handle, render Turkish spoken \
        symbol names compactly and keep ordinary prose untouched:
        - "main nokta swift" → main.swift; "config nokta ceyson" → config.json. \
        A known extension after "nokta" joins to the preceding name.
        - "max alt çizgi retries" → max_retries; "michael tire l tire i" → \
        michael-l-i. Consume the spoken joiner; never write \
        max_alt_çizgi_retries.
        - "aç parantez"/"parantez aç" and "kapat parantez"/"parantez kapat" \
        become ( and ); "aç köşeli parantez" / "kapat köşeli parantez" become \
        [ and ]; "virgül" inside them becomes ,.
        - In an email-shaped sequence, "et" or "kuyruklu a" becomes @ and \
        "nokta" becomes .; keep the address in ASCII.
        - These trigger words are ambiguous in prose: "önemli bir nokta", \
        "alt çizgi", "et almak", and "bir tire" stay words unless their \
        technical surroundings make the symbol intent clear.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Expect Turkish around literal \
        shell commands, flags, and paths:
        - "tire tire verbose" → --verbose and "tire v" → -v.
        - "tilde eğik çizgi projeler" → ~/projeler, "nokta eğik çizgi build" \
        → ./build, and spoken "eğik çizgi" joins path components.
        - Keep commands, flags, paths, environment variables, and program names \
        exactly cased and spelled; never translate command keywords, capitalize \
        the command's first token, add Turkish suffixes to it, or append a \
        sentence-ending period.
        - Prose that is clearly a commit message or chat sentence still follows \
        normal Turkish punctuation and capitalization.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Prefer compact symbol/file/
        identifier rendering when the words clearly describe code. Preserve \
        programming keywords and existing ASCII identifiers exactly; never \
        translate them or apply Turkish dotted/dotless-I casing inside them. \
        Comments, documentation, and other Turkish prose still use normal \
        Turkish orthography.
        """,
        selfCorrectionRule: """
        Resolve Turkish self-corrections by keeping only the replacement spoken \
        last: "beş, hayır altı kopya" → "altı kopya". Markers such as "hayır", \
        "yok", "pardon", "daha doğrusu", and "şey değil" signal a correction \
        only when the speaker retracts nearby words; otherwise they are content \
        and must remain.
        """,
        addendum: """
        - Use Turkish punctuation and typography. Marks attach to the preceding \
        word and take one following space. Use curly double quotation marks \
        “…” and nested single marks ‘…’; punctuation belonging to a quotation \
        stays inside its closing mark.
        - Turkish decimals use a comma and thousands groups use a period: \
        15,2 and 1.500.000. Times use a period (17.30); numeric dates may use \
        periods or slashes (29.10.1923 or 29/10/1923). Do not reinterpret an \
        existing ambiguous separator without context.
        - Put % and ‰ before the number with no space (%25, ‰5). Put the Turkish \
        lira sign before the amount with no space (₺125,50); do not emit both ₺ \
        and TL for the same amount.
        - Write the question particle mı/mi/mu/mü separately from the preceding \
        word, while joining its own following suffix: "geliyor musun", "gelecek \
        miydi". Use ? only for a real direct question; the particle also occurs \
        in non-question constructions.
        - Use the Turkish apostrophe ’ between a proper name or suitable \
        abbreviation and its suffix (Ankara’ya, TDK’ye), with suffix spelling \
        determined by pronunciation. Do not add it after full institution names \
        such as "Türk Dil Kurumuna", and do not alter apostrophes inside embedded \
        English or code.
        - Preserve every Turkish stem, negation, tense, evidential, person, and \
        case suffix. Turkish is highly agglutinative; never split a valid word, \
        discard a suffix, or replace it with a guessed shorter form. Preserve \
        ı/İ, i/I, ç, ğ, ö, ş, and ü.
        """)
}
