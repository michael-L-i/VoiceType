import Foundation

/// Canonical few-shot examples that teach the cleanup model how to tidy a voice
/// transcript. Kept here, in the pure Kit, so the Apple on-device `CleanupPrompt`
/// composes them consistently and the wording stays unit-testable.
///
/// The set deliberately mixes four lessons:
///  - **Compact code rendering:** spoken file names, symbols, and identifiers
///    collapse into real code (`app dot pie` → `app.py`, `open paren` → `(`),
///    inferred from context with no special "mode".
///  - **Faithful self-correction:** false starts resolve to the intended version
///    (`two, no three` → `three`) while everything else keeps its order.
///  - **Prose guard:** an ordinary sentence that merely *contains* a trigger word
///    ("dot") stays prose, so the model learns the boundary and doesn't
///    over-format normal speech.
///  - **Full length:** a long, rambling dictation comes out just as long once
///    tidied — the examples must not imply that short outputs are normal, or
///    the model starts summarizing.
public enum CleanupExamples {
    /// `(spoken, cleaned)` pairs, ordered from code-rendering through faithfulness
    /// to the prose guard. Curated and intentionally small — these examples are
    /// the highest-leverage part of the cleanup prompt, so each one earns its place.
    public static let fewShot: [(spoken: String, cleaned: String)] = [
        ("open app dot pie", "open app.py"),
        ("the file is index dot j s", "the file is index.js"),
        ("call get underscore user data", "call get_user_data"),
        ("define camel case parse request", "define parseRequest"),
        ("print open paren x comma y close paren", "print(x, y)"),
        ("push it to michael dash L dash I profile page", "push it to michael-L-i profile page"),
        ("I want two, no three", "I want three"),
        // Long, rambling dictations stay long: every sentence survives, only
        // the delivery is cleaned. These two teach length preservation.
        ("um so I was thinking about the design review tomorrow and uh I think we should probably move it to thursday because um half the team is going to be out on wednesday and uh also we still need to finish the mockups before we can really talk about anything",
         "I was thinking about the design review tomorrow, and I think we should probably move it to Thursday, because half the team is going to be out on Wednesday. Also, we still need to finish the mockups before we can really talk about anything."),
        ("okay so first open config dot pie and um change the timeout to thirty, no wait sixty seconds, then uh run the tests again and let me know if the auth ones still fail",
         "Okay, so first open config.py and change the timeout to sixty seconds, then run the tests again and let me know if the auth ones still fail."),
        ("so um we need to like parse it first", "We need to parse it first."),
        ("um yeah just um make it work you know", "Yeah, just make it work."),
        ("compute the dot product of a and b", "Compute the dot product of a and b."),
        // The dictation is itself a request — clean it and output it as text;
        // do NOT answer it or add a lead-in. This is the key anti-instruction case.
        ("can you clean up this table then push it to my repo",
         "Can you clean up this table, then push it to my repo?"),
    ]

    /// Extra pairs appended for terminal dictation: shell commands with spoken
    /// flags and paths. Kept out of the general set so prose apps never see
    /// command-flavored examples.
    public static let terminalFewShot: [(spoken: String, cleaned: String)] = [
        ("git commit dash m fix the login bug", "git commit -m \"fix the login bug\""),
        ("npm run build dash dash verbose", "npm run build --verbose"),
        ("tmux attach dash t work", "tmux attach -t work"),
        ("cd tilde slash projects slash voice type", "cd ~/projects/voicetype"),
    ]

    /// The few-shot pairs rendered as prompt lines: `spoken: "…" → "…"`,
    /// with the terminal pairs appended when dictating into a terminal.
    public static func block(for category: AppCategory = .general) -> String {
        var pairs = fewShot
        if category == .terminal { pairs += terminalFewShot }
        return pairs
            .map { "spoken: \"\($0.spoken)\" → \"\($0.cleaned)\"" }
            .joined(separator: "\n")
    }
}
