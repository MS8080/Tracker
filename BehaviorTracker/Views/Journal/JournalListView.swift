import SwiftUI

struct JournalListView: View {
    @StateObject private var viewModel = JournalViewModel()
    @StateObject private var ttsService = TextToSpeechService.shared
    @State private var showingNewEntry = false
    @State private var selectedEntry: JournalEntry?
    @State private var entryToDelete: JournalEntry?
    @State private var searchText = ""
    @Binding var showingProfile: Bool

    @AppStorage("selectedTheme") private var selectedThemeRaw: String = AppTheme.purple.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: selectedThemeRaw) ?? .purple
    }

    init(showingProfile: Binding<Bool> = .constant(false)) {
        self._showingProfile = showingProfile
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.gradient
                    .ignoresSafeArea()

                // Journal Entries List
                if viewModel.journalEntries.isEmpty {
                    emptyStateView
                } else {
                    journalEntriesListWithOffset
                }

                // Floating Action Button - bottom right
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
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                                Circle()
                                    .fill(theme.primaryColor.opacity(0.8))
                                    .frame(width: 56, height: 56)

                                Circle()
                                    .stroke(.white.opacity(0.3), lineWidth: 0.5)
                                    .frame(width: 56, height: 56)

                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                        }
                        .accessibilityLabel(NSLocalizedString("accessibility.create_entry", comment: ""))
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("journal.title", comment: ""))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ProfileButton(showingProfile: $showingProfile)
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                JournalEntryEditorView()
            }
            .onChange(of: showingNewEntry) { _, isShowing in
                if !isShowing {
                    // Refresh entries when sheet closes
                    viewModel.loadJournalEntries()
                }
            }
            .sheet(item: $selectedEntry) { entry in
                JournalEntryDetailView(entry: entry) {
                    // Mark this entry for deletion
                    entryToDelete = entry
                }
            }
            .onChange(of: selectedEntry) { _, newValue in
                if newValue == nil {
                    // If we have an entry marked for deletion, delete it now
                    if let entryToDelete = entryToDelete {
                        withAnimation {
                            viewModel.deleteEntry(entryToDelete)
                        }
                        self.entryToDelete = nil
                    } else {
                        // Otherwise just refresh the list
                        viewModel.loadJournalEntries()
                    }
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchQuery = newValue
        }
    }

    // Group entries by day
    private var entriesGroupedByDay: [(date: Date, entries: [JournalEntry])] {
        let calendar = Calendar.current

        // Filter out deleted entries first to prevent crashes
        let validEntries = viewModel.journalEntries.filter { !$0.isDeleted }

        let grouped = Dictionary(grouping: validEntries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }.map { (date: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }

    private var journalEntriesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(entriesGroupedByDay, id: \.date) { dayGroup in
                    DayTimelineCard(
                        date: dayGroup.date,
                        entries: dayGroup.entries,
                        theme: theme,
                        onEntryTap: { entry in
                            selectedEntry = entry
                        },
                        onToggleFavorite: { entry in
                            viewModel.toggleFavorite(entry)
                        },
                        onSpeak: { entry in
                            ttsService.speakJournalEntry(entry)
                        },
                        onDelete: { entry in
                            withAnimation {
                                viewModel.deleteEntry(entry)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }

    private var journalEntriesListWithOffset: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Search bar at the top - scrolls away naturally
                RoundedSearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                LazyVStack(spacing: 16) {
                    ForEach(entriesGroupedByDay, id: \.date) { dayGroup in
                        DayTimelineCard(
                            date: dayGroup.date,
                            entries: dayGroup.entries,
                            theme: theme,
                            onEntryTap: { entry in
                                selectedEntry = entry
                            },
                            onToggleFavorite: { entry in
                                viewModel.toggleFavorite(entry)
                            },
                            onSpeak: { entry in
                                ttsService.speakJournalEntry(entry)
                            },
                            onDelete: { entry in
                                withAnimation {
                                    viewModel.deleteEntry(entry)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(NSLocalizedString("journal.no_entries", comment: ""))
                .font(.title2)
                .fontWeight(.semibold)
                .accessibilityLabel(NSLocalizedString("journal.no_entries", comment: ""))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let title = entry.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .accessibilityLabel("Title: \(title)")
                } else {
                    Text("Untitled Entry")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Untitled entry")
                }

                Spacer()

                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .accessibilityLabel("Favorite")
                }
            }

            Text(entry.preview)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .accessibilityLabel("Preview: \(entry.preview)")

            HStack {
                Text(entry.formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .accessibilityLabel("Created on \(entry.formattedDate)")

                if entry.mood > 0 {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "face.smiling")
                            .font(.caption)
                        Text(moodText(for: entry.mood))
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .accessibilityLabel("Mood: \(moodText(for: entry.mood))")
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func moodText(for mood: Int16) -> String {
        switch mood {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Neutral"
        case 4: return "Good"
        case 5: return "Very Good"
        default: return "Unknown"
        }
    }
}

struct RoundedSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(NSLocalizedString("journal.search_placeholder", comment: "Search placeholder"), text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .accessibilityLabel(NSLocalizedString("journal.search_placeholder", comment: ""))

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(NSLocalizedString("accessibility.hide_search", comment: ""))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Day Timeline Card

struct DayTimelineCard: View {
    let date: Date
    let entries: [JournalEntry]
    let theme: AppTheme
    let onEntryTap: (JournalEntry) -> Void
    let onToggleFavorite: (JournalEntry) -> Void
    let onSpeak: (JournalEntry) -> Void
    let onDelete: (JournalEntry) -> Void

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
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: date)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date Header
            HStack {
                Text(dateHeader)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                if !isToday {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Timeline
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    JournalTimelineEntryRow(
                        entry: entry,
                        isLast: index == entries.count - 1,
                        theme: theme,
                        onTap: { onEntryTap(entry) },
                        onToggleFavorite: { onToggleFavorite(entry) },
                        onSpeak: { onSpeak(entry) },
                        onDelete: { onDelete(entry) }
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

struct JournalTimelineEntryRow: View {
    let entry: JournalEntry
    let isLast: Bool
    let theme: AppTheme
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    let onSpeak: () -> Void
    let onDelete: () -> Void

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: entry.timestamp)
    }

    var body: some View {
        // Safety check: don't render if entry is deleted
        if !entry.isDeleted {
            HStack(alignment: .top, spacing: 12) {
                // Timeline with bullet point
                VStack(spacing: 0) {
                    // Bullet point - aligned with time text center
                    Circle()
                    .fill(theme.primaryColor)
                    .frame(width: 10, height: 10)
                    .padding(.top, 4) // Align with center of time text

                // Vertical line (if not last)
                if !isLast {
                    Rectangle()
                        .fill(theme.primaryColor.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 10)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Time
                Text(timeString)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.primaryColor)

                // Entry content
                VStack(alignment: .leading, spacing: 4) {
                    if let title = entry.title, !title.isEmpty {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Text(entry.preview)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if entry.mood > 0 {
                        HStack(spacing: 4) {
                            Text(moodEmoji(for: entry.mood))
                            Text(moodText(for: entry.mood))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.bottom, isLast ? 0 : 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            .contextMenu {
                Button {
                    onToggleFavorite()
                } label: {
                    Label(
                        entry.isFavorite ? "Unfavorite" : "Favorite",
                        systemImage: entry.isFavorite ? "star.slash" : "star.fill"
                    )
                }

                Button {
                    onSpeak()
                } label: {
                    Label("Read Aloud", systemImage: "speaker.wave.2.fill")
                }

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            // Favorite indicator
            if entry.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }
        }
        }
    }

    private func moodEmoji(for mood: Int16) -> String {
        switch mood {
        case 1: return "😔"
        case 2: return "😐"
        case 3: return "🙂"
        case 4: return "😊"
        case 5: return "😄"
        default: return ""
        }
    }

    private func moodText(for mood: Int16) -> String {
        switch mood {
        case 1: return "Very Low"
        case 2: return "Low"
        case 3: return "Neutral"
        case 4: return "Good"
        case 5: return "Very Good"
        default: return ""
        }
    }
}

// MARK: - Scroll Offset Tracking

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    JournalListView()
}
