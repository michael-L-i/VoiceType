import Foundation
import AVFoundation
import Speech
import VoiceTypeKit

/// Apple's on-device speech engine. macOS 26 uses the newer
/// `SpeechAnalyzer`/`SpeechTranscriber` stack; macOS 14 and 15 use
/// `SFSpeechRecognizer` with `requiresOnDeviceRecognition` enforced so audio
/// never falls back to Apple's servers.
final class AppleSpeechEngine: TranscriptionEngine {
    let kind: TranscriptionEngineKind = .appleOnDevice

    func isAvailable() async -> Bool {
        !(await Self.supportedLocales()).isEmpty
    }

    func transcribe(_ audio: PCMBuffer, locale localeID: String) async throws -> TranscriptionResult {
        let start = Date()
        let text: String

        if #available(macOS 26.0, *) {
            text = try await transcribeWithSpeechAnalyzer(audio, localeID: localeID)
        } else {
            text = try await transcribeWithLegacyRecognizer(audio, localeID: localeID)
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { throw TranscriptionError.noSpeechDetected }
        return TranscriptionResult(text: trimmed, locale: localeID,
                                   processingTime: Date().timeIntervalSince(start))
    }

    /// Locales the Apple engine can keep entirely on-device on this version of
    /// macOS. Shared with `EngineFactory` so the language picker and resolver do
    /// not advertise a legacy locale that would require a network request.
    static func supportedLocales() async -> [Locale] {
        if #available(macOS 26.0, *) {
            return await SpeechTranscriber.supportedLocales
        }
        return SFSpeechRecognizer.supportedLocales().filter { locale in
            SFSpeechRecognizer(locale: locale)?.supportsOnDeviceRecognition == true
        }
    }

    // MARK: - macOS 26+

    @available(macOS 26.0, *)
    private func transcribeWithSpeechAnalyzer(_ audio: PCMBuffer,
                                              localeID: String) async throws -> String {
        let locale = Locale(identifier: localeID)

        guard await isLocaleSupported(locale) else {
            throw TranscriptionError.unavailable(
                reason: "Apple speech model doesn't support \(localeID).")
        }

        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [],
            attributeOptions: []
        )

        try await ensureModel(for: transcriber, locale: locale)

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber]) else {
            throw TranscriptionError.unavailable(
                reason: "No compatible audio format for the speech model.")
        }

        guard let inputBuffer = Self.makeBuffer(from: audio, targetFormat: analyzerFormat) else {
            throw TranscriptionError.failed("Could not prepare audio for the speech model.")
        }

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

        return try await collector.value
    }

    @available(macOS 26.0, *)
    private func isLocaleSupported(_ locale: Locale) async -> Bool {
        let supported = await SpeechTranscriber.supportedLocales
        let target = locale.identifier(.bcp47)
        return supported.contains { $0.identifier(.bcp47) == target }
    }

    @available(macOS 26.0, *)
    private func isLocaleInstalled(_ locale: Locale) async -> Bool {
        let installed = await SpeechTranscriber.installedLocales
        let target = locale.identifier(.bcp47)
        return installed.contains { $0.identifier(.bcp47) == target }
    }

    /// Download the locale model on first use; no-op once installed.
    @available(macOS 26.0, *)
    private func ensureModel(for transcriber: SpeechTranscriber,
                             locale: Locale) async throws {
        if await isLocaleInstalled(locale) { return }
        do {
            if let request = try await AssetInventory.assetInstallationRequest(
                supporting: [transcriber]) {
                Log.engine.info("downloading Apple speech model for \(locale.identifier, privacy: .public)…")
                try await request.downloadAndInstall()
            }
        } catch {
            throw TranscriptionError.unavailable(
                reason: "Couldn't download the on-device speech model: \(error.localizedDescription)")
        }
    }

    // MARK: - macOS 14–15

    private func transcribeWithLegacyRecognizer(_ audio: PCMBuffer,
                                                localeID: String) async throws -> String {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            throw TranscriptionError.unavailable(
                reason: "Allow Speech Recognition access in System Settings.")
        }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeID)),
              recognizer.supportsOnDeviceRecognition else {
            throw TranscriptionError.unavailable(
                reason: "Apple's on-device recognizer doesn't support \(localeID) on this Mac.")
        }
        guard recognizer.isAvailable else {
            throw TranscriptionError.unavailable(
                reason: "Apple's on-device recognizer is temporarily unavailable.")
        }
        guard let buffer = Self.makeSourceBuffer(from: audio) else {
            throw TranscriptionError.failed("Could not prepare audio for the speech recognizer.")
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = false
        request.taskHint = .dictation

        // The recognizer can stall without ever reporting a final result or an
        // error, which would hang the pipeline forever. Give it a deadline that
        // scales with how much audio it has to chew through.
        let audioSeconds = audio.sampleRate > 0 ? Double(audio.samples.count) / audio.sampleRate : 0
        let deadline = Duration.seconds(max(15, audioSeconds * 2))

        do {
            return try await LegacyRecognitionSession(
                recognizer: recognizer, request: request).recognize(buffer, deadline: deadline)
        } catch let error as TranscriptionError {
            throw error
        } catch {
            throw TranscriptionError.failed(
                "Apple on-device recognition failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Audio bridging

    private static func makeSourceBuffer(from audio: PCMBuffer) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: audio.sampleRate,
                                         channels: 1,
                                         interleaved: false),
              let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(max(1, audio.samples.count))) else {
            return nil
        }
        buffer.frameLength = AVAudioFrameCount(audio.samples.count)
        if let channels = buffer.floatChannelData {
            audio.samples.withUnsafeBufferPointer { source in
                if let base = source.baseAddress {
                    channels[0].update(from: base, count: audio.samples.count)
                }
            }
        }
        return buffer
    }

    static func makeBuffer(from audio: PCMBuffer,
                           targetFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let sourceBuffer = makeSourceBuffer(from: audio) else { return nil }
        let sourceFormat = sourceBuffer.format
        if sourceFormat == targetFormat { return sourceBuffer }

        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            return sourceBuffer
        }
        let ratio = targetFormat.sampleRate / audio.sampleRate
        let capacity = AVAudioFrameCount(Double(audio.samples.count) * ratio) + 4096
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat, frameCapacity: capacity) else {
            return sourceBuffer
        }

        var fed = false
        var error: NSError?
        _ = converter.convert(to: outputBuffer, error: &error) { _, status in
            if fed {
                status.pointee = .endOfStream
                return nil
            }
            fed = true
            status.pointee = .haveData
            return sourceBuffer
        }
        return error == nil ? outputBuffer : sourceBuffer
    }
}

/// Retains the legacy recognition task until its callback produces a final
/// result. The request is explicitly on-device before this bridge is created.
private final class LegacyRecognitionSession: @unchecked Sendable {
    private let recognizer: SFSpeechRecognizer
    private let request: SFSpeechAudioBufferRecognitionRequest
    private let lock = NSLock()
    private var task: SFSpeechRecognitionTask?
    private var watchdog: Task<Void, Never>?
    private var continuation: CheckedContinuation<String, Error>?

    init(recognizer: SFSpeechRecognizer,
         request: SFSpeechAudioBufferRecognitionRequest) {
        self.recognizer = recognizer
        self.request = request
    }

    func recognize(_ buffer: AVAudioPCMBuffer, deadline: Duration) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            self.continuation = continuation
            lock.unlock()

            let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                if let error {
                    self?.finish(.failure(error))
                } else if let result, result.isFinal {
                    self?.finish(.success(result.bestTranscription.formattedString))
                }
            }

            lock.lock()
            if self.continuation != nil {
                self.task = task
                self.watchdog = Task { [weak self] in
                    try? await Task.sleep(for: deadline)
                    guard !Task.isCancelled else { return }
                    self?.finish(.failure(TranscriptionError.failed(
                        "Apple's on-device recognizer timed out.")), cancelTask: true)
                }
            } else {
                task.cancel()
            }
            lock.unlock()

            request.append(buffer)
            request.endAudio()
        }
    }

    private func finish(_ result: Result<String, Error>, cancelTask: Bool = false) {
        lock.lock()
        guard let continuation else {
            lock.unlock()
            return
        }
        self.continuation = nil
        let task = self.task
        let watchdog = self.watchdog
        self.task = nil
        self.watchdog = nil
        lock.unlock()

        watchdog?.cancel()
        if cancelTask { task?.cancel() }
        continuation.resume(with: result)
    }
}
