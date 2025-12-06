import SwiftUI

// MARK: - Dynamic Journal View

struct DynamicJournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    @StateObject private var ttsService = TextToSpeechService.shared
    @State private var showingNewEntry = false
    @State private var selectedEntry: JournalEntry?
    @State private var entryToAnalyze: JournalEntry?
    @State private var dayToAnalyze: DayAnalysisData?
    @Binding var showingProfile: Bool
    @ThemeWrapper var theme

    init(showingProfile: Binding<Bool> = .constant(false)) {
        self._showingProfile = showingProfile
    }

    private var entriesGroupedByDay: [(date: Date, entries: [JournalEntry])] {
        let calendar = Calendar.current
        let validEntries = viewModel.journalEntries.filter { !$0.isDeleted }
        let grouped = Dictionary(grouping: validEntries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }

    private var todayGroup: (date: Date, entries: [JournalEntry])? {
        entriesGroupedByDay.first { Calendar.current.isDateInToday($0.date) }
    }

    private var previousDays: [(date: Date, entries: [JournalEntry])] {
        entriesGroupedByDay.filter { !Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                if viewModel.journalEntries.isEmpty {
                    emptyStateView
                } else {
                    timelineView
                }

                // Floating Action Button
                floatingActionButton
            }
            .navigationTitle(NSLocalizedString("journal.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ProfileButton(showingProfile: $showingProfile)
                }
                .hideSharedBackground()
            }
            .sheet(isPresented: $showingNewEntry) {
                JournalEntryEditorView()
            }
            .onChange(of: showingNewEntry) { _, newValue in
                if !newValue {
                    viewModel.loadJournalEntries()
                }
            }
            .sheet(item: $selectedEntry) { entry in
                JournalEntryDetailView(entry: entry) {
                    withAnimation {
                        viewModel.deleteEntry(entry)
                    }
                }
            }
            .onChange(of: selectedEntry) { _, newValue in
                if newValue == nil {
                    viewModel.loadJournalEntries()
                }
            }
            .sheet(item: $entryToAnalyze) { entry in
                JournalEntryAnalysisView(entry: entry)
            }
            .sheet(item: $dayToAnalyze) { dayData in
                DayAnalysisView(entries: dayData.entries, date: dayData.date)
            }
        }
    }

    // MARK: - Timeline View

    private var timelineView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Today's entries
                    if let today = todayGroup {
                        SimpleDaySection(
                            date: today.date,
                            entries: today.entries,
                            theme: theme,
                            onEntryTap: { selectedEntry = $0 },
                            onToggleFavorite: { viewModel.toggleFavorite($0) },
                            onSpeak: { ttsService.speakJournalEntry($0) },
                            onDelete: { entry in withAnimation { viewModel.deleteEntry(entry) } },
                            onAnalyze: { entryToAnalyze = $0 }
                        )
                        .id(today.date)
                    }

                    // Previous days
                    ForEach(previousDays, id: \.date) { dayGroup in
                        SimpleDaySection(
                            date: dayGroup.date,
                            entries: dayGroup.entries,
                            theme: theme,
                            onEntryTap: { selectedEntry = $0 },
                            onToggleFavorite: { viewModel.toggleFavorite($0) },
                            onSpeak: { ttsService.speakJournalEntry($0) },
                            onDelete: { entry in withAnimation { viewModel.deleteEntry(entry) } },
                            onAnalyze: { entryToAnalyze = $0 }
                        )
                        .id(dayGroup.date)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.lg)
                .padding(.bottom, 80)
            }

        }
    }

    // MARK: - Floating Action Button

    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    showingNewEntry = true
                    HapticFeedback.medium.trigger()
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(theme.primaryColor.opacity(0.5), in: Circle())
                        .background(.ultraThinMaterial, in: Circle())
                        .shadow(color: theme.primaryColor.opacity(0.2), radius: 6, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "book.closed.fill",
            title: "Start Your Journal",
            message: "Capture your thoughts, feelings, and reflections. Tap the + button to create your first entry.",
            actionTitle: "Create First Entry",
            action: {
                showingNewEntry = true
                HapticFeedback.medium.trigger()
            }
        )
        .padding()
    }
}

// MARK: - Simple Day Section

struct SimpleDaySection: View {
    let date: Date
    let entries: [JournalEntry]
    let theme: AppTheme
    let onEntryTap: (JournalEntry) -> Void
    let onToggleFavorite: (JournalEntry) -> Void
    let onSpeak: (JournalEntry) -> Void
    let onDelete: (JournalEntry) -> Void
    let onAnalyze: (JournalEntry) -> Void

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var dateHeader: String {
        if isToday {
            return NSLocalizedString("time.today", comment: "")
        } else if Calendar.current.isDateInYesterday(date) {
            return NSLocalizedString("time.yesterday", comment: "")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, d MMMM yyyy"
            return formatter.string(from: date)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Date header
            Text(dateHeader)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.9))
                .capsuleLabel(theme: theme, style: .title)
                .padding(.leading, Spacing.xs)

            // Entries with timeline inside a card
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    SimpleTimelineEntry(
                        entry: entry,
                        isLast: index == entries.count - 1,
                        theme: theme,
                        onTap: { onEntryTap(entry) },
                        onToggleFavorite: { onToggleFavorite(entry) },
                        onSpeak: { onSpeak(entry) },
                        onDelete: { onDelete(entry) },
                        onAnalyze: { onAnalyze(entry) }
                    )
                }
            }
            .padding(Spacing.lg)
            .cardStyle(theme: theme)
        }
    }
}

// MARK: - Simple Timeline Entry

struct SimpleTimelineEntry: View {
    let entry: JournalEntry
    let isLast: Bool
    let theme: AppTheme
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onSpeak: () -> Void
    let onDelete: () -> Void
    let onAnalyze: () -> Void

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: entry.timestamp)
    }

    var body: some View {
        if !entry.isDeleted {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Timeline dot and line
                VStack(spacing: 0) {
                    Circle()
                        .fill(theme.timelineColor)
                        .frame(width: 10, height: 10)
                        .shadow(color: theme.timelineColor.opacity(0.5), radius: 3)
                        .padding(.top, 4)

                    if !isLast {
                        Rectangle()
                            .fill(theme.timelineColor.opacity(0.3))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 10)

                // Entry content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Time
                    Text(timeString)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.timelineColor)
                        .capsuleLabel(theme: theme, style: .time)

                    // Content - show full text
                    Text(entry.content)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, isLast ? 0 : Spacing.lg)
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticFeedback.light.trigger()
                    onTap()
                }
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = entry.content
                        HapticFeedback.medium.trigger()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                    Button {
                        onToggleFavorite()
                    } label: {
                        Label(entry.isFavorite ? "Remove Bookmark" : "Bookmark", systemImage: entry.isFavorite ? "bookmark.slash" : "bookmark")
                    }

                    Button {
                        onSpeak()
                    } label: {
                        Label("Read Aloud", systemImage: "speaker.wave.2")
                    }

                    Button {
                        onAnalyze()
                    } label: {
                        Label("Analyze", systemImage: "sparkles")
                    }

                    Divider()

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DynamicJournalView()
}
