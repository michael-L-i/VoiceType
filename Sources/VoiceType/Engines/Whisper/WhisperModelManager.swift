import Foundation
import VoiceTypeKit

/// Resolves and (on request) downloads the ggml weights the local whisper.cpp
/// engine runs on. Models are large binaries we must never bundle or commit, so
/// they live in Application Support and are fetched once, on the user's say-so.
///
/// Privacy note: this only ever *pulls* a public model file. No audio or
/// transcript ever touches this type.
struct WhisperModelManager: Sendable {

    /// The ggml model variant. `base.en` is the default: a good
    /// latency/accuracy trade-off for English on Apple silicon.
    enum Model: String, Sendable {
        case baseEN = "ggml-base.en.bin"

        /// Public Hugging Face mirror maintained by whisper.cpp's author.
        var remoteURL: URL {
            URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/\(rawValue)")!
        }
    }

    let model: Model

    init(model: Model = .baseEN) {
        self.model = model
    }

    // MARK: - On-disk location

    /// `~/Library/Application Support/VoiceType/models/` — created on demand.
    static func modelsDirectory() throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = support.appendingPathComponent("VoiceType/models", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Absolute path this model would live at (whether or not it exists yet).
    func modelURL() throws -> URL {
        try Self.modelsDirectory().appendingPathComponent(model.rawValue, isDirectory: false)
    }

    /// True if the weights are already downloaded and non-empty.
    func isModelDownloaded() -> Bool {
        guard let url = try? modelURL() else { return false }
        guard let size = try? FileManager.default
            .attributesOfItem(atPath: url.path)[.size] as? Int else { return false }
        return size > 0
    }

    // MARK: - Download

    /// Fetch the model to `modelsDirectory()` if it isn't already present.
    ///
    /// Downloads to a temp file and atomically moves it into place, so a
    /// cancelled or failed transfer never leaves a half-written model that
    /// `isModelDownloaded()` would falsely report as ready. `progress` is called
    /// on an arbitrary executor with a fraction in `0...1`; it may be called many
    /// times. No-op (and reports `1`) if the model already exists.
    func downloadModelIfNeeded(
        progress: @Sendable @escaping (Double) -> Void = { _ in }
    ) async throws {
        if isModelDownloaded() {
            progress(1)
            return
        }

        let destination = try modelURL()
        let source = model.remoteURL
        Log.engine.info("downloading whisper model \(model.rawValue, privacy: .public)…")

        let tempURL = try await Self.download(from: source, progress: progress)

        // Move the completed download into place atomically. If a sibling task
        // already won the race, prefer the existing file and drop ours.
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try? FileManager.default.removeItem(at: tempURL)
            } else {
                try FileManager.default.moveItem(at: tempURL, to: destination)
            }
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            throw TranscriptionError.failed("Couldn't install the whisper model: \(error.localizedDescription)")
        }
        progress(1)
    }

    /// Stream the bytes to a temp file, reporting progress. Returns the temp URL;
    /// the caller owns moving or deleting it.
    private static func download(
        from url: URL,
        progress: @Sendable @escaping (Double) -> Void
    ) async throws -> URL {
        let (bytes, response) = try await URLSession.shared.bytes(from: url)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw TranscriptionError.network("Model download failed (HTTP \(code)).")
        }

        let expected = response.expectedContentLength // -1 if unknown
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("voicetype-\(UUID().uuidString).download")

        guard FileManager.default.createFile(atPath: tempURL.path, contents: nil) else {
            throw TranscriptionError.failed("Couldn't create a temporary file for the download.")
        }
        let handle = try FileHandle(forWritingTo: tempURL)
        defer { try? handle.close() }

        var received: Int64 = 0
        var chunk = Data()
        chunk.reserveCapacity(1 << 16)

        do {
            for try await byte in bytes {
                chunk.append(byte)
                if chunk.count >= (1 << 16) {
                    try handle.write(contentsOf: chunk)
                    received += Int64(chunk.count)
                    chunk.removeAll(keepingCapacity: true)
                    if expected > 0 { progress(min(1, Double(received) / Double(expected))) }
                }
            }
            if !chunk.isEmpty {
                try handle.write(contentsOf: chunk)
                received += Int64(chunk.count)
            }
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            throw TranscriptionError.network("Model download interrupted: \(error.localizedDescription)")
        }

        return tempURL
    }
}
