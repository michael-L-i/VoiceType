# Latency notes

Time-to-text is the product. These are the measured costs on the dictation
path and the decisions that follow from them. Numbers are from an M5 Pro on
macOS 26.6 with Parakeet TDT 0.6B V3.

## Where the time goes (warm)

| Stage | Cost |
| --- | --- |
| Mic tail grace after the stop key (`AudioCaptureService.tailGrace`) | 300 ms |
| Parakeet inference, 1–20 s of audio | ~50–90 ms + ~1 ms per output token |
| Rule-based cleanup | ~1 ms |
| Logged `ttt` (transcribe + cleanup), median of 1,000 real dictations | ~150 ms |

## The cold start: CoreML's Neural Engine compile

Before a CoreML model runs on the Neural Engine, CoreML compiles it and caches
the result in `~/Library/Caches/<bundle id>/com.apple.e5rt.e5bundlecache/<macOS build>/`.

- **Cache hit:** loading Parakeet takes ~130 ms.
- **Cache miss:** loading takes **~11 s**. Every macOS update starts a new
  build directory, so the first load after an update is always a miss.
- **Even a long-running process can recompile.** Two real dictations stalled
  for 11.9 s and 21.9 s after 13 h and 41 h idle. Each stall coincided with a
  new compile-cache entry being written. The other 998 dictations finished in
  under 0.7 s.

Running the model is what triggers the compile. So each engine's `prewarm()`
loads its model and runs it once on a second of silence, which costs ~50 ms
when nothing needs compiling. The coordinator warms the engine in use:

- **at launch**, after availability resolves;
- **on wake from sleep**;
- **on hotkey press**, if the engine hasn't run for over a minute. The
  recording is dead time for the model, so any reload or compile overlaps the
  user's speech. With a cold compile forced, a 15 s recording went from
  ~10.6 s to 72 ms after release; a 3 s recording still waits ~7.8 s.

The coordinator never warms while a transcription is running. Transcription
waits for an in-flight warm-up, so the two never share a model. Engines are
warmed only when they're in use, never while the user browses the Models page,
because each loaded model stays resident (0.5–1.5 GB).

## Reading the logs

Everything below is timing or counts only, never audio or text:

```sh
/usr/bin/log show --last 1d --info --predicate 'subsystem == "com.voicetype.app"' --style compact
```

- `parakeet warm in 61ms`: a warm-up's duration. Seconds here means a compile
  happened, off the critical path.
- `first audio 140ms after start (buffer holds 64ms)`: how much speech at the
  start of a dictation the mic could have missed (≈ the first number minus the
  second).
- `dictation ok: … ttt=150ms`: transcribe + cleanup for one dictation.
- `dictation dropped below the speech gate` / `dictation error: …`: why a
  dictation produced no text.
