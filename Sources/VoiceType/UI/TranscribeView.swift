import SwiftUI
import AppKit
import UniformTypeIdentifiers
import VoiceTypeKit

/// The Transcribe page: drop or pick an audio/video file and turn it into text.
/// Decoding and transcription run on-device through the same engines as live
/// dictation; the result is saved to Transcripts and offered to copy.
struct TranscribeView: View {
    @Bindable var coordinator: DictationCoordinator
    @State private var showImporter = false
    @State private var isTargeted = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VT.Space.l) {
                PageHeader(title: L("Transcribe a file"),
                           subtitle: L("Turn an audio or video recording into clean text."))
                switch coordinator.importState {
                case .idle:                  dropWell
                case .decoding(let p):       progressCard(L("Decoding audio…"), p)
                case .transcribing(let p):   progressCard(L("Transcribing…"), p)
                case .done(let text):        resultCard(text)
                case .failed(let message):   errorCard(message)
                }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(VT.Space.xl)
        }
        .background(.background)
        .fileImporter(isPresented: $showImporter,
                      allowedContentTypes: [.audio, .movie],
                      allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                coordinator.transcribeFile(at: url)
            }
        }
    }

    // MARK: Drop well

    private var dropWell: some View {
        VStack(spacing: VT.Space.m) {
            Image(systemName: "waveform.badge.plus")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(VT.tint)
            Text(L("Drop an audio or video file"))
                .font(.system(.title3, design: .rounded).weight(.semibold))
            Text(L("MP3, M4A, WAV, MP4, MOV — anything with audio."))
                .font(.callout)
                .foregroundStyle(.secondary)
            Button(L("Choose file…")) { showImporter = true }
                .buttonStyle(.borderedProminent)
                .tint(VT.tint)
                .padding(.top, VT.Space.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VT.Space.xl * 1.5)
        .background(
            RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                .fill(isTargeted ? VT.tint.opacity(0.08) : Color.clear))
        .overlay(
            RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                .strokeBorder(isTargeted ? VT.tint : VT.hairline,
                              style: StrokeStyle(lineWidth: 1.5, dash: [7, 5])))
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first else { return false }
            coordinator.transcribeFile(at: url)
            return true
        } isTargeted: { isTargeted = $0 }
    }

    // MARK: Progress

    private func progressCard(_ title: String, _ progress: Double) -> some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: VT.Space.m) {
                Text(title).font(.headline)
                ProgressView(value: progress)
                    .tint(VT.tint)
                HStack {
                    Text("\(Int(progress * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(L("Cancel"), role: .cancel) { coordinator.cancelImport() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Result

    private func resultCard(_ text: String) -> some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: VT.Space.m) {
                HStack {
                    Label(L("Saved to Transcripts"), systemImage: "checkmark.circle.fill")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.green)
                    Spacer()
                    CopyButton(text: text, style: .labeled)
                }
                ScrollView {
                    Text(text)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 280)
                Button(L("Transcribe another")) { coordinator.clearImport() }
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Error

    private func errorCard(_ message: String) -> some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: VT.Space.m) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Button(L("Try another file")) { coordinator.clearImport() }
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

}
