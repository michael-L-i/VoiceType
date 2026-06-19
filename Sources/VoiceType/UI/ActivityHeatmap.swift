import SwiftUI
import VoiceTypeKit

/// A GitHub-style contribution grid of daily dictation activity — the Stats
/// page's signature element. Columns are weeks (oldest left), rows are weekdays
/// (Sun→Sat); each cell's coral intensity scales with the day's activity.
///
/// Feed it a dense, oldest→newest run of days (e.g. `DailyStatsLog.window`); it
/// pads the ends to whole weeks itself.
struct ActivityHeatmap: View {
    let days: [DailyStats]
    /// Which number a cell represents (default: words).
    var metric: (DailyStats) -> Int = { $0.words }
    var tint: Color = VT.tint
    var calendar: Calendar = .current

    private let cell: CGFloat = 11
    private let gap: CGFloat = 3
    private let corner: CGFloat = 2.5

    var body: some View {
        let columns = weekColumns()
        let peak = max(1, days.map(metric).max() ?? 1)

        VStack(alignment: .leading, spacing: gap) {
            monthLabels(columns)
            HStack(alignment: .top, spacing: gap) {
                weekdayLabels
                HStack(alignment: .top, spacing: gap) {
                    ForEach(Array(columns.enumerated()), id: \.offset) { _, week in
                        VStack(spacing: gap) {
                            ForEach(0..<7, id: \.self) { row in
                                cellView(week[row], peak: peak)
                            }
                        }
                    }
                }
            }
            legend
        }
    }

    // MARK: Cells

    @ViewBuilder
    private func cellView(_ day: DailyStats?, peak: Int) -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(color(for: day, peak: peak))
            .frame(width: cell, height: cell)
            .help(tooltip(for: day))
    }

    /// Empty/zero days read as a faint neutral; active days step through four
    /// coral intensities by quantile of the busiest day in view.
    private func color(for day: DailyStats?, peak: Int) -> Color {
        guard let day else { return .clear }
        let value = metric(day)
        guard value > 0 else { return Color.primary.opacity(0.06) }
        let level = min(4, Int(ceil(Double(value) / Double(peak) * 4)))
        switch level {
        case 1: return tint.opacity(0.28)
        case 2: return tint.opacity(0.50)
        case 3: return tint.opacity(0.74)
        default: return tint
        }
    }

    private func tooltip(for day: DailyStats?) -> String {
        guard let day else { return "" }
        let value = metric(day)
        let date = Self.tooltipDate.string(from: day.day)
        return value > 0 ? "\(date) — \(value.formatted()) words" : "\(date) — no dictation"
    }

    // MARK: Labels

    private var weekdayLabels: some View {
        VStack(alignment: .trailing, spacing: gap) {
            ForEach(0..<7, id: \.self) { row in
                Text(row % 2 == 1 ? Self.weekdayShort(row) : " ")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                    .frame(height: cell)
            }
        }
    }

    private func monthLabels(_ columns: [[DailyStats?]]) -> some View {
        HStack(spacing: gap) {
            // Align month labels with the weekday-label gutter.
            Text(" ").font(.system(size: 8)).frame(width: 18)
            ForEach(Array(columns.enumerated()), id: \.offset) { index, week in
                Text(monthLabel(for: week, at: index, in: columns))
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                    .frame(width: cell, alignment: .leading)
            }
        }
    }

    /// Show a month abbreviation on the first column whose first real day lands in
    /// a new month.
    private func monthLabel(for week: [DailyStats?], at index: Int, in columns: [[DailyStats?]]) -> String {
        guard let first = week.compactMap({ $0 }).first else { return " " }
        let month = calendar.component(.month, from: first.day)
        let prevMonth = index > 0
            ? columns[index - 1].compactMap({ $0 }).first.map { calendar.component(.month, from: $0.day) }
            : nil
        guard month != prevMonth else { return " " }
        return Self.monthShort(month)
    }

    private var legend: some View {
        HStack(spacing: gap) {
            Text("Less").font(.system(size: 8)).foregroundStyle(.secondary)
            ForEach([Color.primary.opacity(0.06), tint.opacity(0.28), tint.opacity(0.50), tint.opacity(0.74), tint], id: \.self) { c in
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(c).frame(width: cell, height: cell)
            }
            Text("More").font(.system(size: 8)).foregroundStyle(.secondary)
        }
        .padding(.leading, 18 + gap)
    }

    // MARK: Layout

    /// Pad the dense day run to whole weeks and slice into week columns (each a
    /// 7-row Sun→Sat array, nil where padded).
    private func weekColumns() -> [[DailyStats?]] {
        guard let first = days.first else { return [] }
        let leadingPad = calendar.component(.weekday, from: first.day) - 1   // Sun == 0
        var cells: [DailyStats?] = Array(repeating: nil, count: leadingPad) + days.map { Optional($0) }
        let trailingPad = (7 - cells.count % 7) % 7
        cells += Array(repeating: nil, count: trailingPad)
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
    }

    // MARK: Formatting

    private static let tooltipDate: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d, yyyy"; return f
    }()
    private static func weekdayShort(_ row: Int) -> String {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][row]
    }
    private static func monthShort(_ month: Int) -> String {
        let symbols = DateFormatter().shortMonthSymbols ?? []
        return symbols.indices.contains(month - 1) ? symbols[month - 1] : " "
    }
}

#if DEBUG
#Preview("Activity heatmap") {
    // Synthetic 26 weeks of activity with a weekly rhythm.
    let cal = Calendar.current
    let today = cal.startOfDay(for: Date())
    let days: [DailyStats] = (0..<182).reversed().map { offset in
        let date = cal.date(byAdding: .day, value: -offset, to: today)!
        let weekday = cal.component(.weekday, from: date)
        let base = (weekday == 1 || weekday == 7) ? 0 : (offset % 5) * 60
        return DailyStats(day: date, words: base, sessions: base / 30, speakingTime: Double(base) / 2)
    }
    return ActivityHeatmap(days: days)
        .padding(40)
}
#endif
