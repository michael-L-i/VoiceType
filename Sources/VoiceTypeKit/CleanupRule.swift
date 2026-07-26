import Foundation

/// One language's own deterministic text fix, written inside its pack.
///
/// The pack's declarative fields (fillers, spoken punctuation, question words)
/// answer a fixed set of questions. Every language also has conventions those
/// questions don't ask about — French writes `Bonjour !` with a space before
/// the mark, Spanish opens a question with `¿`, Turkish uppercases `i` to `İ`.
/// A rule is where those live, so the shared engine never has to learn the
/// word "French" and a language can be improved without touching shared code.
///
/// Rules are pure `String -> String` functions. They run in both cleanup
/// paths — the deterministic `RuleBasedCleanup` floor and `CleanupPolish`'s
/// repair of model output — so a language's orthography holds however the text
/// was produced.
public struct CleanupRule: Sendable {
    /// Where in the shared pipeline a rule runs. Both paths honor all three,
    /// in this order, so a rule behaves the same whichever engine produced the
    /// text.
    public enum Stage: Sendable, Equatable, CaseIterable {
        /// Before any shared pass — raw-ish text, straight from the
        /// transcriber or the model. For repairing engine quirks.
        case early
        /// After punctuation spacing and width normalization. This is where a
        /// convention the shared pass would otherwise flatten belongs: the
        /// Latin rule strips whitespace before `;:!?`, so French restores it
        /// here rather than fighting for it earlier.
        case afterPunctuation
        /// Last, after capitalization and terminal punctuation. For rules that
        /// need to see the finished sentence.
        case final
    }

    /// Identifies the rule in tests and review. Not user-visible.
    public let name: String
    public let stage: Stage

    /// Terminal dictation is usually a shell command, where a "correction" is
    /// corruption: `git status` must never gain a capital, a period, or a
    /// typographic space. Rules therefore sit out the terminal category unless
    /// they opt in — the same conservative bias the rest of the engine uses.
    public let runsInTerminal: Bool

    private let transform: @Sendable (String, CleanupContext) -> String

    public init(name: String,
                stage: Stage,
                runsInTerminal: Bool = false,
                transform: @escaping @Sendable (String, CleanupContext) -> String) {
        self.name = name
        self.stage = stage
        self.runsInTerminal = runsInTerminal
        self.transform = transform
    }

    /// Apply the rule, honoring its terminal opt-out.
    public func apply(_ text: String, context: CleanupContext) -> String {
        guard runsInTerminal || context.category != .terminal else { return text }
        return transform(text, context)
    }

    // MARK: - Building blocks

    /// A regex substitution, the shape most orthographic rules take. Returns
    /// the text unchanged if the pattern doesn't compile, so a typo in a pack
    /// degrades to "no rule" rather than crashing a dictation.
    public static func regex(name: String,
                             stage: Stage,
                             runsInTerminal: Bool = false,
                             pattern: String,
                             template: String,
                             options: NSRegularExpression.Options = []) -> CleanupRule {
        CleanupRule(name: name, stage: stage, runsInTerminal: runsInTerminal) { text, _ in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
                return text
            }
            let range = NSRange(text.startIndex..., in: text)
            return regex.stringByReplacingMatches(in: text, options: [],
                                                  range: range, withTemplate: template)
        }
    }
}

extension Array where Element == CleanupRule {
    /// Run every rule for one stage, in declaration order. The pack author
    /// controls ordering by how they list them.
    func applying(_ stage: CleanupRule.Stage,
                  to text: String,
                  context: CleanupContext) -> String {
        reduce(text) { current, rule in
            rule.stage == stage ? rule.apply(current, context: context) : current
        }
    }
}
