import SwiftUI
import AppKit
import VoiceTypeKit

/// The Models page: choose which on-device speech-to-text engine runs. Laid out
/// as a clean table — model (logo, name, description, actions) on the left, its
/// features on the right. Apple's model is built into macOS and selected by
/// default; the others download once. Exactly one engine is active at a time.
struct ModelsView: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VT.Space.l) {
                PageHeader(title: "Dictation Models",
                           subtitle: "Choose the model that turns your speech into text — everything runs on your Mac.")

                table

                if let note = attributionNote {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, VT.Space.xs)
                }
            }
            .frame(maxWidth: 820, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(VT.Space.xl)
        }
        .background(.background)
    }

    private var table: some View {
        VStack(spacing: 0) {
            HStack(spacing: VT.Space.m) {
                Text("MODEL").tracking(0.6)
                Spacer()
                Text("FEATURES").tracking(0.6)
                    .frame(width: featuresColumnWidth, alignment: .leading)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, VT.Space.l)
            .padding(.vertical, VT.Space.s)

            Divider()

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

private let featuresColumnWidth: CGFloat = 168

/// One engine as a table row: radio + vendor logo + name/description/actions, with
/// its feature chips in the right column.
private struct EngineRow: View {
    @Bindable var coordinator: DictationCoordinator
    let kind: TranscriptionEngineKind

    private var state: ModelAvailability { coordinator.modelState(for: kind) }
    private var isSelected: Bool { coordinator.settings.transcriptionEngine == kind }

    var body: some View {
        HStack(alignment: .top, spacing: VT.Space.m) {
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
                .padding(.top, 1)

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
                actions
                    .padding(.top, 1)
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
        }
        .padding(VT.Space.l)
        .contentShape(Rectangle())
        .onTapGesture {
            if state.isReady { coordinator.settings.transcriptionEngine = kind }
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch state {
        case .builtIn:
            EmptyView()
        case .ready:
            Button { coordinator.deleteModel(kind) } label: {
                Label("Remove", systemImage: "trash")
            }
            .buttonStyle(.link)
            .tint(.red)
            .font(.callout)
        case .notDownloaded:
            Button { coordinator.downloadModel(kind) } label: {
                Label(kind.approxDownloadSize.map { "Download (\($0))" } ?? "Download",
                      systemImage: "arrow.down.circle")
            }
            .buttonStyle(.link)
            .font(.callout)
        case .downloading(let fraction):
            HStack(spacing: VT.Space.s) {
                if let fraction {
                    ProgressView(value: fraction).frame(width: 130).tint(VT.tint)
                    Text("\(Int(fraction * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView().controlSize(.small)
                    Text("Downloading…").font(.caption).foregroundStyle(.secondary)
                }
            }
        case .failed(let message):
            HStack(spacing: VT.Space.s) {
                Button("Retry") { coordinator.downloadModel(kind) }
                    .buttonStyle(.link)
                    .font(.callout)
                Text(message).font(.caption).foregroundStyle(.orange)
            }
        }
    }
}

/// The model vendor's logo. Apple uses the system `apple.logo` glyph. NVIDIA's
/// logo is a trademark we don't ship, so we draw a branded placeholder tile — and
/// if a bundle image named "NVIDIALogo" is present, we use that instead.
private struct VendorMark: View {
    let vendor: EngineVendor

    private static let size: CGFloat = 30

    var body: some View {
        switch vendor {
        case .apple:
            Image(systemName: "apple.logo")
                .font(.system(size: 18))
                .foregroundStyle(.primary)
                .frame(width: Self.size, height: Self.size)
        case .nvidia:
            if let logo = NSImage(named: "NVIDIALogo") {
                Image(nsImage: logo)
                    .resizable().scaledToFit()
                    .frame(width: Self.size, height: Self.size)
            } else {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color(red: 0.46, green: 0.73, blue: 0.0)) // NVIDIA green #76B900
                    .frame(width: Self.size, height: Self.size)
                    .overlay(
                        Text("N")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white))
            }
        }
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
