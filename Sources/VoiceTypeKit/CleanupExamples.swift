import Foundation

/// One few-shot pair: what the speaker said, and exactly what the model should
/// output. A language owns its own set (`LanguagePromptGuidance.fewShot`);
/// `CleanupExamples` below is English's, which is the only set to have been
/// through an eval battery.
public struct CleanupExample: Sendable, Equatable {
    public let spoken: String
    public let cleaned: String

    public init(spoken: String, cleaned: String) {
        self.spoken = spoken
        self.cleaned = cleaned
    }
}

/// English's canonical few-shot examples, teaching the cleanup model how to
/// tidy a voice transcript. Kept here, in the pure Kit, so `CleanupPrompt`
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
///
/// Another language ships its own set in its own pack; nothing here is
/// automatically sent to it.
public enum CleanupExamples {
    /// Ordered from code-rendering through faithfulness to the prose guard.
    /// Curated and intentionally small — these examples are the highest-leverage
    /// part of the cleanup prompt, so each one earns its place.
    public static let fewShot: [CleanupExample] = [
        CleanupExample(spoken: "open app dot pie",
                        cleaned: "open app.py"),
        CleanupExample(spoken: "the file is index dot j s",
                        cleaned: "the file is index.js"),
        CleanupExample(spoken: "call get underscore user data",
                        cleaned: "call get_user_data"),
        CleanupExample(spoken: "define camel case parse request",
                        cleaned: "define parseRequest"),
        CleanupExample(spoken: "print open paren x comma y close paren",
                        cleaned: "print(x, y)"),
        CleanupExample(spoken: "push it to michael dash L dash I profile page",
                        cleaned: "push it to michael-L-i profile page"),
        CleanupExample(spoken: "I want two, no three",
                        cleaned: "I want three"),
        // Long, rambling dictations stay long: every sentence survives, only
        // the delivery is cleaned. These two teach length preservation.
        CleanupExample(spoken: "um so I was thinking about the design review tomorrow and uh I think we should probably move it to thursday because um half the team is going to be out on wednesday and uh also we still need to finish the mockups before we can really talk about anything",
                        cleaned: "I was thinking about the design review tomorrow, and I think we should probably move it to Thursday, because half the team is going to be out on Wednesday. Also, we still need to finish the mockups before we can really talk about anything."),
        CleanupExample(spoken: "okay so first open config dot pie and um change the timeout to thirty, no wait sixty seconds, then uh run the tests again and let me know if the auth ones still fail",
                        cleaned: "Okay, so first open config.py and change the timeout to sixty seconds, then run the tests again and let me know if the auth ones still fail."),
        // Enumerated speech stays flowing prose — never a bullet or numbered list.
        CleanupExample(spoken: "there are two problems here um first the build is really slow and second the tests are flaky",
                        cleaned: "There are two problems here. First, the build is really slow, and second, the tests are flaky."),
        CleanupExample(spoken: "so um we need to like parse it first",
                        cleaned: "We need to parse it first."),
        CleanupExample(spoken: "um yeah just um make it work you know",
                        cleaned: "Yeah, just make it work."),
        CleanupExample(spoken: "compute the dot product of a and b",
                        cleaned: "Compute the dot product of a and b."),
        // The dictation is itself a request — clean it and output it as text;
        // do NOT answer it or add a lead-in. This is the key anti-instruction case.
        CleanupExample(spoken: "can you clean up this table then push it to my repo",
                        cleaned: "Can you clean up this table, then push it to my repo?"),
    ]

    /// Extra pairs appended for terminal dictation: shell commands with spoken
    /// flags and paths. Kept out of the general set so prose apps never see
    /// command-flavored examples.
    public static let terminalFewShot: [CleanupExample] = [
        CleanupExample(spoken: "git commit dash m fix the login bug",
                        cleaned: "git commit -m \"fix the login bug\""),
        CleanupExample(spoken: "npm run build dash dash verbose",
                        cleaned: "npm run build --verbose"),
        CleanupExample(spoken: "tmux attach dash t work",
                        cleaned: "tmux attach -t work"),
        CleanupExample(spoken: "cd tilde slash projects slash voice type",
                        cleaned: "cd ~/projects/voicetype"),
    ]

    /// English's pairs rendered as prompt lines, with the terminal pairs
    /// appended when dictating into a terminal.
    public static func block(for category: AppCategory = .general) -> String {
        var pairs = fewShot
        if category == .terminal { pairs += terminalFewShot }
        return render(pairs)
    }

    /// Any language's pairs rendered as prompt lines: `spoken: "…" → "…"`.
    public static func render(_ examples: [CleanupExample]) -> String {
        examples
            .map { "spoken: \"\($0.spoken)\" → \"\($0.cleaned)\"" }
            .joined(separator: "\n")
    }
}
