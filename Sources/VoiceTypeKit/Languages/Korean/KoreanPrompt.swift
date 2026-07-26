import Foundation

extension LanguagePromptGuidance {
    /// Korean-specific guidance for the on-device cleanup model.
    ///
    /// There are intentionally no few-shot examples. This task may not run the
    /// shared on-device model during parallel language work, so no Korean eval
    /// evidence justifies accepting the known example-echoing risk. The
    /// instructions and deterministic post-pass stand on their own.
    static let korean = LanguagePromptGuidance(
        fillerExamples: """
        : Korean filled pauses such as "어", "음", "으음", "그", "저", "뭐", \
        "이제", "막", and "그러니까" ONLY when context shows they merely hold \
        the floor. These forms can also be meaningful words, answers, \
        demonstratives, adverbs, or discourse markers; preserve them whenever \
        they contribute meaning or stance, and keep them when uncertain
        """,
        capitalizationRule: """
        Korean Hangul has no uppercase/lowercase distinction, so do not invent \
        sentence capitalization. Preserve the established casing of embedded \
        Latin names, brands, acronyms, file names, paths, commands, and \
        identifiers; change Latin casing only when the intended conventional \
        spelling is unambiguous
        """,
        codeRendering: """
        When the surrounding words clearly show that the speaker is dictating \
        code, a file name, an identifier, an email address, or a handle, render \
        Korean-spoken technical forms compactly and keep ordinary Korean prose \
        unchanged:
        - File-name dots: "메인 점 파이", "메인 닷 피와이" → main.py; \
        "콘피그 점 제이슨" → config.json. In this anchored context, 점/닷 \
        means `.`, and common spoken extensions such as 파이/피와이, 제이에스, \
        티에스, 제이슨, 스위프트, and 마크다운 take their conventional ASCII \
        spellings.
        - Identifiers: "유저 언더스코어 아이디" → user_id. Consume \
        언더스코어 as `_`; do not leave the trigger word in the identifier, \
        and do not join neighboring words unless the speaker explicitly named \
        a joiner or casing convention.
        - Symbols: 하이픈/대시 → `-`, 슬래시 → `/`, 틸드 → `~`, \
        골뱅이/앳 → `@`, 괄호 열기/닫기 or 여는/닫는 괄호 → `( )`, \
        and 여는/닫는 대괄호 → `[ ]` when code context is clear.
        - Keep a literal Korean content word when it is not a code trigger: \
        점 in "이 점이 중요하다", "백 점", or "세 시 반" is not `.`, and \
        ordinary 밑줄 is not an underscore command.
        - Preserve embedded code and English exactly; never translate an \
        existing identifier, path, API name, or file name into Korean.
        """,
        terminalGuidance: """
        The user is dictating into a terminal. Expect Korean speech mixed with \
        conventional lowercase command, flag, branch, and path spellings:
        - Render spoken flags: "대시 브이" → -v and "대시 대시 버보스" → \
        --verbose. Render paths: "틸드 슬래시 프로젝트" → ~/projects, \
        "점 슬래시 빌드" → ./build, and consume every spoken separator.
        - Normalize unmistakable command names and subcommands to their real \
        spelling ("깃 스테이터스" → git status), but never translate or guess \
        a user-defined argument, file, branch, environment variable, or path.
        - Shell commands remain lowercase where convention requires, retain \
        exact `-`, `--`, `/`, `.`, `_`, `~`, quotes, and casing, and never gain \
        a trailing sentence mark.
        - If the terminal dictation is clearly prose, such as a Korean commit \
        message, clean it as Korean prose without changing its words.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Bias toward conventional \
        source spelling only when code intent is explicit: render identifiers, \
        file names, extensions, brackets, and symbols compactly, and keep \
        existing Latin casing exact. Korean comments, documentation, commit \
        text, and string content remain natural Korean prose; do not translate \
        them, turn them into identifiers, or alter meaningful whitespace inside \
        code and strings.
        """,
        selfCorrectionRule: """
        Resolve Korean self-corrections by keeping the replacement spoken LAST \
        and removing only the abandoned words plus the correction cue: \
        "다섯 개, 아니 여섯 개" → "여섯 개", and "수요일, 아니고 목요일 \
        오후" → "목요일 오후". Treat 아니/아니고, 잠깐, 정정할게, and \
        다시 말하면 as correction cues only when an actual replacement \
        follows; otherwise they are content and must remain
        """,
        addendum: """
        - Apply standard Korean spacing contextually. Attach particles and verb \
        endings to their hosts; space independent and dependent nouns where \
        required. Korean spacing is morphologically ambiguous, so repair only \
        high-confidence ASR splits/merges and never infer a word boundary from \
        an acoustic pause alone.
        - Use modern horizontal Korean punctuation: no space before `. , ? ! \
        : ;`; opening quotation/bracket marks attach to following text and \
        closing marks attach to preceding text. Prefer Korean curved quotation \
        marks “ ” and ‘ ’ in prose, while preserving ASCII quotes in code.
        - Preserve conventional numeric typography: decimal point and \
        three-digit grouping comma (`1,234.5`), currency symbol before a number \
        (`₩1,000`), percent sign attached (`10%`), and Korean dates such as \
        `2026년 7월 26일`. Do not convert number words to digits unless the \
        speaker clearly dictated a numeric written form.
        - Korean has no orthographic elision apostrophe and no native \
        capitalization. Preserve apostrophes and letter case only where they \
        belong to foreign names, abbreviations, code, identifiers, or quoted \
        source text.
        - Correct obvious ASR spacing and a misrecognized homophone only when \
        the sentence makes the intended Korean form certain. Preserve dialect, \
        politeness level, sentence ending, fragments, and the speaker's lexical \
        choices; never formalize casual speech or replace it with synonyms.
        - Questions may be marked by sentence-final endings rather than an \
        initial question word. Add `?` when the full Korean syntax/intended \
        reading is interrogative, including questions whose topic comes first; \
        do not assume that every final `-요`, `-지`, `-니`, or wh-form is a \
        question.
        """)
}
