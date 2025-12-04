import SwiftUI

// MARK: - Dynamic Journal View with Advanced Animations

struct DynamicJournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    @StateObject private var ttsService = TextToSpeechService.shared
    @State private var showingNewEntry = false
    @State private var selectedEntry: JournalEntry?
    @State private var entryToAnalyze: JournalEntry?
    @State private var dayToAnalyze: DayAnalysisData?
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
    
    // MARK: - Animation Constants
    
    private static let standardSpring = Animation.spring(response: 0.3, dampingFraction: 0.75)

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
    
    // MARK: - Reusable Card Configuration
    
    private func dayCardView(
        date: Date,
        entries: [JournalEntry],
        isExpanded: Bool,
        onTapCard: @escaping () -> Void
    ) -> some View {
        DynamicDayCard(
            date: date,
            entries: entries,
            theme: theme,
            isExpanded: isExpanded,
            namespace: animation,
            onEntryTap: { selectedEntry = $0 },
            onToggleFavorite: { viewModel.toggleFavorite($0) },
            onSpeak: { ttsService.speakJournalEntry($0) },
            onDelete: { entry in withAnimation { viewModel.deleteEntry(entry) } },
            onAnalyze: { entryToAnalyze = $0 },
            onAnalyzeDay: { dayToAnalyze = DayAnalysisData(entries: $0, date: $1) },
            onTapCard: onTapCard
        )
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
        .onAppear {
            // Hero animation on appear - focus on today
            withAnimation(Self.standardSpring) {
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
                        dayCardView(
                            date: todayGroup.date,
                            entries: todayGroup.entries,
                            isExpanded: true,
                            onTapCard: {
                                withAnimation(Self.standardSpring) {
                                    expandedDayDate = todayGroup.date
                                    viewMode = .expanded
                                }
                            }
                        )
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.xl)

                        // Subtle hint about other days
                        if entriesGroupedByDay.count > 1 {
                            Button {
                                withAnimation(Self.standardSpring) {
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
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.md)
                                .background(theme.primaryColor.opacity(0.2), in: Capsule())
                                .background(.ultraThinMaterial, in: Capsule())
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
    }

    // MARK: - Timeline View (All Days)

    private var timelineView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(entriesGroupedByDay, id: \.date) { dayGroup in
                        dayCardView(
                            date: dayGroup.date,
                            entries: dayGroup.entries,
                            isExpanded: false,
                            onTapCard: {
                                withAnimation(Self.standardSpring) {
                                    expandedDayDate = dayGroup.date
                                    viewMode = .expanded
                                }
                            }
                        )
                        .id(dayGroup.date)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !entriesGroupedByDay.isEmpty && todayGroup != nil {
                    Button {
                        withAnimation(Self.standardSpring) {
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
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical)
                    .padding(.top, 60)
                }

                // Close button
                Button {
                    withAnimation(Self.standardSpring) {
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

// MARK: - Preview

#Preview {
    DynamicJournalView()
}
