import Foundation

extension LanguagePromptGuidance {
    /// Japanese guidance is intentionally example-free. The shared model has
    /// leaked few-shot content into output before; these rules are explicit
    /// enough without giving it phrases to imitate.
    static let japanese = LanguagePromptGuidance(
        fillerExamples: """
        : Japanese hesitation forms such as 「えーと」「えっと」「あのー」 and \
        elongated variants. Remove 「あの」「その」「なんか」「まあ」\
        「そうですね」「うーん」 only when context makes them empty hesitation; \
        keep them when they express deixis, agreement, uncertainty, transition, \
        or stance
        """,
        capitalizationRule: """
        Japanese has no sentence capitalization. Do not change kana or kanji for \
        capitalization. Preserve the established case of embedded Latin names, \
        acronyms, URLs, file names, commands, and identifiers (AI, API, GitHub, \
        main.py); never title-case a Latin token merely because it starts a \
        Japanese sentence.
        """,
        codeRendering: """
        When Japanese speech clearly dictates code, a file name, an identifier, \
        an email address, or a handle, render the technical run compactly in \
        half-width ASCII while leaving ordinary Japanese prose alone:
        - 「main ドット パイ」→ main.py, 「config ドット ジェイソン」→ \
        config.json, and 「max アンダースコア retries」→ max_retries. \
        Consume the spoken joiner; never output mainドットpy or \
        max_アンダースコア_retries.
        - Render 「ハイフン」「スラッシュ」「バックスラッシュ」「チルダ」\
        「アットマーク」 and bracket names as ASCII -, /, \\, ~, @, ( ), [ ] \
        only when the surrounding run is technical. Code punctuation is never \
        full-width.
        - Join only words the speaker explicitly connected. 「session token」\
        stays separate; 「session アンダースコア token」 becomes session_token. \
        Preserve established identifier case and do not translate identifiers.
        - A symbol word in ordinary language stays a word: 「ドット柄」 is not \
        「.柄」, and a discussion of a slash or hyphen is not silently rewritten.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Prefer exact shell syntax and \
        half-width ASCII:
        - 「ハイフン ハイフン verbose」→ --verbose, 「ハイフン m」→ -m, \
        「チルダ スラッシュ projects」→ ~/projects, and \
        「ドット スラッシュ build」→ ./build.
        - Restore an unmistakable command or option to its conventional ASCII \
        spelling when ASR emitted katakana (for example ギット→git or \
        シーディー→cd), but never guess a project-specific command, path, branch, \
        proper name, or identifier.
        - Commands stay exactly cased, gain no Japanese punctuation or spaces, \
        and never receive a trailing 。 A clearly dictated Japanese commit \
        message or other prose still uses normal Japanese punctuation.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Bias clearly technical runs \
        toward compact half-width file names, symbols, and identifiers, while \
        keeping Japanese comments and documentation as natural Japanese prose \
        with Japanese punctuation. Preserve string literals, proper names, API \
        names, and identifier case; never translate them.
        """,
        selfCorrectionRule: """
        Resolve Japanese self-corrections only when the speaker clearly retracts \
        an earlier phrase with markers such as 「いや」「違う」「じゃなくて」\
        「ではなく」「訂正」: keep the replacement spoken last and remove the \
        retracted words. Do not treat contrastive 「ではなく」, a meaningful \
        「やっぱり」, or ordinary negation as a correction when no retraction is \
        clear.
        """,
        addendum: """
        - Write ordinary horizontal Japanese without word spaces, using Japanese \
        punctuation 「、。！？」. When a new sentence follows ？ or ！ on the same \
        line, leave one full-width space; do not put that space before a closing \
        bracket.
        - Use 「」 for an ordinary Japanese quotation and 『』 for a quotation \
        nested inside it or a title when context calls for that convention. Keep \
        ASCII quotes and apostrophes inside code, identifiers, and embedded \
        Western-language text. Japanese itself has no capitalization or \
        apostrophe-based elision.
        - Use paired Japanese leaders …… or ‥‥ for an intentional ellipsis. Do \
        not replace the katakana prolonged sound mark ー or repeated middle dots \
        in names with an ellipsis.
        - For clearly dictated horizontal numeric data, preserve the exact value \
        and use readable Japanese forms such as 2026年7月26日, 1,234.56, 1,000円, \
        or ¥1,000. Group long Arabic numerals by three digits with ASCII commas \
        and use an ASCII decimal point. Keep 万・億・兆, kanji numerals, era years, \
        and words like 数十 when the speaker chose them; never infer or convert an \
        ambiguous number, date, unit, or currency.
        - Preserve established Latin abbreviations and brand/API spelling (AI, \
        URL, VoiceType, GitHub) without expansion, translation, katakana \
        conversion, or sentence-start capitalization.
        - Japanese ASR often confuses homophonic kanji and low-frequency proper \
        nouns. Correct a kana/kanji conversion only when the surrounding sentence \
        makes one reading unquestionably intended. Never guess the kanji of a \
        person's name or replace an unfamiliar product, file, or identifier.
        """)
}
