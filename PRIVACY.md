# Privacy Policy

VoiceType is designed so speech processing happens on your Mac. It has no user
accounts, advertising, analytics, telemetry, or cloud transcription service.
The developer does not receive your audio, transcript text, dictionary, usage
statistics, or the identity of apps you dictate into.

This policy describes VoiceType 2.4.1 and later. Last updated: July 24, 2026.

## Data stored on your Mac

- **Transcript history:** Enabled by default and limited to the 1,000 most recent
  dictations. Records can include transcript text, time, selected engines, source
  filename, and the name and bundle identifier of the target app. Turn off
  **Keep an on-device history** to stop saving new records. Delete individual
  records or use **Delete all** on the Transcripts page to remove saved history.
- **Usage statistics:** Word counts, speaking time, streaks, and per-app aggregate
  totals are stored locally. They do not contain audio or transcript text.
- **Settings and dictionary:** Your preferences and word replacements are stored
  locally.
- **Downloaded models:** Optional speech-model weights are cached in your user
  Library. The Models page can reveal or remove them.

Microphone audio is held in memory while a dictation is processed and is not
written to disk by VoiceType. Imported audio or video files are read for
transcription; VoiceType does not copy the source file into its own storage.

## Network connections

Audio, transcripts, dictionary entries, and usage statistics are never included
in these connections:

- **Updates:** Sparkle automatically checks this GitHub repository for signed
  VoiceType updates on a daily schedule; you can also check manually. Every update
  payload is verified with the public EdDSA key embedded in the app.
- **Optional model downloads:** When you choose Download on the Models page,
  VoiceType's open-source model libraries fetch the selected model weights from
  their configured distribution host. Inference uses the downloaded model
  locally afterward.
- **Apple system services:** Apple's built-in speech and intelligence frameworks
  are requested in on-device mode. macOS controls those system components and
  their permissions.

These services may receive ordinary connection metadata such as your IP address,
request time, and the requested file, under their own privacy policies.

## macOS permissions

VoiceType asks for:

- **Microphone**, to capture speech while dictation is active.
- **Speech Recognition**, to use Apple's on-device speech model.
- **Accessibility**, to observe the chosen global shortcut and paste the result
  into the focused app.

Permissions can be reviewed or revoked in System Settings.

## Data sharing and retention

VoiceType does not sell personal data and does not share the local data described
above with the developer or third parties. Local records remain until you delete
them, clear them in the app, or remove VoiceType's data from your Mac. Optional
model files remain until removed from the Models page or from disk.

## Contact

For privacy questions, open a GitHub issue that contains no private data. Report
possible data exposure privately using the process in [SECURITY.md](./SECURITY.md).
