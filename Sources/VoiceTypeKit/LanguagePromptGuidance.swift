import Foundation

/// The parts of the LLM cleanup instruction that are about *this language*
/// rather than about the job.
///
/// The instruction frame stays English and shared — a small on-device model
/// follows English instructions more reliably, and the rules it must obey
/// (don't summarize, don't answer the dictation, don't reformat into bullets)
/// are identical in every language. What differs is the substance: which
/// sounds are hesitations, how the orthography capitalizes, which words a
/// speaker uses to dictate a symbol. That lives here, next to the pack.
///
/// Every field is optional. A nil field means "this language hasn't said" and
/// the prompt falls back to a language-neutral instruction, or omits the
/// section entirely — never to English's answer.
public struct LanguagePromptGuidance: Sendable {
    /// Appended to the generic filler instruction, e.g.
    /// `: "um", "uh", … when they carry no meaning`. Include the leading
    /// punctuation; the prompt supplies the trailing period.
    public let fillerExamples: String?

    /// Replaces the generic capitalization instruction wholesale, for
    /// orthographies whose rule genuinely differs — German capitalizes every
    /// noun, Turkish has a dotted/dotless I, Devanagari has no case at all.
    public let capitalizationRule: String?

    /// The spoken-code rendering section ("dot" → `.`, "camel case parse
    /// request" → parseRequest). Entirely language-specific: the trigger words
    /// are words. Omitted from the prompt when nil.
    public let codeRendering: String?

    /// Extra guidance when the user is dictating into a terminal — spoken
    /// flags and paths. Omitted when nil.
    public let terminalGuidance: String?

    /// True when this language ships few-shot examples worth including.
    /// Off by default: eval showed the model echoing example content into its
    /// output, so a language only opts in once its own eval battery shows the
    /// examples earn their place.
    public let usesFewShotExamples: Bool

    /// Free-form extra rules — full-width punctuation for Chinese, ¿…? for
    /// Spanish, which hesitations to drop. Keep minimal; prompt content leaks.
    public let addendum: String?

    public init(fillerExamples: String? = nil,
                capitalizationRule: String? = nil,
                codeRendering: String? = nil,
                terminalGuidance: String? = nil,
                usesFewShotExamples: Bool = false,
                addendum: String? = nil) {
        self.fillerExamples = fillerExamples
        self.capitalizationRule = capitalizationRule
        self.codeRendering = codeRendering
        self.terminalGuidance = terminalGuidance
        self.usesFewShotExamples = usesFewShotExamples
        self.addendum = addendum
    }

    /// A language that has contributed nothing beyond an addendum.
    public static func addendumOnly(_ text: String) -> LanguagePromptGuidance {
        LanguagePromptGuidance(addendum: text)
    }

    /// Nothing said — generic instructions, no code section.
    public static let none = LanguagePromptGuidance()
}
