import SwiftUI
import AppKit
import VoiceTypeKit

/// The Transcripts page: every saved dictation, searchable, kept on this Mac.
/// Tap a row to expand it; copy or delete from the row; clear everything from the
/// footer. Audio is never stored — only the text.
struct TranscriptsView: View {
    @Bindable var coordinator: DictationCoordinator
    @State private var query = ""
    @State private var expanded: Set<UUID> = []
    @State private var confirmingClear = false

    private var records: [DictationRecord] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return coordinator.history.records }
        return coordinator.history.records.filter {
            $0.text.lowercased().contains(q)
                || ($0.appName?.lowercased().contains(q) ?? false)
                || ($0.sourceFilename?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: VT.Space.l) {
            PageHeader(title: "Transcripts", subtitle: "Saved on this Mac.")
            searchField
            content
        }
        .padding(VT.Space.xl)
        .frame(maxWidth: 900, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.background)
    }

    private var searchField: some View {
        HStack(spacing: VT.Space.s) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search transcripts", text: $query)
                .textFieldStyle(.plain)
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, VT.Space.m)
        .padding(.vertical, VT.Space.s)
        .background(.quaternary.opacity(0.4), in: Capsule())
        .frame(maxWidth: 420)
    }

    @ViewBuilder
    private var content: some View {
        if coordinator.history.records.isEmpty {
            emptyState("No transcripts yet",
                       "Dictations and file transcriptions will be saved here.")
        } else if records.isEmpty {
            emptyState("No matches", "Try a different search.")
        } else {
            List {
                ForEach(records) { record in
                    row(record)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                coordinator.deleteRecord(id: record.id)
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                        .contextMenu {
                            Button { copy(record.text) } label: { Label("Copy", systemImage: "doc.on.doc") }
                            Button(role: .destructive) {
                                coordinator.deleteRecord(id: record.id)
                            } label: { Label("Delete", systemImage: "trash") }
                        }
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)

            footer
        }
    }

    private func row(_ record: DictationRecord) -> some View {
        let isOpen = expanded.contains(record.id)
        return VStack(alignment: .leading, spacing: VT.Space.xs) {
            Text(record.text)
                .lineLimit(isOpen ? nil : 3)
                .contentShape(Rectangle())
                .onTapGesture {
                    if isOpen { expanded.remove(record.id) } else { expanded.insert(record.id) }
                }

            HStack(spacing: VT.Space.s) {
                Text(record.date, format: .dateTime.month().day().hour().minute())
                sourceBadge(record)
                Spacer()
                Button { copy(record.text) } label: { Image(systemName: "doc.on.doc") }
                    .buttonStyle(.borderless)
                    .help("Copy")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func sourceBadge(_ record: DictationRecord) -> some View {
        switch record.source {
        case .importedFile:
            badge(icon: "waveform", text: record.sourceFilename ?? "Imported file")
        case .microphone:
            if let app = record.appName {
                badge(icon: "app.dashed", text: app)
            }
        }
    }

    private func badge(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
            Text(text).lineLimit(1)
        }
        .font(.caption2)
        .foregroundStyle(VT.tint)
        .padding(.horizontal, VT.Space.s)
        .padding(.vertical, 2)
        .background(VT.tint.opacity(0.12), in: Capsule())
    }

    private var footer: some View {
        HStack {
            Text("\(coordinator.history.records.count) saved · on-device only, audio never stored.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Clear all", role: .destructive) { confirmingClear = true }
        }
        .confirmationDialog("Delete all transcripts?", isPresented: $confirmingClear, titleVisibility: .visible) {
            Button("Delete all", role: .destructive) { coordinator.clearHistory() }
        } message: {
            Text("This permanently removes every saved transcript from this Mac.")
        }
    }

    private func emptyState(_ title: String, _ message: String) -> some View {
        ContentUnavailableView(title, systemImage: "text.book.closed", description: Text(message))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
