import Foundation
import AVFoundation
import Speech
import VoiceTypeKit

/// On-device transcription via macOS 26's `SpeechAnalyzer` + `SpeechTranscriber`.
/// Fully local — audio never leaves the device. This is the default engine when
/// the hardware/locale supports it.
///
/// The contract is batch (one utterance in, text out): the pipeline calls this
/// after the push-to-talk key is released. Internally we still drive the
/// streaming analyzer, feeding the whole buffer and finalizing.
final class AppleSpeechEngine: TranscriptionEngine {
    let kind: TranscriptionEngineKind = .appleOnDevice

    func isAvailable() async -> Bool {
        // Available if the framework can offer an audio format for a transcriber
        // in the user's language (model may still need a one-time download).
        let supported = await SpeechTranscriber.supportedLocales
        return !supported.isEmpty
    }

    func transcribe(_ audio: PCMBuffer, locale localeID: String) async throws -> TranscriptionResult {
        let start = Date()
        let locale = Locale(identifier: localeID)

        guard await isLocaleSupported(locale) else {
            throw TranscriptionError.unavailable(reason: "Apple speech model doesn't support \(localeID).")
        }

        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: []
        )

        try await ensureModel(for: transcriber, locale: locale)

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            throw TranscriptionError.unavailable(reason: "No compatible audio format for the speech model.")
        }

        guard let inputBuffer = Self.makeBuffer(from: audio, targetFormat: analyzerFormat) else {
            throw TranscriptionError.failed("Could not prepare audio for the speech model.")
        }

        // Collect final-result text as it arrives.
        let collector = Task { () -> String in
            var text = AttributedString()
            for try await result in transcriber.results where result.isFinal {
                text += result.text
            }
            return String(text.characters)
        }

        let (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()
        try await analyzer.start(inputSequence: inputSequence)
        inputBuilder.yield(AnalyzerInput(buffer: inputBuffer))
        inputBuilder.finish()
        try await analyzer.finalizeAndFinishThroughEndOfInput()

        let text = (try await collector.value).trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { throw TranscriptionError.noSpeechDetected }

        return TranscriptionResult(text: text, locale: localeID,
                                   processingTime: Date().timeIntervalSince(start))
    }

    // MARK: - Model availability

    private func isLocaleSupported(_ locale: Locale) async -> Bool {
        let supported = await SpeechTranscriber.supportedLocales
        let target = locale.identifier(.bcp47)
        return supported.contains { $0.identifier(.bcp47) == target }
    }

    private func isLocaleInstalled(_ locale: Locale) async -> Bool {
        let installed = await SpeechTranscriber.installedLocales
        let target = locale.identifier(.bcp47)
        return installed.contains { $0.identifier(.bcp47) == target }
    }

    /// Download the locale model on first use; no-op once installed.
    private func ensureModel(for transcriber: SpeechTranscriber, locale: Locale) async throws {
        if await isLocaleInstalled(locale) { return }
        do {
            if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                Log.engine.info("downloading Apple speech model for \(locale.identifier, privacy: .public)…")
                try await request.downloadAndInstall()
            }
        } catch {
            throw TranscriptionError.unavailable(reason: "Couldn't download the on-device speech model: \(error.localizedDescription)")
        }
    }

    // MARK: - Audio bridging

    /// Build an `AVAudioPCMBuffer` in the analyzer's required format from our
    /// mono 16 kHz float buffer, resampling if the analyzer wants a different rate.
    static func makeBuffer(from audio: PCMBuffer, targetFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        // Source: mono float at audio.sampleRate.
        guard let srcFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                            sampleRate: audio.sampleRate, channels: 1, interleaved: false),
              let srcBuffer = AVAudioPCMBuffer(pcmFormat: srcFormat,
                                               frameCapacity: AVAudioFrameCount(max(1, audio.samples.count))) else {
            return nil
        }
        srcBuffer.frameLength = AVAudioFrameCount(audio.samples.count)
        if let dst = srcBuffer.floatChannelData {
            audio.samples.withUnsafeBufferPointer { src in
                if let base = src.baseAddress { dst[0].update(from: base, count: audio.samples.count) }
            }
        }

        if srcFormat == targetFormat { return srcBuffer }

        guard let converter = AVAudioConverter(from: srcFormat, to: targetFormat) else { return srcBuffer }
        let ratio = targetFormat.sampleRate / audio.sampleRate
        let capacity = AVAudioFrameCount(Double(audio.samples.count) * ratio) + 4096
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return srcBuffer }

        var fed = false
        var error: NSError?
        _ = converter.convert(to: outBuffer, error: &error) { _, outStatus in
            if fed { outStatus.pointee = .endOfStream; return nil }
            fed = true; outStatus.pointee = .haveData; return srcBuffer
        }
        return outBuffer
    }
}
