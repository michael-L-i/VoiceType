import Foundation

/// Canonical few-shot examples that teach the cleanup model how to tidy a voice
/// transcript. Kept here, in the pure Kit, so the Apple on-device `CleanupPrompt`
/// composes them consistently and the wording stays unit-testable.
///
/// The set deliberately mixes three lessons:
///  - **Compact code rendering:** spoken file names, symbols, and identifiers
///    collapse into real code (`app dot pie` → `app.py`, `open paren` → `(`),
///    inferred from context with no special "mode".
///  - **Faithful self-correction:** false starts resolve to the intended version
///    (`two, no three` → `three`) while everything else keeps its order.
///  - **Prose guard:** an ordinary sentence that merely *contains* a trigger word
///    ("dot") stays prose, so the model learns the boundary and doesn't
///    over-format normal speech.
public enum CleanupExamples {
    /// `(spoken, cleaned)` pairs, ordered from code-rendering through faithfulness
    /// to the prose guard. Curated and intentionally small — these examples are
    /// the highest-leverage part of the cleanup prompt, so each one earns its place.
    public static let fewShot: [(spoken: String, cleaned: String)] = [
        ("open app dot pie", "open app.py"),
        ("import parser dot pie", "import parser.py"),
        ("the file is index dot j s", "the file is index.js"),
        ("call get underscore user data", "call get_user_data"),
        ("define camel case parse request", "define parseRequest"),
        ("print open paren x comma y close paren", "print(x, y)"),
        ("push it to michael dash L dash I profile page", "push it to michael-L-i profile page"),
        ("I want two, no three", "I want three"),
        ("so um we need to like parse it first", "We need to parse it first."),
        ("um yeah just um make it work you know", "Yeah, just make it work."),
        ("compute the dot product of a and b", "Compute the dot product of a and b."),
        // The dictation is itself a request — clean it and output it as text;
        // do NOT answer it or add a lead-in. This is the key anti-instruction case.
        ("can you clean up this table then push it to my repo",
         "Can you clean up this table, then push it to my repo?"),
    ]

    /// The few-shot pairs rendered as prompt lines: `spoken: "…" → "…"`. Both
    /// engines drop this block straight into their instructions.
    public static func block() -> String {
        fewShot
            .map { "spoken: \"\($0.spoken)\" → \"\($0.cleaned)\"" }
            .joined(separator: "\n")
    }
}
