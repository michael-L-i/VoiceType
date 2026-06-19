import SwiftUI
import AppKit
import VoiceTypeKit

/// VoiceType's Home: the single dashboard. A personalized greeting and warm
/// quick-start hero, then everything at a glance — your pace and totals, a
/// full activity heatmap, where you dictate, plain-language insights, and a
/// peek at recent transcripts.
///
/// The layout is responsive: content sits in a centered, width-capped column so
/// it never hugs one edge, and on wide windows the lower cards split into two
/// columns instead of leaving a dead zone.
struct HomeView: View {
    @Bindable var coordinator: DictationCoordinator
    /// Jump to another sidebar destination (the "View all" link).
    var onNavigate: (SidebarItem) -> Void = { _ in }

    /// Past this width the lower cards go two-up.
    private let wideBreakpoint: CGFloat = 880
    /// Cap so content doesn't stretch absurdly on huge displays.
    private let contentMaxWidth: CGFloat = 1180

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width >= wideBreakpoint
            ScrollView {
                VStack(alignment: .leading, spacing: VT.Space.l) {
                    greeting
                    if !coordinator.permissionsGranted { setupCallout }
                    welcomeHero
                    overviewCard
                    activityCard
                    lowerCards(wide: wide)
                    recentTranscripts
                }
                .frame(maxWidth: contentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)   // center the column
                .padding(.horizontal, wide ? VT.Space.xl + 8 : VT.Space.l)
                .padding(.vertical, VT.Space.xl)
            }
        }
        .background(.background)
        .onAppear { coordinator.refreshInsights() }
    }

    // MARK: Greeting

    private var greeting: some View {
        HStack(alignment: .firstTextBaseline, spacing: VT.Space.s) {
            Text(greetingText)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
            Spacer(minLength: 0)
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let part = hour < 12 ? "morning" : (hour < 18 ? "afternoon" : "evening")
        if let name = Self.firstName { return "Good \(part), \(name)" }
        return "Good \(part)"
    }

    private static let firstName: String? = {
        let full = NSFullUserName().trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = full.split(separator: " ").first else { return nil }
        return first.isEmpty ? nil : String(first)
    }()

    // MARK: Welcome hero

    private var welcomeHero: some View {
        VStack(alignment: .leading, spacing: VT.Space.m) {
            BrandMark(color: .white)
                .frame(width: 64, height: 32)
            VStack(alignment: .leading, spacing: VT.Space.xs) {
                Text("Speak anywhere, get clean text instantly")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                Text(quickStartLine)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(VT.Space.l)
        .background(VT.brandGradient,
                    in: RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous))
    }

    private var quickStartLine: String {
        let verb = coordinator.settings.hotkey.holdToTalk ? "Hold" : "Tap"
        return "\(verb) \(coordinator.settings.hotkey.trigger.displayName) anywhere and start speaking — your words land in the focused app."
    }

    // MARK: Overview — gauge + headline numbers

    private var overviewCard: some View {
        FrostedCard {
            HStack(alignment: .center, spacing: VT.Space.xl) {
                RadialGauge(value: Double(coordinator.stats.averageWordsPerMinute),
                            label: "WPM",
                            valueText: coordinator.stats.averageWordsPerMinute.formatted())
                    .frame(width: 132, height: 132)
                VStack(alignment: .leading, spacing: VT.Space.m) {
                    StatRow(value: coordinator.stats.totalWords.formatted(),
                            label: "total words", symbol: "text.word.spacing")
                    StatRow(value: coordinator.stats.currentStreak.formatted(),
                            label: "day streak", symbol: "flame")
                    StatRow(value: coordinator.stats.sessionCount.formatted(),
                            label: "dictations", symbol: "mic")
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: Activity heatmap

    private var activityCard: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: VT.Space.m) {
                SectionLabel("Activity")
                ScrollView(.horizontal, showsIndicators: false) {
                    ActivityHeatmap(days: coordinator.dailyStats.window(endingOn: Date(), days: 364))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Lower cards — top apps + insights (two-up when wide)

    @ViewBuilder
    private func lowerCards(wide: Bool) -> some View {
        let hasApps = !coordinator.dailyStats.topApps().isEmpty
        if wide {
            HStack(alignment: .top, spacing: VT.Space.l) {
                if hasApps { topAppsCard.frame(maxWidth: .infinity, alignment: .top) }
                insightsCard.frame(maxWidth: .infinity, alignment: .top)
            }
        } else {
            if hasApps { topAppsCard }
            insightsCard
        }
    }

    private var topAppsCard: some View {
        let apps = Array(coordinator.dailyStats.topApps(limit: 6))
        let maxWords = max(1, apps.map(\.words).max() ?? 1)
        return FrostedCard {
            VStack(alignment: .leading, spacing: VT.Space.m) {
                SectionLabel("Where you dictate")
                ForEach(apps) { app in
                    AppUsageRow(app: app, fraction: Double(app.words) / Double(maxWords))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var insightsCard: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: VT.Space.m) {
                HStack {
                    SectionLabel("Insights")
                    Spacer()
                    if coordinator.naturalSummary == nil {
                        Button("Summarize my usage") { coordinator.generateNaturalSummary() }
                            .buttonStyle(.borderless)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(VT.tint)
                    }
                }
                Text(coordinator.insights.headline)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                if let summary = coordinator.naturalSummary {
                    Text(summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if coordinator.insights.bullets.isEmpty {
                    Text("Dictate a little and patterns will appear here.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(coordinator.insights.bullets) { bullet in
                        Label { Text(bullet.text) } icon: {
                            Image(systemName: bullet.symbol).foregroundStyle(VT.tint)
                        }
                        .font(.callout)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Recent transcripts

    private var recentTranscripts: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: VT.Space.m) {
                HStack {
                    SectionLabel("Recent transcripts")
                    Spacer()
                    if !coordinator.history.records.isEmpty {
                        Button("View all") { onNavigate(.transcripts) }
                            .buttonStyle(.plain)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(VT.tint)
                    }
                }
                if coordinator.history.records.isEmpty {
                    Text("Your dictations will show up here.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, VT.Space.s)
                } else {
                    let recent = Array(coordinator.history.records.prefix(3))
                    ForEach(recent) { record in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.text)
                                .font(.callout)
                                .lineLimit(2)
                            Text(record.date, format: .dateTime.weekday().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if record.id != recent.last?.id { Divider() }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Setup callout

    private var setupCallout: some View {
        Button {
            coordinator.wantsOnboarding = true
        } label: {
            HStack(spacing: VT.Space.s) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Finish setup to start dictating")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.primary)
                    Text("VoiceType needs microphone, speech, and accessibility access.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding(VT.Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: VT.Radius.control, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// One app's share of dictation: its icon, name, a coral bar, and word count.
private struct AppUsageRow: View {
    let app: AppUsage
    let fraction: Double

    var body: some View {
        HStack(spacing: VT.Space.m) {
            icon.frame(width: 22, height: 22)
            Text(app.name)
                .font(.callout)
                .lineLimit(1)
                .frame(width: 130, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(VT.hairline)
                    Capsule().fill(VT.tint)
                        .frame(width: max(4, geo.size.width * fraction))
                }
            }
            .frame(height: 8)
            Text(app.words.formatted())
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .trailing)
        }
    }

    @ViewBuilder
    private var icon: some View {
        if let nsImage = Self.appIcon(bundleID: app.bundleID) {
            Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "app.dashed").foregroundStyle(.secondary)
        }
    }

    private static func appIcon(bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}
