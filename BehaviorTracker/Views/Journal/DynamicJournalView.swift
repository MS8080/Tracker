import SwiftUI

// MARK: - Dynamic Journal View

struct DynamicJournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    @StateObject private var ttsService = TextToSpeechService.shared
    @State private var showingNewEntry = false
    @State private var selectedEntry: JournalEntry?
    @State private var selectedDemoEntry: DemoJournalEntryWrapper?
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

    private var demoEntriesGroupedByDay: [(date: Date, entries: [DemoJournalEntryWrapper])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.demoEntries) { entry in
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

                if viewModel.isDemoMode {
                    if viewModel.demoEntries.isEmpty {
                        emptyStateView
                    } else {
                        demoTimelineView
                    }
                } else if viewModel.journalEntries.isEmpty {
                    emptyStateView
                } else {
                    timelineView
                }

                // Floating Action Button (hidden in demo mode)
                if !viewModel.isDemoMode {
                    floatingActionButton
                }
            }
            .navigationTitle(NSLocalizedString("journal.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ProfileButton(showingProfile: $showingProfile)
                }

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
            .sheet(item: $selectedDemoEntry) { entry in
                DemoEntryDetailView(entry: entry)
            }
        }
    }

    // MARK: - Demo Timeline View

    private var demoTimelineView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Demo mode indicator
                HStack {
                    Image(systemName: "play.rectangle.fill")
                        .foregroundStyle(.orange)
                    Text("Demo Mode - Sample Data")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(.orange.opacity(0.2), in: Capsule())
                .padding(.horizontal, Spacing.lg)

                ForEach(demoEntriesGroupedByDay, id: \.date) { dayGroup in
                    DemoDaySection(
                        date: dayGroup.date,
                        entries: dayGroup.entries,
                        theme: theme,
                        onEntryTap: { selectedDemoEntry = $0 }
                    )
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
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
                            onAnalyze: { entryToAnalyze = $0 },
                            onAppear: { viewModel.loadMoreIfNeeded(currentEntry: $0) }
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
                            onAnalyze: { entryToAnalyze = $0 },
                            onAppear: { viewModel.loadMoreIfNeeded(currentEntry: $0) }
                        )
                        .id(dayGroup.date)
                    }

                    // Loading more indicator
                    if viewModel.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(.white)
                            Text("Loading more...")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                        }
                        .padding()
                    }

                    // End of entries indicator
                    if !viewModel.hasMoreEntries && viewModel.journalEntries.count > 0 {
                        HStack {
                            Spacer()
                            Text("You've reached the beginning")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                            Spacer()
                        }
                        .padding()
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.lg)
                .padding(.bottom, 80)
            }
            .refreshable {
                await viewModel.refresh()
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
    var onAppear: ((JournalEntry) -> Void)? = nil

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
                    .onAppear {
                        onAppear?(entry)
                    }
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

// MARK: - Demo Day Section

struct DemoDaySection: View {
    let date: Date
    let entries: [DemoJournalEntryWrapper]
    let theme: AppTheme
    let onEntryTap: (DemoJournalEntryWrapper) -> Void

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
            Text(dateHeader)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white.opacity(0.9))
                .capsuleLabel(theme: theme, style: .title)
                .padding(.leading, Spacing.xs)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    DemoTimelineEntry(
                        entry: entry,
                        isLast: index == entries.count - 1,
                        theme: theme,
                        onTap: { onEntryTap(entry) }
                    )
                }
            }
            .padding(Spacing.lg)
            .cardStyle(theme: theme)
        }
    }
}

// MARK: - Demo Timeline Entry

struct DemoTimelineEntry: View {
    let entry: DemoJournalEntryWrapper
    let isLast: Bool
    let theme: AppTheme
    let onTap: () -> Void

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: entry.timestamp)
    }

    var body: some View {
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
                HStack {
                    Text(timeString)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.timelineColor)
                        .capsuleLabel(theme: theme, style: .time)

                    if entry.isFavorite {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }

                    if entry.isAnalyzed {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                    }
                }

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
        }
    }
}

// MARK: - Demo Entry Detail View

struct DemoEntryDetailView: View {
    let entry: DemoJournalEntryWrapper
    @Environment(\.dismiss) private var dismiss
    @ThemeWrapper var theme

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Demo badge
                        HStack {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundStyle(.orange)
                            Text("Demo Entry")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(.orange.opacity(0.2), in: Capsule())

                        // Title if present
                        if let title = entry.title {
                            Text(title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }

                        // Timestamp
                        Text(entry.timestamp, style: .date) + Text(" at ") + Text(entry.timestamp, style: .time)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))

                        // Content
                        Text(entry.content)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.9))
                            .lineSpacing(6)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cardStyle(theme: theme)

                        // Mood indicator
                        if entry.mood > 0 {
                            HStack {
                                Text("Mood:")
                                    .foregroundStyle(.white.opacity(0.6))
                                ForEach(1...5, id: \.self) { index in
                                    Image(systemName: index <= entry.mood ? "circle.fill" : "circle")
                                        .font(.caption)
                                        .foregroundStyle(index <= entry.mood ? theme.primaryColor : .white.opacity(0.3))
                                }
                            }
                            .padding()
                            .cardStyle(theme: theme)
                        }

                        // Analysis summary if analyzed
                        if entry.isAnalyzed, let summary = entry.analysisSummary {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(.purple)
                                    Text("AI Analysis")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                }

                                Text(summary)
                                    .font(.body)
                                    .foregroundStyle(.white.opacity(0.8))

                                HStack {
                                    Text("Intensity:")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text("\(entry.overallIntensity)/10")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding()
                            .cardStyle(theme: theme)
                        }

                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("Entry Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DynamicJournalView()
}
