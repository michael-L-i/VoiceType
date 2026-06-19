import SwiftUI
import VoiceTypeKit

/// The main window's chrome: a sidebar of destinations on the left, the selected
/// page on the right. Home is the live surface; Insights and Scratchpad are
/// placeholders for now; Setup is the guided permissions flow. Settings isn't a
/// page — it opens the existing preferences window (⌘,) so the working 5-tab
/// settings stay intact.
struct RootView: View {
    @Bindable var coordinator: DictationCoordinator
    @State private var selection: SidebarItem = .home

    /// The primary destinations, shown at the top of the sidebar.
    private let topItems: [SidebarItem] = [.home, .stats, .transcripts, .transcribe]

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 212, max: 240)
        } detail: {
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("")
        // A first-run or menu "Set Up" request routes to the Setup tab rather
        // than a separate window. Consume the one-shot flag once handled.
        .onChange(of: coordinator.wantsOnboarding) { _, want in
            if want {
                selection = .setup
                coordinator.wantsOnboarding = false
            }
        }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
                .padding(.horizontal, VT.Space.m)
                .padding(.top, VT.Space.s)
                .padding(.bottom, VT.Space.l)

            VStack(spacing: 2) {
                ForEach(topItems) { item in
                    sidebarRow(item)
                }
            }
            .padding(.horizontal, VT.Space.s)

            Spacer()

            // Bottom group: Setup (a real tab) sits just above Settings (which
            // opens the standalone preferences window).
            VStack(spacing: 2) {
                sidebarRow(.setup, badge: setupBadge)
                settingsRow
            }
            .padding(.horizontal, VT.Space.s)
            .padding(.bottom, VT.Space.xs)
        }
        .padding(.vertical, VT.Space.s)
    }

    /// A count of outstanding grants, so Setup advertises that it needs attention.
    private var setupBadge: Int? {
        let pending = Permission.allCases.filter { coordinator.status(for: $0) != .granted }.count
        return pending == 0 ? nil : pending
    }

    private var brand: some View {
        HStack(spacing: VT.Space.s) {
            BrandMark(color: VT.tint)
                .frame(width: 30, height: 15)
            Text("VoiceType")
                .font(.title3.weight(.semibold))
        }
    }

    private func sidebarRow(_ item: SidebarItem, badge: Int? = nil) -> some View {
        Button {
            selection = item
        } label: {
            HStack(spacing: VT.Space.s) {
                Label(item.title, systemImage: item.symbol)
                Spacer(minLength: 0)
                if let badge {
                    Text("\(badge)")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(.orange, in: Circle())
                }
            }
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
            HomeView(coordinator: coordinator) { selection = $0 }
        case .stats:
            StatsView(coordinator: coordinator)
        case .transcripts:
            TranscriptsView(coordinator: coordinator)
        case .transcribe:
            TranscribeView(coordinator: coordinator)
        case .setup:
            SetupView(coordinator: coordinator) { selection = .home }
        }
    }
}

/// The selectable destinations in the sidebar. (Settings is intentionally not
/// here — it opens the standalone preferences window.)
enum SidebarItem: String, CaseIterable, Identifiable {
    case home, stats, transcripts, transcribe, setup

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .stats: return "Stats"
        case .transcripts: return "Transcripts"
        case .transcribe: return "Transcribe"
        case .setup: return "Setup"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house"
        case .stats: return "chart.bar.xaxis"
        case .transcripts: return "text.book.closed"
        case .transcribe: return "waveform.badge.plus"
        case .setup: return "person.badge.shield.checkmark"
        }
    }
}
