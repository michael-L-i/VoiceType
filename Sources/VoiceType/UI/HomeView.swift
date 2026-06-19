import SwiftUI
import AppKit
import VoiceTypeKit

/// VoiceType's Home: a calm welcome dashboard. A personalized greeting, a
/// quick-start hero, an at-a-glance stat strip with a mini activity heatmap, and
/// a peek at your most recent transcripts. The live "is it listening" feedback
/// lives in the floating HUD pill, so Home stays a quiet at-a-glance surface.
struct HomeView: View {
    @Bindable var coordinator: DictationCoordinator
    /// Jump to another sidebar destination (the "View all" links).
    var onNavigate: (SidebarItem) -> Void = { _ in }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VT.Space.l) {
                greeting
                if !coordinator.permissionsGranted {
                    setupCallout
                }
                welcomeHero
                statStrip
                miniActivity
                recentTranscripts
            }
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(VT.Space.xl)
        }
        .background(.background)
    }

    // MARK: Greeting

    private var greeting: some View {
        HStack(alignment: .firstTextBaseline, spacing: VT.Space.s) {
            Text(greetingText)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
            hotkeyBadge
            Spacer(minLength: 0)
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let part = hour < 12 ? "morning" : (hour < 18 ? "afternoon" : "evening")
        if let name = Self.firstName {
            return "Good \(part), \(name)"
        }
        return "Good \(part)"
    }

    private static let firstName: String? = {
        let full = NSFullUserName().trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = full.split(separator: " ").first else { return nil }
        return first.isEmpty ? nil : String(first)
    }()

    private var hotkeyBadge: some View {
        HStack(spacing: VT.Space.xs) {
            Image(systemName: "keyboard")
            Text(coordinator.settings.hotkey.holdToTalk ? "Hold" : "Tap")
                .foregroundStyle(.secondary)
            Text(coordinator.settings.hotkey.trigger.displayName)
                .fontWeight(.semibold)
                .monospaced()
        }
        .font(.callout)
        .padding(.horizontal, VT.Space.m)
        .padding(.vertical, VT.Space.s)
        .background(.quaternary.opacity(0.5), in: Capsule())
    }

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

    // MARK: Stat strip

    private var statStrip: some View {
        HStack(spacing: VT.Space.m) {
            StatTile(value: coordinator.stats.totalWords.formatted(),
                     label: "total words", symbol: "text.word.spacing")
            StatTile(value: coordinator.stats.averageWordsPerMinute.formatted(),
                     label: "wpm", symbol: "gauge.with.dots.needle.67percent")
            StatTile(value: coordinator.stats.currentStreak.formatted(),
                     label: "day streak", symbol: "flame")
        }
    }

    // MARK: Mini activity

    private var miniActivity: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: VT.Space.m) {
                HStack {
                    SectionLabel("Last 12 weeks")
                    Spacer()
                    Button("All stats") { onNavigate(.stats) }
                        .buttonStyle(.plain)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(VT.tint)
                }
                ActivityHeatmap(days: coordinator.dailyStats.window(endingOn: Date(), days: 84))
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
                    ForEach(coordinator.history.records.prefix(3)) { record in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.text)
                                .font(.callout)
                                .lineLimit(2)
                            Text(record.date, format: .dateTime.weekday().hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if record.id != coordinator.history.records.prefix(3).last?.id {
                            Divider()
                        }
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

/// A compact stat tile for the Home strip: a small glyph, a big rounded value,
/// and its label.
struct StatTile: View {
    let value: String
    let label: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: VT.Space.xs) {
            Image(systemName: symbol)
                .font(.callout)
                .foregroundStyle(VT.tint)
            Text(value)
                .font(.system(.title, design: .rounded).weight(.semibold).monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(VT.Space.l)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous)
            .strokeBorder(VT.hairline, lineWidth: 1))
    }
}
