import Foundation

/// The words one language uses to *speak* a symbol out loud, plus the small
/// lexicons the renderer needs to decide when a join is safe.
///
/// `SpokenSymbols` is the shared token pipeline — the conservative
/// neighbor rules that stop "the dot product" becoming "the.product" are the
/// same in every language. This struct is the part that isn't: the trigger
/// words themselves. A language supplies one of these to opt into spoken-symbol
/// rendering; a pack with `symbols == nil` skips the pipeline entirely, which
/// is what every language except English does today.
///
/// Trigger sets are matched lowercased, so entries must be lowercase.
public struct SpokenSymbolVocabulary: Sendable {
    /// "dot" / "period" — joins file extensions and path prefixes.
    public let dot: Set<String>
    /// "underscore" — joins identifier parts.
    public let underscore: Set<String>
    /// "dash" / "hyphen" — handles outside a terminal, flags inside one.
    public let dash: Set<String>
    /// "slash" — path separator (terminal only).
    public let slash: Set<String>
    /// "tilde" — home-directory prefix (terminal only).
    public let tilde: Set<String>
    /// "comma" — a literal comma when spoken inside an open paren.
    public let comma: Set<String>
    /// The word separating an email local part from its domain ("at").
    public let emailAt: Set<String>

    /// "open" / "close", paired with a bracket noun below.
    public let openers: Set<String>
    public let closers: Set<String>
    /// Nouns that follow an opener/closer: "paren", "parens", "parenthesis".
    public let parenNouns: Set<String>
    /// "bracket", "brackets".
    public let bracketNouns: Set<String>

    /// File extensions safe to join after a spoken dot. Keep to common,
    /// unambiguous ones — anything else stays prose.
    public let fileExtensions: Set<String>
    /// Transcriber homophones for those extensions ("pie" → "py").
    public let extensionHomophones: [String: String]
    /// Top-level domains that anchor the spoken-email pattern.
    public let emailTLDs: Set<String>

    /// Function words that must never be joined into an identifier — the guard
    /// that keeps "I want to underscore the importance" as prose. Normally the
    /// pack's own `stopwords`.
    public let joinGuards: Set<String>
    /// Words that read as prose before the email "at" ("look at gmail dot
    /// com" is a sentence, not an address).
    public let emailLocalGuards: Set<String>

    public init(dot: Set<String>,
                underscore: Set<String>,
                dash: Set<String>,
                slash: Set<String>,
                tilde: Set<String>,
                comma: Set<String>,
                emailAt: Set<String>,
                openers: Set<String>,
                closers: Set<String>,
                parenNouns: Set<String>,
                bracketNouns: Set<String>,
                fileExtensions: Set<String>,
                extensionHomophones: [String: String],
                emailTLDs: Set<String>,
                joinGuards: Set<String>,
                emailLocalGuards: Set<String>) {
        self.dot = dot
        self.underscore = underscore
        self.dash = dash
        self.slash = slash
        self.tilde = tilde
        self.comma = comma
        self.emailAt = emailAt
        self.openers = openers
        self.closers = closers
        self.parenNouns = parenNouns
        self.bracketNouns = bracketNouns
        self.fileExtensions = fileExtensions
        self.extensionHomophones = extensionHomophones
        self.emailTLDs = emailTLDs
        self.joinGuards = joinGuards
        self.emailLocalGuards = emailLocalGuards
    }
}
