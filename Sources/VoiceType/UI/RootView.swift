import SwiftUI
import VoiceTypeKit

/// The main window's chrome: a sidebar of destinations on the left, the selected
/// page on the right. Home is the live surface; Insights and Scratchpad are
/// placeholders for now. Settings isn't a page — it opens the existing
/// preferences window (⌘,) so the working 5-tab settings stay intact.
struct RootView: View {
    @Bindable var coordinator: DictationCoordinator
    @State private var selection: SidebarItem = .home

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 212, max: 240)
        } detail: {
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("")
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
                .padding(.horizontal, VT.Space.m)
                .padding(.top, VT.Space.s)
                .padding(.bottom, VT.Space.l)

            VStack(spacing: 2) {
                ForEach(SidebarItem.allCases) { item in
                    sidebarRow(item)
                }
            }
            .padding(.horizontal, VT.Space.s)

            Spacer()

            Divider().padding(.horizontal, VT.Space.s)
            settingsRow
                .padding(.horizontal, VT.Space.s)
                .padding(.vertical, VT.Space.xs)
        }
        .padding(.vertical, VT.Space.s)
    }

    private var brand: some View {
        HStack(spacing: VT.Space.s) {
            Image(systemName: "waveform")
                .font(.title3.weight(.semibold))
                .foregroundStyle(VT.tint)
            Text("VoiceType")
                .font(.title3.weight(.semibold))
        }
    }

    private func sidebarRow(_ item: SidebarItem) -> some View {
        Button {
            selection = item
        } label: {
            Label(item.title, systemImage: item.symbol)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, VT.Space.s)
                .padding(.vertical, VT.Space.s)
                .background(
                    RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous)
                        .fill(selection == item ? VT.tint.opacity(0.14) : .clear)
                )
                .foregroundStyle(selection == item ? VT.tint : .primary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var settingsRow: some View {
        Button {
            coordinator.openSettings()
        } label: {
            Label("Settings", systemImage: "gearshape")
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, VT.Space.s)
                .padding(.vertical, VT.Space.s)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    // MARK: Detail

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .home:
            HomeView(coordinator: coordinator)
        case .insights:
            ComingSoonView(title: "Insights", symbol: "chart.bar.xaxis",
                           blurb: "Dictation trends and patterns are coming soon.")
        case .scratchpad:
            ComingSoonView(title: "Scratchpad", symbol: "note.text",
                           blurb: "A quick place to jot and dictate is coming soon.")
        }
    }
}

/// The selectable destinations in the sidebar. (Settings is intentionally not
/// here — it opens the standalone preferences window.)
enum SidebarItem: String, CaseIterable, Identifiable {
    case home, insights, scratchpad

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .insights: return "Insights"
        case .scratchpad: return "Scratchpad"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house"
        case .insights: return "chart.bar.xaxis"
        case .scratchpad: return "note.text"
        }
    }
}
