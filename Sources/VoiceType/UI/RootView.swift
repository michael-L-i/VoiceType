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
    private let topItems: [SidebarItem] = [.home, .transcripts, .transcribe, .models, .dictionary]

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

            // Bottom group: Setup sits just above Settings, both real in-window
            // pages now. (⌘, still opens the standalone preferences window too.)
            // When Sparkle has an update pending, a row appears on top of them —
            // the way back to the update dialog after dismissing it.
            VStack(spacing: 2) {
                if coordinator.updateAvailable {
                    updateAvailableRow
                }
                sidebarRow(.setup, badge: setupBadge)
                sidebarRow(.settings)
            }
            .animation(.easeInOut(duration: 0.2), value: coordinator.updateAvailable)
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

    /// An action row, not a destination: reopens Sparkle's update dialog. Only
    /// shown while an update is actually pending, so the sidebar stays quiet
    /// the rest of the time.
    private var updateAvailableRow: some View {
        Button {
            coordinator.checkForUpdates()
        } label: {
            Label(L("Update available"), systemImage: "arrow.down.circle.fill")
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, VT.Space.s)
                .padding(.vertical, VT.Space.s)
                .background(
                    RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous)
                        .fill(VT.tint.opacity(0.14)))
                .foregroundStyle(VT.tint)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .transition(.opacity)
        .help(L("Install the new version of VoiceType"))
    }

    private func sidebarRow(_ item: SidebarItem, badge: Int? = nil) -> some View {
        Button {
            selection = item
        } label: {
            HStack(spacing: VT.Space.s) {
                Label(L(dynamic: item.title), systemImage: item.symbol)
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

    // MARK: Detail

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .home:
            HomeView(coordinator: coordinator) { selection = $0 }
        case .transcripts:
            TranscriptsView(coordinator: coordinator)
        case .transcribe:
            TranscribeView(coordinator: coordinator)
        case .models:
            ModelsView(coordinator: coordinator)
        case .dictionary:
            DictionaryView(coordinator: coordinator)
        case .setup:
            // Setup finishes by sliding the user into Settings (where the
            // dictation key now lives), rather than popping up an inline picker.
            SetupView(coordinator: coordinator) {
                withAnimation(.easeInOut(duration: 0.35)) { selection = .settings }
            }
        case .settings:
            SettingsView(coordinator: coordinator)
        }
    }
}

/// The selectable destinations in the sidebar. (Settings is intentionally not
/// here — it opens the standalone preferences window.)
enum SidebarItem: String, CaseIterable, Identifiable {
    case home, transcripts, transcribe, models, dictionary, setup, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .transcripts: return "Transcripts"
        case .transcribe: return "Transcribe"
        case .models: return "Models"
        case .dictionary: return "Dictionary"
        case .setup: return "Setup"
        case .settings: return "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house"
        case .transcripts: return "text.book.closed"
        case .transcribe: return "waveform.badge.plus"
        case .models: return "cpu"
        case .dictionary: return "character.book.closed"
        case .setup: return "person.badge.shield.checkmark"
        case .settings: return "gearshape"
        }
    }
}
