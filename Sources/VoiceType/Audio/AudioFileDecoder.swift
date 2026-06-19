import Foundation
import AVFoundation
import VoiceTypeKit

/// Decodes an audio or video file into the mono 16 kHz `PCMBuffer` the
/// transcription engines expect. Uses `AVAssetReader`, which reads the audio
/// track out of any container — compressed audio (mp3/m4a) and video (mp4/mov)
/// alike — then reuses `AudioCaptureService.resampleToTarget` for the final
/// sample-rate step. Everything stays on-device.
enum AudioFileDecoder {
    /// File types the import flow offers. Used by the picker and drag-drop.
    static let supportedExtensions = ["mp3", "m4a", "mp4", "mov", "wav", "aiff", "aif", "caf"]

    struct DecodeError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    /// Decode the first audio track to a mono 16 kHz buffer, reporting progress in
    /// 0...1. Throws `DecodeError` with a user-facing message on any failure
    /// (no audio track, unreadable format, etc).
    static func decode(_ url: URL,
                       onProgress: (@Sendable (Double) -> Void)? = nil) async throws -> PCMBuffer {
        let asset = AVURLAsset(url: url)

        guard let track = try await asset.loadTracks(withMediaType: .audio).first else {
            throw DecodeError(message: "No audio found in this file.")
        }
        let totalSeconds = try await CMTimeGetSeconds(asset.load(.duration))
        let nativeRate = try await sampleRate(of: track) ?? AudioCaptureService.targetSampleRate

        let reader = try AVAssetReader(asset: asset)
        // Decode to non-interleaved 32-bit float, downmixed to a single channel.
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
            AVNumberOfChannelsKey: 1,
        ]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else {
            throw DecodeError(message: "Couldn't read this audio format.")
        }
        reader.add(output)
        guard reader.startReading() else {
            throw DecodeError(message: reader.error?.localizedDescription ?? "Couldn't read this file.")
        }

        var native: [Float] = []
        while reader.status == .reading, let sample = output.copyNextSampleBuffer() {
            append(sample, into: &native)
            if let onProgress, totalSeconds > 0 {
                let t = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sample))
                onProgress(min(1, max(0, t / totalSeconds)))
            }
            CMSampleBufferInvalidate(sample)
        }

        if reader.status == .failed {
            throw DecodeError(message: reader.error?.localizedDescription ?? "Decoding failed.")
        }
        guard !native.isEmpty else {
            throw DecodeError(message: "This file contains no audio.")
        }
        onProgress?(1)

        let resampled = AudioCaptureService.resampleToTarget(native, from: nativeRate)
        return PCMBuffer(samples: resampled, sampleRate: AudioCaptureService.targetSampleRate)
    }

    /// The track's native sample rate from its format description, if available.
    private static func sampleRate(of track: AVAssetTrack) async throws -> Double? {
        let descriptions = try await track.load(.formatDescriptions)
        guard let desc = descriptions.first,
              let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(desc) else {
            return nil
        }
        return asbd.pointee.mSampleRate
    }

    /// Append a decoded sample buffer's float samples onto `out`.
    private static func append(_ sampleBuffer: CMSampleBuffer, into out: inout [Float]) {
        var blockBuffer: CMBlockBuffer?
        var abl = AudioBufferList()
        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &abl,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer)
        guard status == noErr else { return }

        for buffer in UnsafeMutableAudioBufferListPointer(&abl) {
            guard let data = buffer.mData else { continue }
            let count = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
            let ptr = data.bindMemory(to: Float.self, capacity: count)
            out.append(contentsOf: UnsafeBufferPointer(start: ptr, count: count))
        }
    }
}
