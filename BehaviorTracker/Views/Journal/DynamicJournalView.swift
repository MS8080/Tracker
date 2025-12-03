import SwiftUI

// MARK: - Dynamic Journal View with Advanced Animations

struct DynamicJournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    @StateObject private var ttsService = TextToSpeechService.shared
    @State private var showingNewEntry = false
    @State private var selectedEntry: JournalEntry?
    @State private var entryToDelete: JournalEntry?
    @State private var searchText = ""
    @State private var entryToAnalyze: JournalEntry?
    @State private var dayToAnalyze: DayAnalysisData?
    @State private var isSearching = false
    @State private var expandedDayDate: Date?
    @State private var viewMode: ViewMode = .focused

    @Binding var showingProfile: Bool
    @ThemeWrapper var theme
    @Namespace private var animation

    enum ViewMode {
        case focused    // Today is hero/expanded
        case timeline   // All days visible in timeline
        case expanded   // A day is fullscreen
    }

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

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                if viewModel.journalEntries.isEmpty {
                    emptyStateView
                } else {
                    mainContentView
                }

                // Floating Action Button
                floatingActionButton
            }
            .navigationTitle(viewMode == .expanded ? "" : NSLocalizedString("journal.title", comment: ""))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if viewMode != .expanded {
                    ToolbarItem(placement: .primaryAction) {
                        ProfileButton(showingProfile: $showingProfile)
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                JournalEntryEditorView()
            }
            .onChange(of: showingNewEntry) { _, isShowing in
                if !isShowing {
                    viewModel.loadJournalEntries()
                }
            }
            .sheet(item: $selectedEntry) { entry in
                JournalEntryDetailView(entry: entry) {
                    entryToDelete = entry
                }
            }
            .onChange(of: selectedEntry) { _, newValue in
                if newValue == nil {
                    if let entryToDelete = entryToDelete {
                        withAnimation {
                            viewModel.deleteEntry(entryToDelete)
                        }
                        self.entryToDelete = nil
                    } else {
                        viewModel.loadJournalEntries()
                    }
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchQuery = newValue
        }
        .onAppear {
            // Hero animation on appear - focus on today
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                viewMode = .focused
            }
        }
    }

    // MARK: - Main Content View

    @ViewBuilder
    private var mainContentView: some View {
        switch viewMode {
        case .focused:
            focusedTodayView
        case .timeline:
            timelineView
        case .expanded:
            expandedDayView
        }
    }

    // MARK: - Focused Today View (Hero Animation)

    private var focusedTodayView: some View {
        VStack(spacing: 0) {
            if let todayGroup = todayGroup {
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        // Hero today card - fills most of screen
                        DynamicDayCard(
                            date: todayGroup.date,
                            entries: todayGroup.entries,
                            theme: theme,
                            isExpanded: true,
                            isFocused: true,
                            namespace: animation,
                            onEntryTap: { entry in selectedEntry = entry },
                            onToggleFavorite: { entry in viewModel.toggleFavorite(entry) },
                            onSpeak: { entry in ttsService.speakJournalEntry(entry) },
                            onDelete: { entry in
                                withAnimation { viewModel.deleteEntry(entry) }
                            },
                            onAnalyze: { entry in entryToAnalyze = entry },
                            onAnalyzeDay: { entries, date in
                                dayToAnalyze = DayAnalysisData(entries: entries, date: date)
                            },
                            onTapCard: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    expandedDayDate = todayGroup.date
                                    viewMode = .expanded
                                }
                            }
                        )
                        .padding(.horizontal)
                        .padding(.top, Spacing.xl)

                        // Subtle hint about other days
                        if entriesGroupedByDay.count > 1 {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    viewMode = .timeline
                                }
                            } label: {
                                HStack(spacing: Spacing.sm) {
                                    Text("View All Days")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.md)
                                .background(
                                    Capsule()
                                        .fill(.white.opacity(0.1))
                                        .overlay(
                                            Capsule()
                                                .stroke(.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                            .padding(.bottom, Spacing.xxl)
                        }
                    }
                }
            } else {
                // No entries today - show timeline
                timelineView
            }
        }
        .sheet(item: $entryToAnalyze) { entry in
            JournalEntryAnalysisView(entry: entry)
        }
        .sheet(item: $dayToAnalyze) { (dayData: DayAnalysisData) in
            DayAnalysisView(entries: dayData.entries, date: dayData.date)
        }
    }

    // MARK: - Timeline View (All Days)

    private var timelineView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(entriesGroupedByDay, id: \.date) { dayGroup in
                        let isToday = Calendar.current.isDateInToday(dayGroup.date)

                        DynamicDayCard(
                            date: dayGroup.date,
                            entries: dayGroup.entries,
                            theme: theme,
                            isExpanded: false,
                            isFocused: isToday,
                            namespace: animation,
                            onEntryTap: { entry in selectedEntry = entry },
                            onToggleFavorite: { entry in viewModel.toggleFavorite(entry) },
                            onSpeak: { entry in ttsService.speakJournalEntry(entry) },
                            onDelete: { entry in
                                withAnimation { viewModel.deleteEntry(entry) }
                            },
                            onAnalyze: { entry in entryToAnalyze = entry },
                            onAnalyzeDay: { entries, date in
                                dayToAnalyze = DayAnalysisData(entries: entries, date: date)
                            },
                            onTapCard: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    expandedDayDate = dayGroup.date
                                    viewMode = .expanded
                                }
                            }
                        )
                        .id(dayGroup.date)
                    }
                }
                .padding()
            }
        }
        .sheet(item: $entryToAnalyze) { entry in
            JournalEntryAnalysisView(entry: entry)
        }
        .sheet(item: $dayToAnalyze) { (dayData: DayAnalysisData) in
            DayAnalysisView(entries: dayData.entries, date: dayData.date)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !entriesGroupedByDay.isEmpty && todayGroup != nil {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            viewMode = .focused
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.caption)
                            Text("Today")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }
        }
    }

    // MARK: - Expanded Day View (Fullscreen)

    @ViewBuilder
    private var expandedDayView: some View {
        if let expandedDate = expandedDayDate,
           let dayGroup = entriesGroupedByDay.first(where: { Calendar.current.isDate($0.date, inSameDayAs: expandedDate) }) {
            ZStack(alignment: .topLeading) {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        // Expanded day content
                        ExpandedDayContentView(
                            date: dayGroup.date,
                            entries: dayGroup.entries,
                            theme: theme,
                            onEntryTap: { entry in selectedEntry = entry },
                            onToggleFavorite: { entry in viewModel.toggleFavorite(entry) },
                            onSpeak: { entry in ttsService.speakJournalEntry(entry) },
                            onDelete: { entry in
                                withAnimation { viewModel.deleteEntry(entry) }
                            },
                            onAnalyze: { entry in entryToAnalyze = entry },
                            onAnalyzeDay: { entries, date in
                                dayToAnalyze = DayAnalysisData(entries: entries, date: date)
                            }
                        )
                    }
                    .padding()
                    .padding(.top, 60)
                }

                // Close button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        expandedDayDate = nil
                        viewMode = todayGroup != nil ? .focused : .timeline
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding()
                }
                .padding(.top, 8)
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
                    ZStack {
                        Circle()
                            .fill(theme.primaryColor)
                            .frame(width: 56, height: 56)

                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 0.5)
                            .frame(width: 56, height: 56)

                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: theme.primaryColor.opacity(0.3), radius: 10, y: 5)
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

// MARK: - Preview

#Preview {
    DynamicJournalView()
}
