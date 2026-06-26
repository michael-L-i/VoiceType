import SwiftUI
import VoiceTypeKit

/// The Models page: choose which on-device speech-to-text engine runs. Apple's
/// model is built into macOS and selected by default; the others download once
/// and you can switch between them. Exactly one engine is active at a time.
struct ModelsView: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VT.Space.l) {
                PageHeader(title: "Transcription models",
                           subtitle: "Everything runs on your Mac — your audio never leaves the device. Pick the engine that transcribes your speech; one is active at a time.")

                VStack(spacing: VT.Space.m) {
                    ForEach(TranscriptionEngineKind.allCases, id: \.self) { kind in
                        EngineCard(coordinator: coordinator, kind: kind)
                    }
                }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(VT.Space.xl)
        }
        .background(.background)
    }
}

/// One engine as a selectable card: a radio to activate it (only when its model
/// is ready), plus a download / remove control for downloadable engines.
private struct EngineCard: View {
    @Bindable var coordinator: DictationCoordinator
    let kind: TranscriptionEngineKind

    private var state: ModelAvailability { coordinator.modelState(for: kind) }
    private var isSelected: Bool { coordinator.settings.transcriptionEngine == kind }

    var body: some View {
        FrostedCard {
            HStack(alignment: .top, spacing: VT.Space.m) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? VT.tint : Color.secondary)
                    .opacity(state.isReady ? 1 : 0.35)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: VT.Space.s) {
                        Text(kind.displayName)
                            .font(.system(.headline, design: .rounded))
                        if !kind.requiresDownload {
                            Tag(text: "Built-in")
                        }
                        if isSelected {
                            Tag(text: "Active", tint: VT.tint)
                        }
                    }
                    Text(kind.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let attribution = kind.attribution {
                        Text(attribution)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer(minLength: VT.Space.m)
                trailing
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay(
            RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                .strokeBorder(isSelected ? VT.tint.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if state.isReady { coordinator.settings.transcriptionEngine = kind }
        }
    }

    @ViewBuilder
    private var trailing: some View {
        switch state {
        case .builtIn:
            EmptyView()
        case .ready:
            Button("Remove", role: .destructive) { coordinator.deleteModel(kind) }
                .buttonStyle(.borderless)
                .font(.callout)
        case .notDownloaded:
            Button {
                coordinator.downloadModel(kind)
            } label: {
                Label(kind.approxDownloadSize.map { "Download (\($0))" } ?? "Download",
                      systemImage: "arrow.down.circle")
            }
            .buttonStyle(.borderedProminent)
            .tint(VT.tint)
            .controlSize(.regular)
        case .downloading(let fraction):
            VStack(alignment: .trailing, spacing: 4) {
                if let fraction {
                    ProgressView(value: fraction).frame(width: 120).tint(VT.tint)
                    Text("\(Int(fraction * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView().controlSize(.small)
                    Text("Downloading…").font(.caption).foregroundStyle(.secondary)
                }
            }
        case .failed(let message):
            VStack(alignment: .trailing, spacing: 4) {
                Button("Retry") { coordinator.downloadModel(kind) }
                    .buttonStyle(.bordered)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: 180, alignment: .trailing)
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
