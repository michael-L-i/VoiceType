import Foundation

extension LanguagePack {
    /// Spanish. Question openers are interrogative words ONLY: Spanish yes/no
    /// questions don't invert ("¿es bueno?" reads like "es bueno"), so verbs
    /// would misfire on plain statements. The deterministic rule appends "?"
    /// without the opening "¿" — half-right beats wrong, and informal Spanish
    /// routinely omits it. "este"/"o sea"/"pues" are real words as often as
    /// hesitations, so they stay (LLM territory).
    static let spanish = LanguagePack(
        code: "es",
        separatesWordsWithSpaces: true,
        usesFullWidthPunctuation: false,
        terminalPeriod: ".",
        fillers: ["eh", "em", "mmm", "ehm"],
        spokenPunctuation: [:],
        questionPrefixWords: [
            "qué", "quién", "quiénes", "cuándo", "cuánto", "cuánta",
            "cuántos", "cuántas", "dónde", "adónde", "cómo", "cuál", "cuáles",
        ],
        questionSuffixParticles: [],
        promptAddendum: """
        - Spanish questions and exclamations use opening marks too: write \
        ¿…? and ¡…! around them.
        """)
}
