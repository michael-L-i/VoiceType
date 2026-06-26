import SwiftUI
import AppKit
import VoiceTypeKit

/// The Models page: choose which on-device speech-to-text engine runs. Each row
/// shows the model (logo, name, description) with its features and an action on
/// the right — download, then test or remove. Apple's model is built into macOS
/// and selected by default; the others download once. One engine is active at a
/// time, and any ready engine can be tested inline without leaving the page.
struct ModelsView: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VT.Space.l) {
                PageHeader(title: "Models",
                           subtitle: "Pick the on-device engine that turns your voice into text — it all stays on your Mac.")

                table

                if let note = attributionNote {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, VT.Space.xs)
                }
            }
            .frame(maxWidth: 940, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(VT.Space.xl)
        }
        .background(.background)
    }

    private var table: some View {
        VStack(spacing: 0) {
            ForEach(Array(TranscriptionEngineKind.allCases.enumerated()), id: \.element) { index, kind in
                if index > 0 { Divider().padding(.leading, VT.Space.l) }
                EngineRow(coordinator: coordinator, kind: kind)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(
            RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                .strokeBorder(VT.hairline))
    }

    /// Collected attribution lines for any downloadable engines (e.g. NVIDIA CC-BY).
    private var attributionNote: String? {
        let lines = TranscriptionEngineKind.allCases.compactMap(\.attribution)
        return lines.isEmpty ? nil : lines.joined(separator: "  ·  ")
    }
}

private let featuresColumnWidth: CGFloat = 184
private let actionColumnWidth: CGFloat = 116

/// One engine as a table row: radio + vendor logo + name/description, feature
/// chips, and a right-side action (download → test/remove). Tapping Test expands
/// the row to reveal an inline recorder.
private struct EngineRow: View {
    @Bindable var coordinator: DictationCoordinator
    let kind: TranscriptionEngineKind

    @State private var showTest = false

    private var state: ModelAvailability { coordinator.modelState(for: kind) }
    private var isSelected: Bool { coordinator.settings.transcriptionEngine == kind }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: VT.Space.m) {
                Button {
                    if state.isReady { coordinator.settings.transcriptionEngine = kind }
                } label: {
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? VT.tint : Color.secondary)
                        .opacity(state.isReady ? 1 : 0.3)
                }
                .buttonStyle(.plain)
                .disabled(!state.isReady)

                VendorMark(vendor: kind.vendor)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: VT.Space.s) {
                        Text(kind.displayName)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                        if isSelected {
                            Tag(text: "Active", tint: VT.tint)
                        } else if !kind.requiresDownload {
                            Tag(text: "Built-in")
                        }
                    }
                    Text(kind.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: VT.Space.m)

                VStack(alignment: .leading, spacing: 5) {
                    ForEach(kind.features, id: \.self) { feature in
                        HStack(spacing: 6) {
                            Circle().fill(Color.secondary.opacity(0.6)).frame(width: 4, height: 4)
                            Text(feature).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: featuresColumnWidth, alignment: .leading)

                actionColumn
                    .frame(width: actionColumnWidth, alignment: .trailing)
            }
            .padding(VT.Space.l)
            .contentShape(Rectangle())
            .onTapGesture {
                if state.isReady { coordinator.settings.transcriptionEngine = kind }
            }

            if showTest {
                TestPanel(coordinator: coordinator, kind: kind) { closeTest() }
                    .padding(.horizontal, VT.Space.l)
                    .padding(.bottom, VT.Space.l)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: showTest)
    }

    private func toggleTest() {
        showTest.toggle()
        if !showTest { coordinator.cancelTest(kind) }
    }

    private func closeTest() {
        showTest = false
        coordinator.cancelTest(kind)
    }

    @ViewBuilder
    private var actionColumn: some View {
        switch state {
        case .builtIn, .ready:
            HStack(spacing: VT.Space.s) {
                Button { toggleTest() } label: {
                    Label("Test", systemImage: "waveform")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(showTest ? VT.tint : .accentColor)

                if kind.requiresDownload {
                    Button { coordinator.deleteModel(kind) } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .tint(.red)
                    .help("Remove model")
                }
            }
        case .notDownloaded:
            Button { coordinator.downloadModel(kind) } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.title2)
            }
            .buttonStyle(.borderless)
            .tint(VT.tint)
            .help(kind.approxDownloadSize.map { "Download (\($0))" } ?? "Download")
        case .downloading(let fraction):
            VStack(spacing: 3) {
                if let fraction {
                    ProgressView(value: fraction).frame(width: 96).tint(VT.tint)
                    Text("\(Int(fraction * 100))%")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView().controlSize(.small)
                    Text("Downloading…").font(.caption2).foregroundStyle(.secondary)
                }
            }
        case .failed(let message):
            Button("Retry") { coordinator.downloadModel(kind) }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help(message)
        }
    }
}

/// Inline "test this engine" panel that expands under a row. Records a short clip
/// and shows the engine's raw transcript in a copyable box. Never injects.
private struct TestPanel: View {
    @Bindable var coordinator: DictationCoordinator
    let kind: TranscriptionEngineKind
    var onClose: () -> Void

    private var test: DictationCoordinator.TestState { coordinator.testState(for: kind) }

    var body: some View {
        FrostedCard(padding: VT.Space.m) {
            VStack(alignment: .leading, spacing: VT.Space.m) {
                switch test {
                case .idle:
                    Button { coordinator.startTest(kind) } label: {
                        Label("Tap to record a test", systemImage: "mic.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(VT.tint)

                case .recording:
                    HStack(spacing: VT.Space.s) {
                        Circle().fill(VT.live).frame(width: 8, height: 8)
                        Text("Recording… speak, then stop.")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Stop") { coordinator.stopTest(kind) }
                            .buttonStyle(.borderedProminent)
                            .tint(VT.live)
                    }

                case .transcribing:
                    HStack(spacing: VT.Space.s) {
                        ProgressView().controlSize(.small)
                        Text("Transcribing with \(kind.displayName)…")
                            .foregroundStyle(.secondary)
                    }

                case .done(let text):
                    VStack(alignment: .leading, spacing: VT.Space.s) {
                        HStack {
                            Text("Heard by \(kind.displayName)")
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            CopyButton(text: text, style: .labeled)
                        }
                        ScrollView {
                            Text(text)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 140)
                        .padding(VT.Space.s)
                        .background(
                            RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous)
                                .fill(Color(nsColor: .textBackgroundColor)))
                        Button("Record again") {
                            coordinator.clearTest(kind)
                            coordinator.startTest(kind)
                        }
                        .buttonStyle(.bordered)
                    }

                case .failed(let message):
                    VStack(alignment: .leading, spacing: VT.Space.s) {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.callout)
                        Button("Try again") {
                            coordinator.clearTest(kind)
                            coordinator.startTest(kind)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// The model vendor's logo, sized and vertically centered in its cell. Apple uses
/// the system `apple.logo` glyph; NVIDIA uses its official eye mark, shipped as
/// `NVIDIALogo.svg` in the app bundle (with a branded tile as a safety fallback).
private struct VendorMark: View {
    let vendor: EngineVendor

    private static let size: CGFloat = 42

    /// The NVIDIA mark loaded from the bundled SVG, if present.
    private static let nvidiaLogo: NSImage? = {
        guard let url = Bundle.main.url(forResource: "NVIDIALogo", withExtension: "svg") else { return nil }
        return NSImage(contentsOf: url)
    }()

    var body: some View {
        Group {
            switch vendor {
            case .apple:
                Image(systemName: "apple.logo")
                    .font(.system(size: 26))
                    .foregroundStyle(.primary)
            case .nvidia:
                if let logo = Self.nvidiaLogo {
                    Image(nsImage: logo)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(red: 0.46, green: 0.73, blue: 0.0)) // NVIDIA green #76B900
                        .overlay(
                            Text("N")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white))
                }
            }
        }
        .frame(width: Self.size, height: Self.size)
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

/// A small rounded pill used for the "Built-in" / "Active" labels.
private struct Tag: View {
    let text: String
    var tint: Color = .secondary

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint == .secondary ? Color.secondary : tint)
    }
}
