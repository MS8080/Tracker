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
                    .foregroundStyle(.white)
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

#Preview {
    CalendarDayDetailView(
        date: Date(),
        entries: [],
        medicationLogs: [],
        journalEntries: []
    )
}
