import SwiftUI
import AppKit
import VoiceTypeKit

/// The Stats page: a WPM gauge and headline numbers, a full-year activity
/// heatmap, your most-used apps, and plain-language insights (with an optional
/// on-device AI summary). All from on-device data — nothing leaves the Mac.
struct StatsView: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VT.Space.l) {
                PageHeader(title: "Stats", subtitle: "Your dictation, at a glance.")
                headline
                activityCard
                if !coordinator.dailyStats.topApps().isEmpty {
                    topAppsCard
                }
                insightsCard
            }
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(VT.Space.xl)
        }
        .background(.background)
        .onAppear { coordinator.refreshInsights() }
    }

    // MARK: Headline — gauge + key numbers

    private var headline: some View {
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

    // MARK: Top apps

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

    // MARK: Insights

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
                        Label {
                            Text(bullet.text)
                        } icon: {
                            Image(systemName: bullet.symbol).foregroundStyle(VT.tint)
                        }
                        .font(.callout)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// One app's share of dictation: its icon, name, a coral bar, and word count.
private struct AppUsageRow: View {
    let app: AppUsage
    let fraction: Double

    var body: some View {
        HStack(spacing: VT.Space.m) {
            icon
                .frame(width: 22, height: 22)
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
