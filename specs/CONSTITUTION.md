# Constitution — VoiceType

> The agent reconstructs **every** accept/reject decision from this file.
> Editing it is the highest-trust action a human can take. Keep it short.

## North star
Speak anywhere, get clean text instantly, with your audio never leaving your
control unless you opt in.

## Platform
Mac-only, native Swift 6 / SwiftUI. Deployment floor is **macOS 14**, built
against the newest SDK: newer Apple APIs are availability-gated and must degrade
to a path that works on 14, never assumed present. Reach was chosen over
latest-OS-only on 2026-07-24, accepting that macOS 14–15 gets a weaker engine.

## Principles (the agent must never violate these)
- **Privacy is the product.** Audio and transcripts stay on-device by default.
  Any off-device path is opt-in, clearly labeled, and explicitly consented to.
- **Latency is a feature.** Time-to-text is the primary metric we optimize.
- Ship the smallest thing that is genuinely good. Opinionated over configurable.
- Degrade gracefully: if the cleanup/cloud step is unavailable, still deliver raw
  text rather than failing.

## Non-goals (reject on sight)
- Cloud-by-default or telemetry-by-default. No silent data egress, ever.
- Feature bloat that adds a setting instead of making a decision.
- Account/login walls for core dictation.

## Guardrails (constitutional invariants — non-negotiable)
- The agent only touches files, issues, and PRs in THIS repo.
- Any irreversible or outward-facing action requires human approval via comms.
- User audio and transcripts are never committed, logged externally, or
  exfiltrated.
- Hard caps: agent iterations, files-per-auto-merge, open agent PRs (see policy).
