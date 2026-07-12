import SwiftUI
import AppKit
import VoiceTypeKit

/// The Dictionary page: the user's personal vocabulary — words the transcriber
/// keeps hearing wrong (names, jargon, brands) and what to type instead. A
/// composer up top adds pairs, the list below edits them in place, and a live
/// playground at the bottom shows the rules rewriting a sentence as you type.
/// Everything binds straight to `coordinator.settings.wordReplacements`, which
/// the pipeline applies to the final text no matter which engines ran.
struct DictionaryView: View {
    @Bindable var coordinator: DictationCoordinator

    @State private var draftFrom = ""
    @State private var draftTo = ""
    @State private var query = ""
    @State private var sample = ""
    @FocusState private var focusedField: ComposerField?

    private enum ComposerField { case from, to }

    private var replacements: [WordReplacement] { coordinator.settings.wordReplacements }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VT.Space.l) {
                PageHeader(title: L("Dictionary"),
                           subtitle: L("Teach VoiceType the words it hears wrong — names, jargon, brands. They're fixed on every dictation, whichever engine runs."))

                composer

                if replacements.isEmpty {
                    emptyState
                } else {
                    rulesSection
                    playground
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(VT.Space.xl)
        }
        .background(.background)
        .onAppear(perform: seedSample)
        .onChange(of: replacements) { seedSample() }
    }

    // MARK: Composer

    /// Whether the draft's "heard" phrase already exists (trimmed, case-insensitive).
    private var draftIsDuplicate: Bool {
        let from = normalized(draftFrom)
        guard !from.isEmpty else { return false }
        return replacements.contains { normalized($0.from) == from }
    }

    private var draftCanAdd: Bool {
        !normalized(draftFrom).isEmpty && !draftIsDuplicate
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: VT.Space.s) {
            HStack(alignment: .bottom, spacing: VT.Space.m) {
                composerField(L("When you say"), placeholder: "voice type",
                              text: $draftFrom, field: .from)
                Image(systemName: "arrow.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(VT.tint)
                    .padding(.bottom, VT.Space.m)
                composerField(L("VoiceType types"), placeholder: "VoiceType",
                              text: $draftTo, field: .to)

                Button(action: addDraft) {
                    Label(L("Add"), systemImage: "plus")
                        .font(.body.weight(.semibold))
                        .padding(.horizontal, VT.Space.xs)
                        .padding(.vertical, 2)
                }
                .buttonStyle(.borderedProminent)
                .tint(VT.tint)
                .disabled(!draftCanAdd)
            }

            if draftIsDuplicate {
                Label(L("“\(normalized(draftFrom))” is already in your dictionary — edit it below instead."),
                      systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(VT.Space.l)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                .strokeBorder(VT.hairline, lineWidth: 1))
    }

    private func composerField(_ label: String, placeholder: String,
                               text: Binding<String>, field: ComposerField) -> some View {
        VStack(alignment: .leading, spacing: VT.Space.xs) {
            SectionLabel(label)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .rounded))
                .focused($focusedField, equals: field)
                .onSubmit {
                    if field == .from { focusedField = .to } else { addDraft() }
                }
                .padding(.horizontal, VT.Space.m)
                .padding(.vertical, VT.Space.s)
                .background(
                    RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous)
                        .fill(Color(nsColor: .textBackgroundColor)))
                .overlay(
                    RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous)
                        .strokeBorder(focusedField == field ? VT.tint.opacity(0.7) : VT.hairline,
                                      lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
    }

    private func addDraft() {
        guard draftCanAdd else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            coordinator.settings.wordReplacements.append(
                WordReplacement(from: draftFrom.trimmingCharacters(in: .whitespaces),
                                to: draftTo.trimmingCharacters(in: .whitespaces)))
        }
        draftFrom = ""
        draftTo = ""
        focusedField = .from
    }

    // MARK: Empty state

    /// Ready-made pairs that demonstrate the feature; tapping one adds it.
    private static let starters: [(from: String, to: String)] = [
        ("voice type", "VoiceType"),
        ("git hub", "GitHub"),
        ("j son", "JSON"),
    ]

    private var emptyState: some View {
        VStack(spacing: VT.Space.m) {
            Image(systemName: "character.book.closed")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.tertiary)
            Text(L("Your dictionary is empty"))
                .font(.system(.title3, design: .rounded).weight(.semibold))
            Text(L("Add your name, product names, or team shorthand above — or start with an example:"))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: VT.Space.s) {
                ForEach(Self.starters, id: \.from) { starter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            coordinator.settings.wordReplacements.append(
                                WordReplacement(from: starter.from, to: starter.to))
                        }
                    } label: {
                        HStack(spacing: VT.Space.xs) {
                            Text(starter.from).foregroundStyle(.secondary)
                            Image(systemName: "arrow.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(VT.tint)
                            Text(starter.to).fontWeight(.medium)
                        }
                        .font(.callout)
                        .padding(.horizontal, VT.Space.m)
                        .padding(.vertical, VT.Space.s)
                        .background(.regularMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(VT.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, VT.Space.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, VT.Space.xl * 1.5)
        .background(
            RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                .strokeBorder(VT.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])))
    }

    // MARK: Rules list

    /// Search kicks in once the list is long enough that scanning it stops
    /// being instant; below that it would just be chrome.
    private var showsSearch: Bool { replacements.count >= 8 }

    private func matchesQuery(_ replacement: WordReplacement) -> Bool {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return true }
        return replacement.from.localizedCaseInsensitiveContains(q)
            || replacement.to.localizedCaseInsensitiveContains(q)
    }

    /// The trimmed lowercase "heard" phrases that appear more than once, so
    /// later duplicates can be flagged in place.
    private var duplicatedFroms: Set<String> {
        var seen: Set<String> = []
        var dupes: Set<String> = []
        for replacement in replacements {
            let from = normalized(replacement.from)
            guard !from.isEmpty else { continue }
            if !seen.insert(from).inserted { dupes.insert(from) }
        }
        return dupes
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: VT.Space.s) {
            HStack(alignment: .firstTextBaseline) {
                SectionLabel(L("Your words"))
                Spacer()
                if showsSearch {
                    searchField
                }
                Text(replacements.count == 1 ? L("1 word") : L("\(replacements.count) words"))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }

            VStack(spacing: 0) {
                let visible = replacements.filter(matchesQuery)
                if visible.isEmpty {
                    Text(L("No matches for “\(query)”."))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(VT.Space.l)
                } else {
                    let dupes = duplicatedFroms
                    ForEach($coordinator.settings.wordReplacements) { $replacement in
                        if matchesQuery(replacement) {
                            if replacement.id != visible.first?.id {
                                Divider().padding(.leading, VT.Space.l)
                            }
                            ReplacementRow(
                                replacement: $replacement,
                                isDuplicate: dupes.contains(normalized(replacement.from))) {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        coordinator.settings.wordReplacements
                                            .removeAll { $0.id == replacement.id }
                                    }
                                }
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor)))
            .clipShape(RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                    .strokeBorder(VT.hairline))

            Text(L("Matched as whole words, ignoring case, after cleanup runs — top to bottom."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var searchField: some View {
        HStack(spacing: VT.Space.xs) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(L("Search"), text: $query)
                .textFieldStyle(.plain)
                .font(.callout)
                .frame(width: 130)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L("Clear search"))
            }
        }
        .padding(.horizontal, VT.Space.s)
        .padding(.vertical, VT.Space.xs)
        .background(
            Capsule().fill(Color(nsColor: .textBackgroundColor)))
        .overlay(Capsule().strokeBorder(VT.hairline, lineWidth: 1))
    }

    // MARK: Playground

    private var playground: some View {
        VStack(alignment: .leading, spacing: VT.Space.s) {
            HStack(spacing: VT.Space.xs) {
                Image(systemName: "waveform")
                    .font(.caption)
                    .foregroundStyle(VT.tint)
                SectionLabel(L("Try it"))
                Spacer()
            }

            VStack(alignment: .leading, spacing: VT.Space.m) {
                Text(L("Type a sentence the way the transcriber might hear it:"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // A vertically-growing field, not a TextEditor: it hugs a single
                // line (no phantom empty row), wraps as you type, and Return
                // ends editing instead of inserting newlines that balloon the box.
                TextField(L("So I was telling the team about voice type…"),
                          text: $sample, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .lineLimit(1...3)
                    .padding(VT.Space.m)
                    .background(
                        RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous)
                            .fill(Color(nsColor: .textBackgroundColor)))
                    .overlay(
                        RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous)
                            .strokeBorder(VT.hairline))

                VStack(alignment: .leading, spacing: VT.Space.xs) {
                    SectionLabel(L("What gets typed"))
                    Text(highlightedResult)
                        .font(.callout)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(VT.Space.m)
                        .background(
                            RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous)
                                .fill(VT.tint.opacity(0.06)))
                        .overlay(
                            RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous)
                                .strokeBorder(VT.tint.opacity(0.25)))
                }
            }
            .padding(VT.Space.l)
            .background(
                RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor)))
            .overlay(
                RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
                    .strokeBorder(VT.hairline))
        }
    }

    /// Seed the playground with the user's own words the first time rules
    /// exist, so the very first glance shows a replacement happening.
    private func seedSample() {
        guard sample.isEmpty, let first = replacements.first(where: {
            !normalized($0.from).isEmpty
        }) else { return }
        sample = L("So I was telling the team about \(first.from.trimmingCharacters(in: .whitespaces)) yesterday.")
    }

    /// The playground text with every replacement applied, mirroring
    /// `WordReplacements.apply` but marking the inserted text so the user can
    /// see exactly which words their dictionary rewrote.
    private var highlightedResult: AttributedString {
        var out = AttributedString(sample)
        for replacement in replacements {
            let from = replacement.from.trimmingCharacters(in: .whitespaces)
            guard !from.isEmpty else { continue }
            let pattern = "(?<!\\w)" + NSRegularExpression.escapedPattern(for: from) + "(?!\\w)"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }
            let plain = String(out.characters)
            let matches = regex.matches(in: plain, range: NSRange(plain.startIndex..., in: plain))
            for match in matches.reversed() {
                guard let range = Range(match.range, in: out) else { continue }
                var piece = AttributedString(replacement.to)
                piece.foregroundColor = VT.tint
                piece.font = .callout.weight(.semibold)
                out.replaceSubrange(range, with: piece)
            }
        }
        return out
    }

    // MARK: Helpers

    private func normalized(_ phrase: String) -> String {
        phrase.trimmingCharacters(in: .whitespaces).lowercased()
    }
}

// MARK: - Row

/// One dictionary entry as an editable table row: the heard phrase, a coral
/// arrow, the typed phrase, and a delete affordance that appears on hover.
private struct ReplacementRow: View {
    @Binding var replacement: WordReplacement
    let isDuplicate: Bool
    var onDelete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: VT.Space.m) {
            Image(systemName: "mic.fill")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 16)

            TextField(L("Heard"), text: $replacement.from)
                .textFieldStyle(.plain)
                .font(.system(.callout, design: .rounded))
                .frame(maxWidth: .infinity)

            Image(systemName: "arrow.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(VT.tint)

            TextField(L("Typed instead"), text: $replacement.to)
                .textFieldStyle(.plain)
                .font(.system(.callout, design: .rounded).weight(.medium))
                .frame(maxWidth: .infinity)

            if isDuplicate {
                Text(L("Duplicate"))
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15), in: Capsule())
                    .foregroundStyle(.orange)
                    .help(L("Another entry already matches this phrase; the first one wins."))
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.callout)
                    .foregroundStyle(hovering ? AnyShapeStyle(.red) : AnyShapeStyle(.tertiary))
            }
            .buttonStyle(.plain)
            .opacity(hovering ? 1 : 0)
            .accessibilityLabel(L("Remove “\(replacement.from)”"))
        }
        .padding(.horizontal, VT.Space.l)
        .padding(.vertical, VT.Space.m)
        .background(hovering ? Color.primary.opacity(0.03) : .clear)
        .onHover { hovering = $0 }
    }
}
