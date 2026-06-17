import SwiftUI
import AppKit
import VoiceTypeKit

/// VoiceType's Home: a calm welcome dashboard. A personalized greeting, a
/// quick-start hero that reminds you how to dictate, and your headline stats.
/// The in-the-moment "is it listening" feedback lives in the floating HUD pill,
/// so Home stays a quiet at-a-glance surface rather than a live status board.
struct HomeView: View {
    @Bindable var coordinator: DictationCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VT.Space.l) {
                greeting
                if !coordinator.permissionsGranted {
                    setupCallout
                }
                welcomeHero
                statsCard
            }
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(VT.Space.xl)
        }
        .background(.background)
    }

    // MARK: Greeting

    private var greeting: some View {
        HStack(alignment: .firstTextBaseline, spacing: VT.Space.s) {
            Text(greetingText)
                .font(.largeTitle.weight(.bold))
            hotkeyBadge
            Spacer(minLength: 0)
        }
    }

    /// "Good {morning/afternoon/evening}, {FirstName}" — name from the macOS
    /// account, gracefully dropping to a nameless greeting when unavailable.
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

    /// A branded quick-start card: the product promise plus the one move that
    /// makes it happen. Replaces a live status board — the HUD does that job.
    private var welcomeHero: some View {
        VStack(alignment: .leading, spacing: VT.Space.m) {
            Image(systemName: "waveform")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: VT.Space.xs) {
                Text("Speak anywhere, get clean text instantly")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Text(quickStartLine)
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(VT.Space.l)
        .background(
            LinearGradient(
                colors: [VT.tint, VT.tint.opacity(0.72)],
                startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: VT.Radius.card, style: .continuous))
    }

    private var quickStartLine: String {
        let verb = coordinator.settings.hotkey.holdToTalk ? "Hold" : "Tap"
        return "\(verb) \(coordinator.settings.hotkey.trigger.displayName) anywhere and start speaking — your words land in the focused app."
    }

    // MARK: Stats

    private var statsCard: some View {
        FrostedCard {
            VStack(alignment: .leading, spacing: VT.Space.l) {
                Text("Your stats")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                StatRow(value: coordinator.stats.totalWords.formatted(), label: "total words", symbol: "text.word.spacing")
                StatRow(value: coordinator.stats.averageWordsPerMinute.formatted(), label: "wpm", symbol: "gauge.with.dots.needle.67percent")
                StatRow(value: "0", label: "day streak", symbol: "flame")
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
