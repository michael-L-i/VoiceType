import Foundation

extension LanguagePack {
    /// Japanese (keyed on "ja").
    ///
    /// Ambiguity policy — what this pack deliberately does NOT touch:
    /// - あの / その / ええ / まあ / なんか / うーん / そうですね can be
    ///   discourse content, deixis, agreement, uncertainty, or stance. Only
    ///   unmistakable えっと-family hesitations and the drawn-out あのー are
    ///   deterministic fillers; contextual removals belong to the LLM.
    /// - 点 / まる / ダッシュ are ordinary words as well as symbol names.
    ///   They never undergo blind replacement. Code-shaped utterances use the
    ///   guarded vocabulary in JapaneseSymbols.swift; ambiguous prose stays
    ///   untouched.
    /// - Bare sentence-final か also occurs in exclamations, invitations, and
    ///   self-talk (そうか / 行こうか). Only longer endings that unambiguously
    ///   form a question opt into the deterministic question heuristic.
    /// - Horizontal Japanese admits both 「、。」 and the consistent
    ///   technical/publication styles 「，。」 or 「，．」. We prefer 「、。」
    ///   for newly rendered Japanese punctuation but do not rewrite an
    ///   existing document's consistent comma/period style.
    /// - Quotation marks, numeric kanji versus Arabic digits, era versus
    ///   Gregorian dates, and ¥ versus 円 all depend on register or context.
    ///   The prompt gives the model the conventions and tells it not to guess;
    ///   deterministic rules preserve the speaker/transcriber's choice.
    /// - Homophonic kanji and proper-name spellings are a major Japanese ASR
    ///   failure mode, but no context-free correction is safe. The prompt may
    ///   repair only a contextually certain error and otherwise preserves it.
    static let japanese = LanguagePack(
        code: "ja",
        separatesWordsWithSpaces: false,
        usesFullWidthPunctuation: true,
        terminalPeriod: "。",
        fillers: [
            "えーと", "ええと", "えっと", "えーっと", "ええっと",
            "あのー", "あのう",
        ],
        // Direct dictation commands only. Ambiguous short names such as 点,
        // まる, ドット, and ダッシュ are deliberately absent.
        spokenPunctuation: [
            "句点": "。",
            "読点": "、",
            "疑問符": "？",
            "感嘆符": "！",
            "中黒": "・",
            "三点リーダー": "……",
            "三点リーダ": "……",
            "二点リーダー": "‥‥",
            "二点リーダ": "‥‥",
            "開き二重かぎ括弧": "『",
            "閉じ二重かぎ括弧": "』",
            "二重かぎ括弧開く": "『",
            "二重かぎ括弧閉じる": "』",
            "開きかぎ括弧": "「",
            "閉じかぎ括弧": "」",
            "かぎ括弧開く": "「",
            "かぎ括弧閉じる": "」",
            "円記号": "¥",
            "ドル記号": "$",
            "ユーロ記号": "€",
            "英ポンド記号": "£",
            "パーセント記号": "%",
            "改行": "\n",
        ],
        questionPrefixWords: [],
        questionSuffixParticles: [
            "ですか", "ますか", "ませんか", "でしょうか", "だろうか",
            "のですか", "んですか",
        ],
        questionMark: "？",
        stopwords: JapanesePackData.stopwords,
        prompt: .japanese,
        rules: [
            .renderJapaneseSpokenSymbols,
            .japaneseBracketSpacing,
            .japaneseDividingMarkSpacing,
        ],
        spokenSymbolWords: JapanesePackData.spokenSymbolWords,
        modelLeadInPatterns: JapanesePackData.modelLeadInPatterns)
}

enum JapanesePackData {
    /// Conservative function-word guards for spaced mixed Japanese/code input.
    /// Ordinary Japanese has no word spaces, so these matter mainly when an ASR
    /// engine emits `max アンダースコア retries`-style token boundaries.
    static let stopwords: Set<String> = [
        "は", "が", "を", "に", "へ", "と", "で", "の", "も", "や", "か",
        "から", "まで", "より", "です", "ます", "する", "した", "して",
        "これ", "それ", "あれ", "この", "その", "あの", "ここ", "そこ",
        "そして", "でも",
    ]

    static let spokenSymbolWords: Set<String> = [
        "ドット", "アンダースコア", "アンダーバー", "ハイフン",
        "スラッシュ", "バックスラッシュ", "チルダ", "カンマ",
        "アットマーク", "開き", "閉じ", "丸括弧", "丸かっこ",
        "角括弧", "角かっこ", "キャメルケース", "大文字", "小文字",
        "改行", "タブ", "スペース",
    ]

    /// Japanese variants of the assistant-style wrapper the small model may
    /// add despite the shared "output only the transcript" contract.
    static let modelLeadInPatterns = [
        #"^\s*(?:はい|もちろん|承知しました|了解しました)[、。！,\s]*(?:こちら(?:が|は)|以下(?:が|は))?[^：:\n]{0,40}(?:修正|整え|清書|クリーンアップ)(?:した|済みの)?(?:文章|テキスト|文字起こし|音声入力)[^：:\n]{0,20}[：:]\s*"#,
        #"^\s*(?:こちら(?:が|は)|以下(?:が|は))?[^：:\n]{0,30}(?:修正|整え|清書|クリーンアップ)(?:した|済みの)?(?:文章|テキスト|文字起こし|音声入力)[^：:\n]{0,20}[：:]\s*"#,
    ]
}

private extension CleanupRule {
    /// Japanese brackets are set solid: literal ASCII whitespace immediately
    /// inside 「」/『』/【】, or between those brackets and adjacent Japanese
    /// text, is an ASR artifact rather than typographic spacing.
    static let japaneseBracketSpacing = CleanupRule.regex(
        name: "Japanese bracket spacing",
        stage: .afterPunctuation,
        pattern: #"(?<=[「『【])[ \t]+|[ \t]+(?=[」』】])|(?<=[\p{Han}\p{Hiragana}\p{Katakana}])[ \t]+(?=[「『【])|(?<=[」』】])[ \t]+(?=[\p{Han}\p{Hiragana}\p{Katakana}])"#,
        template: "")

    /// In Japanese composition, a question/exclamation mark that ends a
    /// sentence takes a one-em space before another sentence, except when a
    /// closing bracket follows immediately. CJKPunctuation intentionally
    /// removes generic CJK spacing first; this language rule restores the
    /// Japanese convention with an ideographic space.
    static let japaneseDividingMarkSpacing = CleanupRule.regex(
        name: "Japanese space after question or exclamation mark",
        stage: .afterPunctuation,
        pattern: #"([！？])(?=[\p{L}\p{N}「『（【])"#,
        template: "$1\u{3000}")
}
