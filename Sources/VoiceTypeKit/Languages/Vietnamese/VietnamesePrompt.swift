import Foundation

extension LanguagePromptGuidance {
    /// Vietnamese-specific cleanup guidance for the on-device model.
    ///
    /// Few-shot examples are intentionally empty. Vietnamese has no isolated
    /// model-eval result showing that examples outweigh the known leakage risk;
    /// the instructions carry the policy without giving the model text to echo.
    static let vietnamese = LanguagePromptGuidance(
        fillerExamples: #": "ừm", "ờm", "ưm", "uhm", and "hmm"; also remove short "ừ", "ờ", "à", "ơ", "kiểu như", "ý là", or "nói chung là" ONLY when context proves they are hesitation with no conversational meaning. Keep acknowledgements, particles, and content uses"#,
        capitalizationRule: """
        Fix Vietnamese capitalization: capitalize the first syllable after a \
        sentence-ending period, question mark, or exclamation mark and at a new \
        line. Capitalize every syllable of Vietnamese personal names (Nguyễn Văn \
        An) and the proper-name elements of places and organizations. Preserve \
        established all-caps abbreviations and the exact casing of brands, file \
        names, identifiers, URLs, email addresses, and commands; do not title-case \
        ordinary Vietnamese words.
        """,
        codeRendering: """
        When context clearly shows Vietnamese tech dictation, compact the spoken \
        symbol names and leave ordinary prose alone:
        - File names and domains: "main chấm py" → main.py, "config chấm json" → \
        config.json, and "example chấm com" → example.com. Chấm is also an \
        ordinary Vietnamese word, so render it as a dot only in a known file, \
        domain, email, path, version, or numeric context.
        - Identifiers: "max gạch dưới retries" → max_retries. "Gạch ngang" or \
        "gạch nối" → - only when the speaker is spelling a handle, flag, path, \
        or identifier. Consume the spoken symbol words; never emit \
        max_gạch_dưới_retries.
        - Pairs and operators: "mở ngoặc x phẩy y đóng ngoặc" → (x, y); explicit \
        "dấu bằng", "dấu cộng", "dấu trừ", "dấu sao", "dấu thăng", "dấu gạch \
        đứng", "dấu gạch chéo ngược", and "dấu a còng" render as = + - * # | \\ @.
        - Preserve Vietnamese spaces in prose. Join only what the speaker marked; \
        "giá trị người dùng" stays three words, while "user gạch dưới id" becomes \
        user_id. Never strip Vietnamese diacritics from prose to make it look \
        like an identifier.
        """,
        terminalGuidance: """
        The user is dictating into a terminal, so Vietnamese symbol words often \
        name shell syntax:
        - "gạch ngang gạch ngang verbose" → --verbose, "gạch ngang m" → -m, \
        "dấu ngã gạch chéo projects" → ~/projects, and "chấm gạch chéo build" \
        → ./build.
        - Keep command names, flags, paths, environment variables, and identifiers \
        exactly cased and compact. Never capitalize the command and never append \
        sentence punctuation to a command.
        - A Vietnamese commit message or other clear prose dictated in the \
        terminal still keeps its natural words and punctuation; do not translate \
        it or rewrite it as shell syntax.
        """,
        codeEditorGuidance: """
        The user is dictating into a code editor. Prefer compact rendering for \
        explicit Vietnamese symbol phrases, known extensions, identifiers, and \
        function calls. Preserve the programming language's ASCII punctuation \
        and exact casing. Vietnamese comments, documentation, and commit text \
        remain normal spaced Vietnamese prose with full diacritics.
        """,
        selfCorrectionRule: """
        Resolve Vietnamese self-corrections by keeping only the replacement spoken \
        last. Markers include "à không", "không, ý tôi là", "không phải", "à \
        nhầm", and "xin lỗi": "đặt năm bản, à không, sáu bản" becomes "đặt sáu \
        bản". Do not delete lexical không when it is negation or a question \
        particle, and do not delete ý when it means an idea.
        """,
        addendum: """
        - Keep Vietnamese in precomposed Unicode with every diacritic. ASR often \
        confuses tones, close vowels/consonants, and regional pronunciations; \
        correct a spelling only when the full sentence makes the intended word \
        certain. Never guess between two meaningful Vietnamese words, erase \
        regional vocabulary, or remove diacritics from ordinary prose.
        - Vietnamese questions may use an initial or in-situ question phrase and \
        final particles such as không, chưa, à, ạ, ư, hả, nhỉ, or chứ. Decide \
        from the whole utterance: these same words also make statements and \
        acknowledgements, so do not add a question mark from one token alone.
        - Use ASCII . , ; : ? ! with no space before and one space after in prose. \
        Use paired typographic quotation marks “…” (and ‘…’ when nested), with no \
        inner spaces. Do not curl straight quotes or alter punctuation inside \
        code, identifiers, paths, URLs, or foreign text.
        - In clear Vietnamese prose, a comma is the decimal separator and a dot \
        groups thousands (1.234,56); dates are day/month/year (26/07/2026); the \
        currency follows the amount (100.000 ₫ or 100.000 đồng); percent attaches \
        to the number (75%). Preserve literal versions, IP addresses, source-code \
        numbers, and already explicit foreign formats instead of localizing them.
        - Vietnamese has no productive apostrophe elision. Do not insert \
        apostrophes into Vietnamese words; preserve them in foreign names, quoted \
        text, contractions, and code. Preserve established abbreviations such as \
        TP.HCM, UBND, CNTT, AI, and API; never invent or expand an abbreviation \
        unless the speaker did so.
        """)
}
