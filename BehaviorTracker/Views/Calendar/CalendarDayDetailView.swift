import SwiftUI

struct CalendarDayDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let date: Date
    let entries: [PatternEntry]
    let medicationLogs: [MedicationLog]
    let journalEntries: [JournalEntry]
    var calendarEvents: [CalendarEvent] = []

    @ThemeWrapper var theme

    private var sortedEntries: [PatternEntry] {
        entries.sorted { $0.timestamp < $1.timestamp }
    }

    private var sortedMedicationLogs: [MedicationLog] {
        medicationLogs.sorted { $0.timestamp < $1.timestamp }
    }

    private var sortedJournalEntries: [JournalEntry] {
        journalEntries.sorted { $0.timestamp < $1.timestamp }
    }

    private var sortedCalendarEvents: [CalendarEvent] {
        calendarEvents.sorted { $0.startDate < $1.startDate }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        daySummaryCard

                        if !sortedCalendarEvents.isEmpty {
                            calendarEventsSection
                        }

                        if !sortedEntries.isEmpty {
                            patternEntriesSection
                        }

                        if !sortedMedicationLogs.isEmpty {
                            medicationLogsSection
                        }

                        if !sortedJournalEntries.isEmpty {
                            journalEntriesSection
                        }

                        if sortedEntries.isEmpty && sortedMedicationLogs.isEmpty && sortedJournalEntries.isEmpty && sortedCalendarEvents.isEmpty {
                            emptyStateView
                        }
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    // MARK: - Day Summary Card

    private var daySummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day Summary")
                        .font(.headline)
                    Text(weekdayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 16) {
                if !calendarEvents.isEmpty {
                    SummaryStatView(
                        icon: "calendar",
                        color: .cyan,
                        value: "\(calendarEvents.count)",
                        label: "Events"
                    )
                }

                SummaryStatView(
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue,
                    value: "\(entries.count)",
                    label: "Patterns"
                )

                SummaryStatView(
                    icon: "pills.fill",
                    color: .green,
                    value: "\(medicationLogs.count)",
                    label: "Meds"
                )

                SummaryStatView(
                    icon: "book.fill",
                    color: .orange,
                    value: "\(journalEntries.count)",
                    label: "Journal"
                )
            }

            if let avgIntensity = averageIntensity {
                HStack {
                    Text("Average Intensity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    IntensityIndicator(intensity: avgIntensity)
                }
            }

            if !categoryBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Categories")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 8) {
                        ForEach(categoryBreakdown, id: \.category) { item in
                            CategoryPill(category: item.category, count: item.count)
                        }
                    }
                }
            }
        }
        .padding(20)
        .cardStyle(theme: theme)
    }

    private var weekdayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private var averageIntensity: Double? {
        let intensityEntries = entries.filter { $0.intensity > 0 }
        guard !intensityEntries.isEmpty else { return nil }
        let total = intensityEntries.reduce(0) { $0 + Int($1.intensity) }
        return Double(total) / Double(intensityEntries.count)
    }

    private var categoryBreakdown: [(category: PatternCategory, count: Int)] {
        let grouped = Dictionary(grouping: entries) { $0.patternCategoryEnum }
        return grouped.compactMap { category, entries in
            guard let cat = category else { return nil }
            return (category: cat, count: entries.count)
        }.sorted { $0.count > $1.count }
    }

    // MARK: - Calendar Events Section

    private var calendarEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.cyan)
                Text("Calendar Events")
                    .font(.headline)
            }

            VStack(spacing: 12) {
                ForEach(sortedCalendarEvents) { event in
                    CalendarEventRow(event: event)
                }
            }
        }
        .padding(20)
        .cardStyle(theme: theme)
    }

    // MARK: - Pattern Entries Section

    private var patternEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pattern Entries")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(sortedEntries) { entry in
                    PatternEntryRow(entry: entry)
                }
            }
        }
        .padding(20)
        .cardStyle(theme: theme)
    }

    // MARK: - Medication Logs Section

    private var medicationLogsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Medication Logs")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(sortedMedicationLogs) { log in
                    CalendarMedicationLogRow(log: log)
                }
            }
        }
        .padding(20)
        .cardStyle(theme: theme)
    }

    // MARK: - Journal Entries Section

    private var journalEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Journal Entries")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(sortedJournalEntries) { entry in
                    CalendarJournalEntryRow(entry: entry)
                }
            }
        }
        .padding(20)
        .cardStyle(theme: theme)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No entries for this day")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Start logging to see your data here")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .cardStyle(theme: theme)
    }
}

// MARK: - Supporting Views

struct SummaryStatView: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct IntensityIndicator: View {
    let intensity: Double

    private var intensityColor: Color {
        switch intensity {
        case 0..<2: return .green
        case 2..<3: return .yellow
        case 3..<4: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(String(format: "%.1f", intensity))
                .font(.headline)
                .foregroundStyle(intensityColor)

            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { level in
                    Circle()
                        .fill(Double(level) <= intensity ? intensityColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

struct PatternEntryRow: View {
    let entry: PatternEntry

    @ThemeWrapper var theme

    var body: some View {
        HStack(spacing: 12) {
            if let category = entry.patternCategoryEnum {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(category.color)
                    .frame(width: 36)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.patternType)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(entry.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if entry.duration > 0 {
                        Text("\(entry.duration)min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let notes = entry.contextNotes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if entry.intensity > 0 {
                Text("\(entry.intensity)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(intensityColor(for: entry.intensity))
                    )
            }
        }
        .padding(12)
        .cardStyle(theme: theme, cornerRadius: 12)
    }

    private func intensityColor(for intensity: Int16) -> Color {
        switch intensity {
        case 1: return .green
        case 2: return .mint
        case 3: return .yellow
        case 4: return .orange
        case 5: return .red
        default: return .blue
        }
    }
}

struct CalendarMedicationLogRow: View {
    let log: MedicationLog

    @ThemeWrapper var theme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.taken ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(log.taken ? .green : .red)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(log.medication?.name ?? "Unknown Medication")
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(log.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let dosage = log.medication?.dosage {
                        Text(dosage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !log.taken, let reason = log.skippedReason, !reason.isEmpty {
                    Text("Skipped: \(reason)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if let notes = log.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if log.effectiveness > 0 {
                VStack(spacing: 2) {
                    Text("\(log.effectiveness)")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("eff")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .cardStyle(theme: theme, cornerRadius: 12)
    }
}

struct CalendarJournalEntryRow: View {
    let entry: JournalEntry

    @ThemeWrapper var theme

    var body: some View {
        HStack(spacing: 12) {
            if entry.mood > 0 {
                Text(moodEmoji(for: entry.mood))
                    .font(.title2)
                    .frame(width: 36)
            } else {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .frame(width: 36)
            }

            VStack(alignment: .leading, spacing: 4) {
                if let title = entry.title, !title.isEmpty {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                }

                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !entry.content.isEmpty {
                    Text(entry.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(12)
        .cardStyle(theme: theme, cornerRadius: 12)
    }

    private func moodEmoji(for mood: Int16) -> String {
        switch mood {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "📝"
        }
    }
}

// MARK: - Calendar Event Row

struct CalendarEventRow: View {
    let event: CalendarEvent

    @ThemeWrapper var theme

    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(spacing: 2) {
                if event.isAllDay {
                    Image(systemName: "sun.max.fill")
                        .font(.title2)
                        .foregroundStyle(.cyan)
                } else {
                    Text(event.timeString)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.cyan)
                }
            }
            .frame(width: 50)

            // Color bar from calendar
            RoundedRectangle(cornerRadius: 2)
                .fill(calendarColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if !event.isAllDay {
                        Text(event.durationString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let calendarTitle = event.calendarTitle {
                        Text(calendarTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let location = event.location, !location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                if let notes = event.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(12)
        .cardStyle(theme: theme, cornerRadius: 12)
    }

    private var calendarColor: Color {
        if let cgColor = event.calendarColor {
            return Color(cgColor: cgColor)
        }
        return .cyan
    }
}

// MARK: - Flow Layout (for category pills)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)

        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(x: bounds.minX + result.positions[index].x,
                              y: bounds.minY + result.positions[index].y)
            subview.place(at: point, proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            height = y + rowHeight
        }
    }
}

#Preview {
    CalendarDayDetailView(
        date: Date(),
        entries: [],
        medicationLogs: [],
        journalEntries: []
    )
}
